import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/map/map_location_controller.dart';

class FakeMapPositionSource implements MapPositionSource {
  final controller = StreamController<MapPositionFix>.broadcast();
  MapLocationPermission permission = MapLocationPermission.granted;
  int permissionChecks = 0;
  int watches = 0;
  int stops = 0;

  @override
  Future<MapLocationPermission> ensurePermission() async {
    permissionChecks += 1;
    return permission;
  }

  @override
  Stream<MapPositionFix> watch() {
    watches += 1;
    return controller.stream;
  }

  @override
  Future<void> stop() async {
    stops += 1;
  }

  Future<void> close() => controller.close();
}

void main() {
  const boundary = MapLocationBoundary(
    latitude: -1.3690877425784418,
    longitude: -78.647792380582,
    radiusMeters: 900,
  );

  test('inicia solo al activar y no duplica la suscripción', () async {
    final source = FakeMapPositionSource();
    final controller = MapLocationController(
      source: source,
      boundary: boundary,
    );

    await controller.setActive(false);
    expect(source.watches, 0);

    await controller.setActive(true);
    await controller.setActive(true);
    expect(source.permissionChecks, 1);
    expect(source.watches, 1);

    await controller.setActive(false);
    expect(source.stops, 1);

    await controller.setActive(true);
    expect(source.permissionChecks, 2);
    expect(source.watches, 2);

    controller.dispose();
    await source.close();
  });

  test('publica muestras interiores y exteriores sin descartar', () async {
    final source = FakeMapPositionSource();
    final controller = MapLocationController(
      source: source,
      boundary: boundary,
    );
    final samples = <MapLocationSample>[];
    final subscription = controller.updates.listen(samples.add);

    await controller.setActive(true);
    source.controller.add(
      MapPositionFix(
        latitude: boundary.latitude,
        longitude: boundary.longitude,
        accuracy: 4,
        timestamp: DateTime.utc(2026, 10, 8, 12),
      ),
    );
    source.controller.add(
      MapPositionFix(
        latitude: -1.34,
        longitude: -78.61,
        accuracy: 7,
        timestamp: DateTime.utc(2026, 10, 8, 12, 1),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(samples, hasLength(2));
    expect(samples.first.inside, isTrue);
    expect(samples.last.inside, isFalse);
    expect(samples.last.toJson()['timestamp'], isA<int>());

    await subscription.cancel();
    controller.dispose();
    await source.close();
  });

  test('expone el error de permiso sin abrir un stream', () async {
    final source = FakeMapPositionSource()
      ..permission = MapLocationPermission.deniedForever;
    final controller = MapLocationController(
      source: source,
      boundary: boundary,
    );
    final errors = <MapLocationFailure>[];
    final subscription = controller.errors.listen(errors.add);

    await controller.setActive(true);
    await Future<void>.delayed(Duration.zero);

    expect(source.watches, 0);
    expect(errors.single.code, MapLocationFailureCode.permissionDenied);

    await subscription.cancel();
    controller.dispose();
    await source.close();
  });
}
