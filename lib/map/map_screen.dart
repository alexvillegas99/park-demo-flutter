import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../account/account_session.dart';
import '../design/brand_theme.dart';
import 'map_admin_controller.dart';
import 'map_connectivity_monitor.dart';
import 'map_document_controller.dart';
import 'map_geo.dart';
import 'map_location_controller.dart';
import 'map_marker_icon_factory.dart';
import 'map_runtime_config.dart';
import 'map_route_graph.dart';
import 'map_screen_controller.dart';
import 'map_view_model.dart';
import 'widgets/map_admin_sheet.dart';
import 'widgets/map_admin_place_dialog.dart';
import 'widgets/map_navigation_card.dart';
import 'widgets/map_place_sheet.dart';
import 'widgets/map_search_filters.dart';

class FairLocation {
  const FairLocation._();

  static const double latitude = -1.3690877425784418;
  static const double longitude = -78.647792380582;
  static const double radiusMeters = 900;
  static const double initialZoom = 17.6;
}

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.active = true,
    required this.programming,
    required this.mapDocument,
    required this.session,
    this.locationController,
    this.mapBuilder,
    this.mapsConfigured = MapRuntimeConfig.mapsConfigured,
    this.connectivityCheck,
    this.routeGraph,
    this.initialPlaceId,
  });

  final bool active;
  final MapProgrammingSource programming;
  final MapDocumentController mapDocument;
  final AccessSession session;
  final MapLocationController? locationController;
  final MapCanvasBuilder? mapBuilder;
  final bool mapsConfigured;
  final Future<bool> Function()? connectivityCheck;
  final MapRouteGraph? routeGraph;
  final String? initialPlaceId;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  late final MapScreenController _controller;
  late final MapLocationController _locationController;
  late final bool _ownsLocationController;
  StreamSubscription<MapLocationSample>? _locationSubscription;
  StreamSubscription<MapLocationFailure>? _errorSubscription;
  GoogleMapController? _googleMapController;
  String? _locationMessage;
  int _lastCameraRevision = 0;
  bool _arrivalAnnounced = false;
  MapAdminController? _adminController;
  bool _adminMoveMode = false;
  bool _adminAddMode = false;
  final MapMarkerIconFactory _markerIconFactory = MapMarkerIconFactory();
  Map<String, BitmapDescriptor> _markerIcons =
      const <String, BitmapDescriptor>{};
  String? _markerIconSignature;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MapScreenController(
      document: widget.mapDocument,
      routeGraph: widget.routeGraph,
    )..addListener(_refresh);
    if (widget.initialPlaceId != null) {
      _controller.selectPlace(widget.initialPlaceId);
    }
    if (widget.session.isAdmin) {
      _adminController = MapAdminController(
        session: widget.session,
        document: widget.mapDocument,
      );
    }
    _ownsLocationController = widget.locationController == null;
    _locationController =
        widget.locationController ??
        MapLocationController(
          source: const GeolocatorMapPositionSource(),
          boundary: const MapLocationBoundary(
            latitude: FairLocation.latitude,
            longitude: FairLocation.longitude,
            radiusMeters: FairLocation.radiusMeters,
          ),
        );
    _locationSubscription = _locationController.updates.listen(_onLocation);
    _errorSubscription = _locationController.errors.listen(_onLocationError);
    widget.programming.addListener(_refresh);
    _checkConnectivity();
    if (widget.routeGraph == null) _loadRouteGraph();
    _syncTracking();
    _queueMarkerIconRefresh();
  }

  Future<void> _loadRouteGraph() async {
    try {
      final raw = await rootBundle.loadString('assets/map/route_graph_v2.json');
      _controller.setRouteGraph(MapRouteGraph.fromJson(jsonDecode(raw)));
    } on Object {
      if (mounted) {
        setState(
          () => _locationMessage = 'No se pudo preparar la red peatonal',
        );
      }
    }
  }

  Future<void> _checkConnectivity() async {
    final result =
        await (widget.connectivityCheck?.call() ??
            const MapConnectivityMonitor().check());
    if (!mounted) return;
    _controller.viewModel.setConnectivity(result);
  }

  Future<void> _syncTracking() =>
      _locationController.setActive(widget.active && widget.mapsConfigured);

  void _onLocation(MapLocationSample sample) {
    if (!_controller.onLocation(sample)) return;
    _locationMessage = null;
    if (_controller.navigationState?.arrived == true && !_arrivalAnnounced) {
      _arrivalAnnounced = true;
      final destination = _controller.routeDestination?.name ?? 'tu destino';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Llegaste a $destination')));
    }
  }

  void _onLocationError(MapLocationFailure failure) {
    if (!mounted) return;
    setState(() => _locationMessage = failure.message);
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
    _queueMarkerIconRefresh();
    _applyCameraCommand();
  }

  void _queueMarkerIconRefresh() {
    if (!widget.mapsConfigured || widget.mapBuilder != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _prepareMarkerIcons();
    });
  }

  Future<void> _prepareMarkerIcons() async {
    final model = _controller.canvas;
    final signature = <String>[
      model.selectedPlaceId ?? '',
      for (final place in model.places)
        <Object?>[
          place.id,
          place.name,
          place.category,
          place.icon,
          place.isFeatured,
        ].join(':'),
    ].join('|');
    if (_markerIconSignature == signature) return;
    _markerIconSignature = signature;
    final ratio = MediaQuery.devicePixelRatioOf(context);
    try {
      final icons = <String, BitmapDescriptor>{};
      for (final place in model.places) {
        icons[place.id] = await _markerIconFactory.create(
          place,
          selected: model.selectedPlaceId == place.id,
          devicePixelRatio: ratio,
        );
      }
      if (!mounted || _markerIconSignature != signature) return;
      setState(
        () => _markerIcons = Map<String, BitmapDescriptor>.unmodifiable(icons),
      );
    } on Object {
      if (_markerIconSignature == signature) _markerIconSignature = null;
    }
  }

  Future<void> _applyCameraCommand() async {
    final command = _controller.cameraCommand;
    final map = _googleMapController;
    if (command == null ||
        map == null ||
        command.revision == _lastCameraRevision ||
        command.points.isEmpty) {
      return;
    }
    _lastCameraRevision = command.revision;
    if (command.points.length == 1) {
      final point = command.points.single;
      await map.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(point.latitude, point.longitude),
          command.action == MapCameraAction.recenter ? 19 : 18.5,
        ),
      );
      return;
    }
    var minLat = command.points.first.latitude;
    var maxLat = minLat;
    var minLng = command.points.first.longitude;
    var maxLng = minLng;
    for (final point in command.points.skip(1)) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }
    await map.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        68,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.programming != widget.programming) {
      oldWidget.programming.removeListener(_refresh);
      widget.programming.addListener(_refresh);
    }
    if (oldWidget.active != widget.active ||
        oldWidget.mapsConfigured != widget.mapsConfigured) {
      _syncTracking();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkConnectivity();
      _syncTracking();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _locationController.setActive(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.programming.removeListener(_refresh);
    _controller.removeListener(_refresh);
    _controller.dispose();
    _locationSubscription?.cancel();
    _errorSubscription?.cancel();
    _locationController.setActive(false);
    if (_ownsLocationController) _locationController.dispose();
    super.dispose();
  }

  void _showAll() {
    _controller.viewModel
      ..setSearch('')
      ..setCategory(MapCategory.all)
      ..setZoom(18.9);
    _googleMapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        const LatLng(FairLocation.latitude, FairLocation.longitude),
        17.2,
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    final location = _controller.canvas.currentLocation;
    if (location == null) {
      await _locationController.setActive(true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_locationMessage ?? 'Buscando tu ubicación…')),
        );
      }
      return;
    }
    _controller.recenter();
    await _googleMapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(location.latitude, location.longitude),
        19,
      ),
    );
  }

  void _startRoute() {
    final destination = _controller.selectedPlace;
    if (destination == null) return;
    final started = _controller.startRoute(destination);
    if (!started) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Necesito una ubicación precisa dentro del recinto para trazar la ruta.',
          ),
        ),
      );
      _locationController.setActive(true);
      return;
    }
    _arrivalAnnounced = false;
    _controller.selectPlace(null);
  }

  void _openAdmin() {
    final admin = _adminController;
    if (admin == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => MapAdminSheet(
        places: widget.mapDocument.snapshot?.places ?? const <MapPlace>[],
        moving: _adminMoveMode,
        adding: _adminAddMode,
        onToggleMoving: () {
          Navigator.of(sheetContext).pop();
          setState(() {
            _adminMoveMode = !_adminMoveMode;
            _adminAddMode = false;
          });
        },
        onToggleAdding: () {
          Navigator.of(sheetContext).pop();
          setState(() {
            _adminAddMode = !_adminAddMode;
            _adminMoveMode = false;
          });
          if (_adminAddMode) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mantén presionado el lugar exacto en el mapa.'),
              ),
            );
          }
        },
        onEdit: (place) async {
          Navigator.of(sheetContext).pop();
          await _editAdminPlace(place);
        },
        onHide: (id) async {
          try {
            await admin.hidePlace(id);
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          } on Object {
            if (mounted) _showAdminError();
          }
        },
        onRestore: () async {
          final restored = await admin.restoreBackup();
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  restored
                      ? 'Respaldo restaurado correctamente'
                      : 'No existe un respaldo disponible',
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _editAdminPlace(MapPlace place) async {
    final admin = _adminController;
    if (admin == null) return;
    final draft = await showDialog<MapAdminPlaceDraft>(
      context: context,
      builder: (_) => MapAdminPlaceDialog(place: place),
    );
    if (draft == null) return;
    try {
      await admin.updatePlace(
        place.id,
        name: draft.name,
        category: draft.category,
        isVisible: draft.isVisible,
        isFeatured: draft.isFeatured,
      );
      await admin.updateEvents(place.id, draft.events);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Punto actualizado correctamente.')),
      );
    } on Object {
      if (mounted) _showAdminError();
    }
  }

  Future<void> _createAdminPlace(LatLng position) async {
    final admin = _adminController;
    if (admin == null || !_adminAddMode) return;
    try {
      await admin.createPlace(
        name: 'Nuevo punto',
        category: 'servicio',
        point: GeoPoint(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
      if (!mounted) return;
      setState(() => _adminAddMode = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Punto agregado. Ábrelo para completar sus datos.'),
        ),
      );
    } on Object {
      if (mounted) _showAdminError();
    }
  }

  Future<void> _moveAdminPlace(MapPlace place, LatLng position) async {
    final admin = _adminController;
    if (admin == null || !_adminMoveMode) return;
    try {
      await admin.movePlace(
        place.id,
        GeoPoint(latitude: position.latitude, longitude: position.longitude),
      );
    } on Object {
      if (mounted) _showAdminError();
    }
  }

  void _showAdminError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo guardar el cambio del mapa.')),
    );
  }

  List<Map<String, String>> _programmingFor(MapPlace place) {
    final venue = place.venue;
    if (venue == null) return const <Map<String, String>>[];
    final days = widget.programming.toJsonList();
    if (days.isEmpty) return const <Map<String, String>>[];
    final raw = days.first[venue];
    if (raw is! List) return const <Map<String, String>>[];
    return raw
        .whereType<Map>()
        .map(
          (event) => <String, String>{
            'time': '${event['time'] ?? ''}',
            'title': '${event['title'] ?? ''}',
          },
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.viewModel.state;
    final selected = _controller.selectedPlace;
    final navigation = _controller.navigationState;
    final top = MediaQuery.paddingOf(context).top;
    return Material(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 96),
        child: Stack(
          children: [
            Positioned.fill(
              child: widget.mapsConfigured
                  ? (widget.mapBuilder ?? _buildGoogleMap)(
                      context,
                      _controller.canvas,
                      _controller.selectPlace,
                      _controller.viewModel.setZoom,
                    )
                  : _MissingMapConfiguration(
                      message: MapRuntimeConfig.missingKeyMessage,
                    ),
            ),
            Positioned(
              top: top + 10,
              left: 14,
              right: 14,
              child: MapSearchFilters(
                viewModel: _controller.viewModel,
                onShowAll: _showAll,
              ),
            ),
            if (!state.online)
              Positioned(
                top: top + 108,
                left: 18,
                right: 18,
                child: _OfflineBanner(onRetry: _checkConnectivity),
              ),
            if (widget.session.isAdmin)
              Positioned(
                key: const Key('map-admin-button'),
                top: top + 110,
                right: 14,
                child: FloatingActionButton.small(
                  heroTag: 'map-admin',
                  tooltip: 'Administrar mapa',
                  onPressed: _openAdmin,
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.gold,
                  child: const Icon(Icons.admin_panel_settings_rounded),
                ),
              ),
            Positioned(
              right: 14,
              bottom: selected == null && navigation == null ? 24 : 205,
              child: Column(
                children: [
                  _MapAction(
                    icon: Icons.fit_screen_rounded,
                    label: 'Ver todo',
                    onTap: _showAll,
                  ),
                  const SizedBox(height: 8),
                  _MapAction(
                    icon: Icons.my_location_rounded,
                    label: 'Mi ubicación',
                    onTap: _goToMyLocation,
                  ),
                ],
              ),
            ),
            if (selected != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: MapPlaceSheet(
                  place: selected,
                  programming: _programmingFor(selected),
                  onClose: () => _controller.selectPlace(null),
                  onNavigate: _startRoute,
                ),
              ),
            if (navigation != null && _controller.routeDestination != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: MapNavigationCard(
                  destination: _controller.routeDestination!.name,
                  remainingMeters: navigation.remainingMeters,
                  progress: navigation.progress,
                  onStop: _controller.stopRoute,
                ),
              ),
            if (_controller.canvas.currentLocation != null &&
                selected == null &&
                navigation == null)
              Positioned(
                left: 14,
                bottom: 22,
                child: _GpsStatus(
                  accuracy: _controller.canvas.accuracyMeters ?? 0,
                  walked: _controller.walkedMeters,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleMap(
    BuildContext context,
    MapCanvasModel model,
    ValueChanged<String> onPlaceTap,
    ValueChanged<double> onZoom,
  ) {
    final markers = model.places.map((place) {
      final featured = place.isFeatured;
      final selected = model.selectedPlaceId == place.id;
      return Marker(
        markerId: MarkerId(place.id),
        position: LatLng(place.latitude, place.longitude),
        zIndexInt: selected ? 40 : (featured ? 20 : 5),
        icon:
            _markerIcons[place.id] ??
            BitmapDescriptor.defaultMarkerWithHue(
              featured ? BitmapDescriptor.hueRed : _hue(place.category),
            ),
        anchor: MapMarkerIconFactory.anchorFor(place),
        infoWindow: InfoWindow(
          title: place.name,
          snippet: featured ? 'Evento destacado' : null,
        ),
        onTap: () => onPlaceTap(place.id),
        draggable: widget.session.isAdmin && _adminMoveMode,
        onDragEnd: (position) => _moveAdminPlace(place, position),
      );
    }).toSet();
    final location = model.currentLocation;
    final circles = <Circle>{
      if (location != null)
        Circle(
          circleId: const CircleId('current-location-accuracy'),
          center: LatLng(location.latitude, location.longitude),
          radius: model.accuracyMeters ?? 0,
          fillColor: AppColors.primary.withValues(alpha: .12),
          strokeColor: AppColors.primary.withValues(alpha: .55),
          strokeWidth: 2,
        ),
    };
    final routePolylines = <Polyline>{
      if (model.remainingPolyline.length > 1)
        Polyline(
          polylineId: const PolylineId('route-remaining'),
          points: model.remainingPolyline
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(growable: false),
          color: AppColors.primary,
          width: 7,
          zIndex: 20,
        ),
      if (model.completedPolyline.length > 1)
        Polyline(
          polylineId: const PolylineId('route-completed'),
          points: model.completedPolyline
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(growable: false),
          color: AppColors.gold,
          width: 7,
          zIndex: 19,
        ),
    };
    if (location != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current-location'),
          position: LatLng(location.latitude, location.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          zIndexInt: 50,
          infoWindow: InfoWindow(
            title: 'Estás aquí',
            snippet: 'Precisión ± ${(model.accuracyMeters ?? 0).round()} m',
          ),
        ),
      );
    }
    return GoogleMap(
      key: const Key('native-google-map'),
      mapType: MapType.hybrid,
      initialCameraPosition: const CameraPosition(
        target: LatLng(FairLocation.latitude, FairLocation.longitude),
        zoom: FairLocation.initialZoom,
      ),
      minMaxZoomPreference: const MinMaxZoomPreference(15, 21),
      markers: markers,
      circles: circles,
      polylines: routePolylines,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: true,
      mapToolbarEnabled: false,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      zoomGesturesEnabled: true,
      tiltGesturesEnabled: true,
      onMapCreated: (controller) {
        _googleMapController = controller;
        _applyCameraCommand();
      },
      onCameraMove: (position) => onZoom(position.zoom),
      onLongPress: _createAdminPlace,
    );
  }

  double _hue(String category) => switch (category) {
    'bano' => BitmapDescriptor.hueAzure,
    'acceso' => BitmapDescriptor.hueGreen,
    'salida' => BitmapDescriptor.hueRose,
    'show' => BitmapDescriptor.hueOrange,
    'comida' => BitmapDescriptor.hueYellow,
    _ => BitmapDescriptor.hueViolet,
  };
}

class _GpsStatus extends StatelessWidget {
  const _GpsStatus({required this.accuracy, required this.walked});

  final double accuracy;
  final double walked;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 5,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          'GPS ± ${accuracy.round()} m  ·  Hoy ${walked.round()} m',
          style: const TextStyle(
            color: AppColors.green,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _MapAction extends StatelessWidget {
  const _MapAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 6,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 74,
          height: 54,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 21),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingMapConfiguration extends StatelessWidget {
  const _MissingMapConfiguration({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFF7F0DC), Color(0xFFE3EFD9)],
        ),
      ),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(28),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.map_outlined,
                size: 46,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Agrega la clave local de Google Maps para cargar la vista satelital. Tus puntos y datos permanecen guardados.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Sin conexión · puntos guardados disponibles',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
