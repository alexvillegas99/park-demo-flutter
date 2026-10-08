import 'dart:math' as math;

import 'map_geo.dart';

class MapRouteNode {
  const MapRouteNode({
    required this.id,
    required this.point,
    this.accessId,
    this.placeId,
  });

  final String id;
  final GeoPoint point;
  final String? accessId;
  final String? placeId;
}

class MapRoute {
  const MapRoute({
    required this.polyline,
    required this.totalMeters,
    this.accessId,
  });

  final List<GeoPoint> polyline;
  final double totalMeters;
  final String? accessId;
}

class MapRouteGraph {
  MapRouteGraph._(this.nodes, this._neighbors);

  factory MapRouteGraph.fromJson(Object? value) {
    if (value is! Map || value['version'] != 2) {
      throw const FormatException('Grafo peatonal inválido');
    }
    final rawNodes = value['nodes'];
    final rawEdges = value['edges'];
    if (rawNodes is! List || rawEdges is! List || rawNodes.isEmpty) {
      throw const FormatException('Grafo peatonal vacío');
    }
    final nodes = <String, MapRouteNode>{};
    for (final raw in rawNodes) {
      if (raw is! Map) throw const FormatException('Nodo inválido');
      final id = '${raw['id'] ?? ''}'.trim();
      if (id.isEmpty || nodes.containsKey(id)) {
        throw const FormatException('ID de nodo inválido');
      }
      nodes[id] = MapRouteNode(
        id: id,
        point: GeoPoint(
          latitude: _number(raw['latitude']),
          longitude: _number(raw['longitude']),
        ),
        accessId: _optional(raw['accessId']),
        placeId: _optional(raw['placeId']),
      );
    }
    final neighbors = <String, Set<String>>{
      for (final id in nodes.keys) id: <String>{},
    };
    for (final raw in rawEdges) {
      if (raw is! Map) throw const FormatException('Arista inválida');
      final from = '${raw['from'] ?? ''}';
      final to = '${raw['to'] ?? ''}';
      if (!nodes.containsKey(from) || !nodes.containsKey(to) || from == to) {
        throw const FormatException('Arista desconectada');
      }
      neighbors[from]!.add(to);
      neighbors[to]!.add(from);
    }
    return MapRouteGraph._(
      Map<String, MapRouteNode>.unmodifiable(nodes),
      Map<String, Set<String>>.unmodifiable(
        neighbors.map(
          (key, value) => MapEntry(key, Set<String>.unmodifiable(value)),
        ),
      ),
    );
  }

  final Map<String, MapRouteNode> nodes;
  final Map<String, Set<String>> _neighbors;

  MapRouteNode? nearestNode(GeoPoint point, {double maxDistanceMeters = 35}) {
    MapRouteNode? closest;
    var shortest = double.infinity;
    for (final node in nodes.values) {
      final distance = MapGeo.distanceMeters(point, node.point);
      if (distance < shortest) {
        shortest = distance;
        closest = node;
      }
    }
    return shortest <= maxDistanceMeters ? closest : null;
  }

  MapRoute? route(
    GeoPoint origin,
    GeoPoint destination, {
    double snapToleranceMeters = 35,
  }) {
    final start = nearestNode(origin, maxDistanceMeters: snapToleranceMeters);
    final finish = nearestNode(
      destination,
      maxDistanceMeters: snapToleranceMeters,
    );
    if (start == null || finish == null) return null;

    final open = <String>{start.id};
    final cameFrom = <String, String>{};
    final g = <String, double>{
      for (final id in nodes.keys) id: double.infinity,
    };
    final f = <String, double>{
      for (final id in nodes.keys) id: double.infinity,
    };
    g[start.id] = 0;
    f[start.id] = MapGeo.distanceMeters(start.point, finish.point);

    while (open.isNotEmpty) {
      final current = open.reduce((a, b) => f[a]! <= f[b]! ? a : b);
      if (current == finish.id) {
        final ids = <String>[current];
        var cursor = current;
        var previous = cameFrom[cursor];
        while (previous != null) {
          ids.add(previous);
          cursor = previous;
          previous = cameFrom[cursor];
        }
        final orderedIds = ids.reversed;
        final polyline = <GeoPoint>[
          origin,
          ...orderedIds.map((id) => nodes[id]!.point),
          destination,
        ];
        final compact = <GeoPoint>[];
        for (final point in polyline) {
          if (compact.isEmpty ||
              MapGeo.distanceMeters(compact.last, point) > 0.05) {
            compact.add(point);
          }
        }
        var total = 0.0;
        for (var index = 1; index < compact.length; index += 1) {
          total += MapGeo.distanceMeters(compact[index - 1], compact[index]);
        }
        return MapRoute(
          polyline: List<GeoPoint>.unmodifiable(compact),
          totalMeters: total,
          accessId: start.accessId,
        );
      }
      open.remove(current);
      for (final neighbor in _neighbors[current]!) {
        final tentative =
            g[current]! +
            MapGeo.distanceMeters(
              nodes[current]!.point,
              nodes[neighbor]!.point,
            );
        if (tentative >= g[neighbor]!) continue;
        cameFrom[neighbor] = current;
        g[neighbor] = tentative;
        f[neighbor] =
            tentative +
            MapGeo.distanceMeters(nodes[neighbor]!.point, finish.point);
        open.add(neighbor);
      }
    }
    return null;
  }

  static double _number(Object? value) {
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    if (number == null || !number.isFinite) {
      throw const FormatException('Coordenada de nodo inválida');
    }
    return number;
  }

  static String? _optional(Object? value) {
    final text = '${value ?? ''}'.trim();
    return text.isEmpty ? null : text;
  }
}

double distanceToPolylineMeters(GeoPoint point, List<GeoPoint> polyline) {
  if (polyline.isEmpty) return double.infinity;
  if (polyline.length == 1) {
    return MapGeo.distanceMeters(point, polyline.single);
  }
  var best = double.infinity;
  final latitudeScale = 111132.0;
  final longitudeScale = 111320 * math.cos(point.latitude * math.pi / 180);
  for (var index = 1; index < polyline.length; index += 1) {
    final a = polyline[index - 1];
    final b = polyline[index];
    final ax = (a.longitude - point.longitude) * longitudeScale;
    final ay = (a.latitude - point.latitude) * latitudeScale;
    final bx = (b.longitude - point.longitude) * longitudeScale;
    final by = (b.latitude - point.latitude) * latitudeScale;
    final dx = bx - ax;
    final dy = by - ay;
    final denominator = dx * dx + dy * dy;
    final t = denominator == 0
        ? 0.0
        : ((-ax * dx - ay * dy) / denominator).clamp(0.0, 1.0);
    final closestX = ax + dx * t;
    final closestY = ay + dy * t;
    best = math.min(best, math.sqrt(closestX * closestX + closestY * closestY));
  }
  return best;
}
