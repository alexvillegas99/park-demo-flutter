import 'package:geolocator/geolocator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/map/map_location_controller.dart';
import 'package:park_demo/map/map_runtime_config.dart';
import 'package:park_demo/map/map_screen.dart';

void main() {
  test('el mapa exige confirmar una clave local para montar Google Maps', () {
    expect(MapRuntimeConfig.mapsConfigured, isFalse);
  });

  test('la geocerca coincide con el centro del plano de la feria', () {
    expect(FairLocation.latitude, closeTo(-1.3690877, 0.00001));
    expect(FairLocation.longitude, closeTo(-78.6477924, 0.00001));
    expect(FairLocation.radiusMeters, greaterThanOrEqualTo(850));
  });

  test('el seguimiento publica movimientos desde un metro', () {
    expect(
      GeolocatorMapPositionSource.trackingSettings.accuracy,
      LocationAccuracy.bestForNavigation,
    );
    expect(GeolocatorMapPositionSource.trackingSettings.distanceFilter, 1);
  });
}
