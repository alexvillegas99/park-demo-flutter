import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/map/map_geo.dart';
import 'package:park_demo/map/map_route_graph.dart';

MapRouteGraph _graph() => MapRouteGraph.fromJson(<String, Object?>{
  'version': 2,
  'nodes': <Object?>[
    <String, Object?>{
      'id': 'luna',
      'latitude': -1.3690,
      'longitude': -78.6480,
      'placeId': '28',
    },
    <String, Object?>{
      'id': 'centro',
      'latitude': -1.3688,
      'longitude': -78.6478,
    },
    <String, Object?>{
      'id': 'mega',
      'latitude': -1.3686,
      'longitude': -78.6476,
      'placeId': '20',
    },
    <String, Object?>{'id': 'aislado', 'latitude': -1.36, 'longitude': -78.63},
  ],
  'edges': <Object?>[
    <String, Object?>{'from': 'luna', 'to': 'centro'},
    <String, Object?>{'from': 'centro', 'to': 'mega'},
  ],
});

void main() {
  test('calcula una ruta conectada de Luna a Megaescenario', () {
    final graph = _graph();
    final origin = GeoPoint(latitude: -1.3690, longitude: -78.6480);
    final destination = GeoPoint(latitude: -1.3686, longitude: -78.6476);
    final route = graph.route(origin, destination);

    expect(route, isNotNull);
    expect(route!.polyline, hasLength(greaterThanOrEqualTo(3)));
    expect(
      route.totalMeters,
      greaterThanOrEqualTo(MapGeo.distanceMeters(origin, destination)),
    );
  });

  test('rechaza un destino sin conexión peatonal', () {
    final graph = _graph();
    expect(
      graph.route(
        GeoPoint(latitude: -1.3690, longitude: -78.6480),
        GeoPoint(latitude: -1.36, longitude: -78.63),
      ),
      isNull,
    );
  });
}
