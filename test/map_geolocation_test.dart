import 'package:geolocator/geolocator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/main.dart';

void main() {
  test('el mapa usa primero el recurso offline incluido', () {
    expect(MapExperienceConfig.bundledMapFirst, isTrue);
    expect(MapExperienceConfig.remoteFontsEnabled, isFalse);
  });

  test('la geocerca coincide con el centro del plano de la feria', () {
    expect(FairLocation.latitude, closeTo(-1.3690877, 0.00001));
    expect(FairLocation.longitude, closeTo(-78.6477924, 0.00001));
    expect(FairLocation.radiusMeters, greaterThanOrEqualTo(850));
  });

  test('la lectura inicial solicita precisión apta para navegación', () {
    expect(
      FairLocation.initialLocationSettings.accuracy,
      LocationAccuracy.bestForNavigation,
    );
  });

  test('el seguimiento publica movimientos desde un metro', () {
    expect(
      FairLocation.trackingLocationSettings.accuracy,
      LocationAccuracy.bestForNavigation,
    );
    expect(FairLocation.trackingLocationSettings.distanceFilter, 1);
  });
}
