import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/map/map_geo.dart';
import 'package:park_demo/map/map_location_controller.dart';
import 'package:park_demo/map/map_navigation_controller.dart';
import 'package:park_demo/map/map_route_graph.dart';

MapRouteGraph _graph() => MapRouteGraph.fromJson(<String, Object?>{
  'version': 2,
  'nodes': <Object?>[
    <String, Object?>{'id': 'a', 'latitude': -1.3690, 'longitude': -78.6480},
    <String, Object?>{'id': 'b', 'latitude': -1.3688, 'longitude': -78.6478},
    <String, Object?>{'id': 'c', 'latitude': -1.3686, 'longitude': -78.6476},
  ],
  'edges': <Object?>[
    <String, Object?>{'from': 'a', 'to': 'b'},
    <String, Object?>{'from': 'b', 'to': 'c'},
  ],
});

MapLocationSample _sample(
  double lat,
  double lng,
  int seconds, {
  double accuracy = 4,
}) => MapLocationSample(
  latitude: lat,
  longitude: lng,
  accuracy: accuracy,
  timestamp: DateTime.utc(2026, 10, 8, 12).add(Duration(seconds: seconds)),
  inside: true,
);

void main() {
  test(
    'actualiza distancia, progreso y detecta llegada con radio dinámico',
    () {
      final controller = MapNavigationController(graph: _graph());
      final destination = GeoPoint(latitude: -1.3686, longitude: -78.6476);
      expect(
        controller.start(
          GeoPoint(latitude: -1.3690, longitude: -78.6480),
          destination,
        ),
        isTrue,
      );
      final initial = controller.state!.remainingMeters;

      controller.update(_sample(-1.3688, -78.6478, 10));
      expect(controller.state!.remainingMeters, lessThan(initial));
      expect(controller.state!.progress, greaterThan(0));

      controller.update(_sample(-1.36861, -78.64761, 20, accuracy: 8));
      expect(controller.state!.arrived, isTrue);
    },
  );

  test('recalcula después de dos muestras consecutivas fuera de ruta', () {
    final controller = MapNavigationController(graph: _graph());
    controller.start(
      GeoPoint(latitude: -1.3690, longitude: -78.6480),
      GeoPoint(latitude: -1.3686, longitude: -78.6476),
    );
    controller.update(_sample(-1.36875, -78.64755, 10));
    expect(controller.state!.recalculations, 0);
    controller.update(_sample(-1.36874, -78.64754, 20));
    expect(controller.state!.recalculations, 1);
  });
}
