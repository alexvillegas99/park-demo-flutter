import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/main.dart';

void main() {
  test('la geocerca coincide con el centro del plano de la feria', () {
    expect(FairLocation.latitude, closeTo(-1.3690877, 0.00001));
    expect(FairLocation.longitude, closeTo(-78.6477924, 0.00001));
    expect(FairLocation.radiusMeters, greaterThanOrEqualTo(850));
  });
}
