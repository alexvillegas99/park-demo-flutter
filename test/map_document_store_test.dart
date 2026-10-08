import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/map/map_document_controller.dart';
import 'package:park_demo/map/map_document_store.dart';

String _json(String updatedAt, {String name = 'Mega Escenario'}) =>
    jsonEncode(<String, Object?>{
      'schemaVersion': 4,
      'updatedAt': updatedAt,
      'places': <Object?>[
        <String, Object?>{
          'id': '20',
          'cat': 'evento',
          'name': name,
          'latitude': -1.369,
          'longitude': -78.648,
          'isVisible': true,
          'isFeatured': true,
          'needsReview': false,
          'events': <Object?>[],
        },
      ],
    });

class _MemoryStore implements MapDocumentStore {
  String? current;
  String? backup;

  @override
  Future<String?> readCurrent() async => current;

  @override
  Future<String?> readBackup() async => backup;

  @override
  Future<void> writeValidated(String currentJson, String? previousJson) async {
    MapDocumentSnapshot.fromJson(jsonDecode(currentJson));
    if (previousJson != null) backup = previousJson;
    current = currentJson;
  }

  @override
  Future<String?> restoreBackup() async {
    if (backup != null) current = backup;
    return backup;
  }
}

void main() {
  test('inicializa con la semilla cuando no existe documento local', () async {
    final controller = MapDocumentController();
    final store = _MemoryStore();
    await controller.initialize(
      () async => _json('2026-10-08T12:00:00Z'),
      store,
    );
    expect(controller.snapshot!.places.single.name, 'Mega Escenario');
  });

  test('prefiere el documento local más reciente', () async {
    final controller = MapDocumentController();
    final store = _MemoryStore()
      ..current = _json('2026-10-08T13:00:00Z', name: 'Local');
    await controller.initialize(
      () async => _json('2026-10-08T12:00:00Z', name: 'Semilla'),
      store,
    );
    expect(controller.snapshot!.places.single.name, 'Local');
  });

  test('un documento local corrupto vuelve a la semilla', () async {
    final controller = MapDocumentController();
    final store = _MemoryStore()..current = '{dañado';
    await controller.initialize(
      () async => _json('2026-10-08T12:00:00Z', name: 'Semilla segura'),
      store,
    );
    expect(controller.snapshot!.places.single.name, 'Semilla segura');
  });

  test(
    'guardar conserva respaldo y restaurarlo recupera la versión previa',
    () async {
      final controller = MapDocumentController();
      final store = _MemoryStore();
      await controller.initialize(
        () async => _json('2026-10-08T12:00:00Z', name: 'Anterior'),
        store,
      );
      final next = MapDocumentSnapshot.fromJson(
        jsonDecode(_json('2026-10-08T13:00:00Z', name: 'Nueva')),
      );
      await controller.replace(next, persist: true);
      expect(jsonDecode(store.backup!)['places'][0]['name'], 'Anterior');
      expect(controller.snapshot!.places.single.name, 'Nueva');

      expect(await controller.restoreBackup(), isTrue);
      expect(controller.snapshot!.places.single.name, 'Anterior');
    },
  );
}
