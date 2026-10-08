import 'package:flutter/widgets.dart';

import 'daily_walking_tracker.dart';
import 'map_document_controller.dart';
import 'map_geo.dart';
import 'map_location_controller.dart';
import 'map_navigation_controller.dart';
import 'map_route_graph.dart';
import 'map_view_model.dart';

abstract interface class MapProgrammingSource implements Listenable {
  List<Map<String, Object>> toJsonList();
}

@immutable
class MapCanvasModel {
  const MapCanvasModel({
    required this.places,
    required this.selectedPlaceId,
    this.currentLocation,
    this.accuracyMeters,
    this.remainingPolyline = const <GeoPoint>[],
    this.completedPolyline = const <GeoPoint>[],
    this.walkedMeters = 0,
  });

  final List<MapPlace> places;
  final String? selectedPlaceId;
  final GeoPoint? currentLocation;
  final double? accuracyMeters;
  final List<GeoPoint> remainingPolyline;
  final List<GeoPoint> completedPolyline;
  final double walkedMeters;
}

enum MapCameraAction { recenter, fitRoute, fitVenue }

@immutable
class MapCameraCommand {
  const MapCameraCommand(this.action, this.points, this.revision);

  final MapCameraAction action;
  final List<GeoPoint> points;
  final int revision;
}

typedef MapCanvasBuilder =
    Widget Function(
      BuildContext context,
      MapCanvasModel model,
      ValueChanged<String> onPlaceTap,
      ValueChanged<double> onZoom,
    );

class MapScreenController extends ChangeNotifier {
  MapScreenController({
    required MapDocumentController document,
    MapRouteGraph? routeGraph,
    DailyWalkingTracker? walkingTracker,
  }) : viewModel = MapViewModel(document: document),
       _walkingTracker = walkingTracker ?? DailyWalkingTracker() {
    viewModel.addListener(_viewChanged);
    if (routeGraph != null) setRouteGraph(routeGraph, notify: false);
  }

  final MapViewModel viewModel;
  final DailyWalkingTracker _walkingTracker;
  GeoPoint? _currentLocation;
  double? _accuracyMeters;
  MapLocationSample? _lastAccepted;
  MapNavigationController? _navigation;
  MapPlace? _routeDestination;
  MapCameraCommand? _cameraCommand;
  int _cameraRevision = 0;

  MapCanvasModel get canvas => MapCanvasModel(
    places: viewModel.visiblePlaces,
    selectedPlaceId: viewModel.state.selectedPlaceId,
    currentLocation: _currentLocation,
    accuracyMeters: _accuracyMeters,
    remainingPolyline:
        _navigation?.state?.remainingPolyline ?? const <GeoPoint>[],
    completedPolyline:
        _navigation?.state?.completedPolyline ?? const <GeoPoint>[],
    walkedMeters: _walkingTracker.meters,
  );

  MapPlace? get selectedPlace => viewModel.selectedPlace;
  MapNavigationState? get navigationState => _navigation?.state;
  MapPlace? get routeDestination => _routeDestination;
  double get walkedMeters => _walkingTracker.meters;
  MapCameraCommand? get cameraCommand => _cameraCommand;

  void selectPlace(String? id) => viewModel.selectPlace(id);

  void setLocation(GeoPoint point, {required double accuracyMeters}) {
    _currentLocation = point;
    _accuracyMeters = accuracyMeters;
    viewModel.setCurrentLocation(point);
  }

  void setRouteGraph(MapRouteGraph graph, {bool notify = true}) {
    _navigation?.removeListener(_navigationChanged);
    _navigation?.dispose();
    _navigation = MapNavigationController(graph: graph)
      ..addListener(_navigationChanged);
    if (notify) notifyListeners();
  }

  bool onLocation(MapLocationSample sample) {
    if (!sample.accuracy.isFinite || sample.accuracy > 35) return false;
    final previous = _lastAccepted;
    if (previous != null) {
      if (!sample.timestamp.isAfter(previous.timestamp)) return false;
      final seconds =
          sample.timestamp.difference(previous.timestamp).inMilliseconds / 1000;
      final meters = MapGeo.distanceMeters(previous.point, sample.point);
      if (seconds <= 0 || meters / seconds > 3) return false;
    }
    _lastAccepted = sample;
    _walkingTracker.update(sample);
    _currentLocation = sample.point;
    _accuracyMeters = sample.accuracy;
    viewModel.setCurrentLocation(sample.point);
    _navigation?.update(sample);
    return true;
  }

  bool startRoute(MapPlace destination) {
    final origin = _currentLocation;
    final navigation = _navigation;
    if (origin == null || navigation == null) return false;
    if (!navigation.start(origin, destination.point)) return false;
    _routeDestination = destination;
    _issueCamera(MapCameraAction.fitRoute, navigation.state!.remainingPolyline);
    notifyListeners();
    return true;
  }

  void stopRoute() {
    _navigation?.finish();
    _routeDestination = null;
    notifyListeners();
  }

  void recenter() {
    final location = _currentLocation;
    if (location != null) {
      _issueCamera(MapCameraAction.recenter, <GeoPoint>[location]);
      notifyListeners();
    }
  }

  void fitVenue(MapPlace place) {
    _issueCamera(MapCameraAction.fitVenue, <GeoPoint>[place.point]);
    notifyListeners();
  }

  void _issueCamera(MapCameraAction action, List<GeoPoint> points) {
    _cameraRevision += 1;
    _cameraCommand = MapCameraCommand(
      action,
      List<GeoPoint>.unmodifiable(points),
      _cameraRevision,
    );
  }

  void _viewChanged() => notifyListeners();
  void _navigationChanged() => notifyListeners();

  @override
  void dispose() {
    viewModel.removeListener(_viewChanged);
    viewModel.dispose();
    _navigation?.removeListener(_navigationChanged);
    _navigation?.dispose();
    super.dispose();
  }
}
