import 'package:flutter/foundation.dart';

import 'map_document_controller.dart';
import 'map_geo.dart';

enum MapCategory {
  all(null, 'Todos'),
  events('evento', 'Eventos'),
  bathrooms('bano', 'Baños'),
  accesses('acceso', 'Accesos'),
  exits('salida', 'Salidas'),
  attractions('show', 'Atracciones'),
  food('comida', 'Comida'),
  services('servicio', 'Servicios'),
  parking('parqueo', 'Parqueo'),
  zones('zona', 'Zonas');

  const MapCategory(this.value, this.label);
  final String? value;
  final String label;
}

@immutable
class MapViewState {
  const MapViewState({
    required this.search,
    required this.category,
    required this.zoom,
    required this.online,
    this.selectedPlaceId,
    this.currentLocation,
  });

  final String search;
  final MapCategory category;
  final double zoom;
  final bool online;
  final String? selectedPlaceId;
  final GeoPoint? currentLocation;
}

class NearbyMapPlace {
  const NearbyMapPlace(this.place, this.meters);
  final MapPlace place;
  final double meters;
}

class MapViewModel extends ChangeNotifier {
  MapViewModel({required MapDocumentController document})
    : _document = document {
    _document.addListener(_documentChanged);
  }

  final MapDocumentController _document;
  String _search = '';
  MapCategory _category = MapCategory.all;
  double _zoom = 17.6;
  bool _online = true;
  String? _selectedPlaceId;
  GeoPoint? _currentLocation;

  MapViewState get state => MapViewState(
    search: _search,
    category: _category,
    zoom: _zoom,
    online: _online,
    selectedPlaceId: _selectedPlaceId,
    currentLocation: _currentLocation,
  );

  MapPlace? get selectedPlace {
    final id = _selectedPlaceId;
    if (id == null) return null;
    for (final place in _document.visiblePlaces) {
      if (place.id == id) return place;
    }
    return null;
  }

  List<MapPlace> get visiblePlaces {
    final all = _document.visiblePlaces;
    Iterable<MapPlace> result;
    final query = _normalize(_search);
    if (query.isNotEmpty) {
      result = all.where((place) => _normalize(place.name).contains(query));
    } else if (_category != MapCategory.all) {
      result = all.where((place) => place.category == _category.value);
    } else {
      result = all.where((place) {
        if (place.isFeatured) return true;
        if (place.category == 'zona') return _zoom >= 18.8;
        return _zoom >= 18.0;
      });
    }
    final places = result.toList(growable: true);
    final selected = selectedPlace;
    if (selected != null && !places.any((place) => place.id == selected.id)) {
      places.add(selected);
    }
    return List<MapPlace>.unmodifiable(places);
  }

  List<NearbyMapPlace> get nearbyPlaces {
    final origin = _currentLocation;
    if (origin == null) return const <NearbyMapPlace>[];
    final places =
        _document.visiblePlaces
            .map(
              (place) => NearbyMapPlace(
                place,
                MapGeo.distanceMeters(origin, place.point),
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => a.meters.compareTo(b.meters));
    return List<NearbyMapPlace>.unmodifiable(places);
  }

  List<GeoPoint> get fitBoundsPoints {
    final points = visiblePlaces.map((place) => place.point).toList();
    final location = _currentLocation;
    if (location != null) points.insert(0, location);
    return List<GeoPoint>.unmodifiable(points);
  }

  void selectPlace(String? id) {
    if (_selectedPlaceId == id) return;
    _selectedPlaceId = id;
    notifyListeners();
  }

  void setSearch(String value) {
    if (_search == value) return;
    _search = value;
    notifyListeners();
  }

  void setCategory(MapCategory value) {
    if (_category == value) return;
    _category = value;
    notifyListeners();
  }

  void setZoom(double value) {
    if ((_zoom - value).abs() < 0.001) return;
    _zoom = value;
    notifyListeners();
  }

  void setConnectivity(bool online) {
    if (_online == online) return;
    _online = online;
    notifyListeners();
  }

  void setCurrentLocation(GeoPoint? location) {
    _currentLocation = location;
    notifyListeners();
  }

  void _documentChanged() => notifyListeners();

  static String _normalize(String value) {
    const replacements = <String, String>{
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    var normalized = value.toLowerCase().trim();
    replacements.forEach(
      (from, to) => normalized = normalized.replaceAll(from, to),
    );
    return normalized;
  }

  @override
  void dispose() {
    _document.removeListener(_documentChanged);
    super.dispose();
  }
}
