import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/map/map_document_controller.dart';
import 'package:park_demo/map/map_geo.dart';
import 'package:park_demo/map/map_location_controller.dart';
import 'package:park_demo/map/map_route_graph.dart';
import 'package:park_demo/map/map_screen_controller.dart';

MapDocumentController _document() {
  final controller = MapDocumentController();
  controller.acceptJson(
    jsonEncode(<String, Object?>{
      'schemaVersion': 4,
      'updatedAt': '2026-10-08T12:00:00Z',
      'places': <Object?>[
        for (final id in <String>['20', '28', '93'])
          <String, Object?>{
            'id': id,
            'cat': 'evento',
            'name': id == '20'
                ? 'Mega Escenario'
                : id == '28'
                ? 'Plaza de la Luna'
                : 'Plaza del Sol',
            'latitude': -1.369 + int.parse(id) / 1000000,
            'longitude': -78.648,
            'isVisible': true,
            'isFeatured': true,
            'needsReview': false,
            'events': <Object?>[],
          },
      ],
    }),
  );
  return controller;
}

void main() {
  test('construye el lienzo con escenarios y ubicación actual', () {
    final controller = MapScreenController(document: _document());
    expect(controller.canvas.places, hasLength(3));
    controller.setLocation(
      GeoPoint(latitude: -1.369, longitude: -78.648),
      accuracyMeters: 6,
    );
    expect(controller.canvas.currentLocation, isNotNull);
    expect(controller.canvas.accuracyMeters, 6);
  });

  test(
    'acepta GPS preciso, suma recorrido y crea una ruta sin recentrado forzado',
    () {
      final graph = MapRouteGraph.fromJson(<String, Object?>{
        'version': 2,
        'nodes': <Object?>[
          <String, Object?>{
            'id': 'a',
            'latitude': -1.369,
            'longitude': -78.648,
          },
          <String, Object?>{
            'id': 'b',
            'latitude': -1.36898,
            'longitude': -78.648,
          },
        ],
        'edges': <Object?>[
          <String, Object?>{'from': 'a', 'to': 'b'},
        ],
      });
      final controller = MapScreenController(
        document: _document(),
        routeGraph: graph,
      );
      final time = DateTime.utc(2026, 10, 8, 12);
      expect(
        controller.onLocation(
          MapLocationSample(
            latitude: -1.369,
            longitude: -78.648,
            accuracy: 4,
            timestamp: time,
            inside: true,
          ),
        ),
        isTrue,
      );
      expect(controller.cameraCommand, isNull);
      expect(
        controller.startRoute(controller.viewModel.visiblePlaces.first),
        isTrue,
      );
      expect(controller.canvas.remainingPolyline, isNotEmpty);

      final walked = controller.walkedMeters;
      expect(
        controller.onLocation(
          MapLocationSample(
            latitude: -1.3689,
            longitude: -78.648,
            accuracy: 50,
            timestamp: time.add(const Duration(seconds: 10)),
            inside: true,
          ),
        ),
        isFalse,
      );
      expect(controller.walkedMeters, walked);
    },
  );
}
