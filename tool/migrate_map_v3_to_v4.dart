import 'dart:convert';
import 'dart:io';

import 'package:park_demo/map/map_geo.dart';

const _officialCoordinates = <int, ({double x, double y})>{
  11: (x: 690, y: 120),
  12: (x: 345, y: 555),
  13: (x: 160, y: 1060),
  14: (x: 1120, y: 970),
  15: (x: 1300, y: 525),
  16: (x: 1415, y: 305),
  20: (x: 890, y: 755),
  21: (x: 990, y: 570),
  22: (x: 740, y: 515),
  23: (x: 750, y: 590),
  24: (x: 1050, y: 535),
  25: (x: 900, y: 660),
  26: (x: 620, y: 620),
  27: (x: 235, y: 935),
  28: (x: 600, y: 685),
  29: (x: 1175, y: 620),
  30: (x: 610, y: 650),
  31: (x: 1010, y: 700),
  32: (x: 540, y: 610),
  39: (x: 800, y: 700),
  40: (x: 820, y: 720),
  41: (x: 900, y: 600),
  93: (x: 950, y: 610),
};

const _recommendationIds = <int, String>{
  20: 'megaescenario',
  21: 'mushuc-park',
  22: 'resbaladera-gigante',
  23: 'parque-dinosaurios',
  28: 'plaza-luna',
  29: 'granja-interactiva',
  30: 'patio-luna',
  31: 'patio-mega',
  93: 'plaza-sol',
};

void main(List<String> arguments) {
  final write = arguments.contains('--write');
  final check = arguments.contains('--check');
  if (!write && !check) {
    stderr.writeln('Usa --write o --check.');
    exitCode = 64;
    return;
  }

  final mapOutput = File('assets/map/map_document_v4.json');
  final routeOutput = File('assets/map/route_graph_v2.json');
  final mapJson = _buildMapJson();
  final routeJson = _buildRouteJson();

  if (write) {
    mapOutput.writeAsStringSync(mapJson);
    routeOutput.writeAsStringSync(routeJson);
    stdout.writeln('Generados ${mapOutput.path} y ${routeOutput.path}.');
  }
  if (check) {
    final matches =
        mapOutput.existsSync() &&
        routeOutput.existsSync() &&
        mapOutput.readAsStringSync() == mapJson &&
        routeOutput.readAsStringSync() == routeJson;
    if (!matches) {
      stderr.writeln('Los activos geográficos no coinciden con la migración.');
      exitCode = 1;
      return;
    }
    final decoded = jsonDecode(mapJson) as Map<String, Object?>;
    final places = decoded['places']! as List;
    for (final raw in places) {
      final place = raw as Map;
      GeoPoint(
        latitude: (place['latitude']! as num).toDouble(),
        longitude: (place['longitude']! as num).toDouble(),
      );
    }
    stdout.writeln(
      '${places.length} lugares válidos; cero coordenadas inválidas.',
    );
  }
}

String _buildMapJson() {
  final source = File('assets/map/map_places.js').readAsStringSync();
  const marker = 'const legacyPlaces = ';
  final start = source.indexOf(marker) + marker.length;
  final end = source.indexOf('\n];', start) + 2;
  if (start < marker.length || end < 2) {
    throw const FormatException('No se encontró legacyPlaces');
  }
  final rawPlaces = jsonDecode(source.substring(start, end)) as List;
  final places = <Map<String, Object?>>[];
  for (final raw in rawPlaces) {
    final place = Map<String, Object?>.from(raw as Map);
    if (place['cat'] == 'trans') continue;
    final id = (place['id']! as num).toInt();
    final official = _officialCoordinates[id];
    final x = (place['x']! as num).toDouble();
    final y = (place['y']! as num).toDouble();
    final migrated = official ?? LegacyMapProjection.legacyToCurrent(x, y);
    final point = LegacyMapProjection.toGeo(
      migrated.x.clamp(0, LegacyMapProjection.width).toDouble(),
      migrated.y.clamp(0, LegacyMapProjection.height).toDouble(),
    );
    places.add(<String, Object?>{
      'id': '$id',
      'cat': place['cat'],
      'name': place['name'],
      'latitude': point.latitude,
      'longitude': point.longitude,
      'isVisible': true,
      'isFeatured': place['venue'] != null,
      'needsReview': official == null,
      if (_recommendationIds[id] case final recommendationId?)
        'recommendationId': recommendationId,
      if (place['icon'] != null) 'icon': place['icon'],
      if (place['venue'] != null) 'venue': place['venue'],
      'events': place['events'] ?? const <Object?>[],
    });
  }
  final migrated = <String, Object?>{
    'schemaVersion': 4,
    'updatedAt': '2026-10-08T13:00:00.000Z',
    'places': places,
  };
  return '${const JsonEncoder.withIndent('  ').convert(migrated)}\n';
}

String _buildRouteJson() {
  final source = File('assets/map/route_graph.js').readAsStringSync();
  final nodePattern = RegExp(
    r"\{id: '([^']+)', x: ([\d.]+), y: ([\d.]+)(?:, (accessId|placeId): (\d+))?\}",
  );
  final edgePattern = RegExp(r"\['([^']+)', '([^']+)'\]");
  final nodes = nodePattern
      .allMatches(source)
      .map((match) {
        final point = LegacyMapProjection.toGeo(
          double.parse(match.group(2)!),
          double.parse(match.group(3)!),
        );
        return <String, Object?>{
          'id': match.group(1),
          'latitude': point.latitude,
          'longitude': point.longitude,
          if (match.group(4) != null) match.group(4)!: match.group(5),
        };
      })
      .toList(growable: false);
  final edges = edgePattern
      .allMatches(source)
      .map((match) {
        return <String, Object?>{'from': match.group(1), 'to': match.group(2)};
      })
      .toList(growable: false);
  if (nodes.isEmpty || edges.isEmpty) {
    throw const FormatException('No se pudo leer el grafo heredado');
  }
  return '${const JsonEncoder.withIndent('  ').convert(<String, Object?>{'version': 2, 'nodes': nodes, 'edges': edges})}\n';
}
