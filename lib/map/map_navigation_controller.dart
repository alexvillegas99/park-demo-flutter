import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'map_geo.dart';
import 'map_location_controller.dart';
import 'map_route_graph.dart';

@immutable
class MapNavigationState {
  const MapNavigationState({
    required this.completedPolyline,
    required this.remainingPolyline,
    required this.totalMeters,
    required this.remainingMeters,
    required this.progress,
    required this.arrived,
    required this.recalculations,
  });

  final List<GeoPoint> completedPolyline;
  final List<GeoPoint> remainingPolyline;
  final double totalMeters;
  final double remainingMeters;
  final double progress;
  final bool arrived;
  final int recalculations;
}

class MapNavigationController extends ChangeNotifier {
  MapNavigationController({required MapRouteGraph graph}) : _graph = graph;

  final MapRouteGraph _graph;
  GeoPoint? _destination;
  MapRoute? _route;
  final List<GeoPoint> _completed = <GeoPoint>[];
  MapNavigationState? _state;
  int _offRouteSamples = 0;

  MapNavigationState? get state => _state;

  bool start(GeoPoint origin, GeoPoint destination) {
    final route = _graph.route(origin, destination);
    if (route == null) return false;
    _destination = destination;
    _route = route;
    _completed
      ..clear()
      ..add(origin);
    _offRouteSamples = 0;
    _state = MapNavigationState(
      completedPolyline: List<GeoPoint>.unmodifiable(_completed),
      remainingPolyline: route.polyline,
      totalMeters: route.totalMeters,
      remainingMeters: route.totalMeters,
      progress: 0,
      arrived: false,
      recalculations: 0,
    );
    notifyListeners();
    return true;
  }

  void update(MapLocationSample sample) {
    final destination = _destination;
    final currentRoute = _route;
    final currentState = _state;
    if (destination == null || currentRoute == null || currentState == null) {
      return;
    }
    final position = sample.point;
    _completed.add(position);
    final arrivalRadius = math.max(6.0, math.min(sample.accuracy, 15.0));
    final directRemaining = MapGeo.distanceMeters(position, destination);
    if (directRemaining <= arrivalRadius) {
      _state = MapNavigationState(
        completedPolyline: List<GeoPoint>.unmodifiable(_completed),
        remainingPolyline: <GeoPoint>[position, destination],
        totalMeters: currentState.totalMeters,
        remainingMeters: 0,
        progress: 1,
        arrived: true,
        recalculations: currentState.recalculations,
      );
      notifyListeners();
      return;
    }

    final offRoute =
        distanceToPolylineMeters(position, currentRoute.polyline) > 15;
    _offRouteSamples = offRoute ? _offRouteSamples + 1 : 0;
    var remainingRoute = _graph.route(position, destination);
    var recalculations = currentState.recalculations;
    if (_offRouteSamples >= 2 && remainingRoute != null) {
      _route = remainingRoute;
      recalculations += 1;
      _offRouteSamples = 0;
    } else {
      remainingRoute ??= currentRoute;
    }
    final remaining = remainingRoute.totalMeters;
    final progress = (1 - remaining / currentState.totalMeters).clamp(0.0, 1.0);
    _state = MapNavigationState(
      completedPolyline: List<GeoPoint>.unmodifiable(_completed),
      remainingPolyline: remainingRoute.polyline,
      totalMeters: currentState.totalMeters,
      remainingMeters: remaining,
      progress: progress,
      arrived: false,
      recalculations: recalculations,
    );
    notifyListeners();
  }

  void finish() {
    _destination = null;
    _route = null;
    _completed.clear();
    _state = null;
    _offRouteSamples = 0;
    notifyListeners();
  }
}
