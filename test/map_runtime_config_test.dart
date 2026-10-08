import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/map/map_runtime_config.dart';

void main() {
  test('el mapa queda deshabilitado hasta configurar la integración local', () {
    expect(MapRuntimeConfig.mapsConfigured, isFalse);
    expect(
      MapRuntimeConfig.missingKeyMessage.toLowerCase(),
      contains('configurar el mapa'),
    );
  });

  test('la configuración Dart no contiene ni solicita la clave real', () {
    final source = File('lib/map/map_runtime_config.dart').readAsStringSync();

    expect(source, isNot(contains('GOOGLE_MAPS_API_KEY')));
    expect(source, isNot(contains('AIza')));
  });
}
