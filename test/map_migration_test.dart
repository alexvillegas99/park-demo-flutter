import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/map/map_document_controller.dart';

void main() {
  test(
    'migra un documento v3, preserva eventos y usa coordenadas geográficas',
    () {
      final migrated = MapDocumentMigration.migrateV3(<String, Object?>{
        'schemaVersion': 3,
        'updatedAt': '2026-10-08T12:00:00.000Z',
        'places': <Object?>[
          <String, Object?>{
            'id': 'custom',
            'cat': 'evento',
            'name': 'Escenario personalizado',
            'x': 890,
            'y': 755,
            'events': <Object?>[
              <String, Object?>{'time': '18:00', 'title': 'Show'},
            ],
          },
        ],
      });

      expect(migrated['schemaVersion'], 4);
      final place =
          (migrated['places']! as List).single as Map<String, Object?>;
      expect(place, containsPair('latitude', isA<double>()));
      expect(place, containsPair('longitude', isA<double>()));
      expect(place, isNot(contains('x')));
      expect(place, isNot(contains('y')));
      expect((place['events']! as List).single, containsPair('title', 'Show'));
    },
  );
}
