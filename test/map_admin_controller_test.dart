import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/account/account_session.dart';
import 'package:park_demo/map/map_admin_controller.dart';
import 'package:park_demo/map/map_document_controller.dart';
import 'package:park_demo/map/map_document_store.dart';
import 'package:park_demo/map/map_geo.dart';

class _Store implements MapDocumentStore {
  String? current;
  String? backup;
  @override
  Future<String?> readCurrent() async => current;
  @override
  Future<String?> readBackup() async => backup;
  @override
  Future<void> writeValidated(String currentJson, String? previousJson) async {
    backup = previousJson;
    current = currentJson;
  }

  @override
  Future<String?> restoreBackup() async {
    current = backup;
    return backup;
  }
}

String _seed() => jsonEncode(<String, Object?>{
  'schemaVersion': 4,
  'updatedAt': '2026-10-08T12:00:00Z',
  'places': <Object?>[
    <String, Object?>{
      'id': '20',
      'cat': 'evento',
      'name': 'Mega Escenario',
      'latitude': -1.369,
      'longitude': -78.648,
      'isVisible': true,
      'isFeatured': true,
      'needsReview': false,
      'events': <Object?>[],
    },
  ],
});

void main() {
  const admin = AccessSession(
    displayName: 'Admin',
    email: 'admin@mushucruna.demo',
    provider: AccessProvider.local,
    role: AccessRole.admin,
  );
  const visitor = AccessSession(
    displayName: 'Visitante',
    email: 'persona@example.com',
    provider: AccessProvider.local,
  );

  test('solo el rol administrador puede mutar el mapa', () async {
    final document = MapDocumentController();
    await document.initialize(() async => _seed(), _Store());
    final controller = MapAdminController(session: visitor, document: document);
    expect(
      () => controller.createPlace(
        name: 'Nuevo punto',
        category: 'servicio',
        point: GeoPoint(latitude: -1.3691, longitude: -78.6481),
      ),
      throwsStateError,
    );
  });

  test('crea, mueve, oculta y edita eventos con respaldo', () async {
    final store = _Store();
    final document = MapDocumentController();
    await document.initialize(() async => _seed(), store);
    final controller = MapAdminController(
      session: admin,
      document: document,
      now: () => DateTime.utc(2026, 10, 8, 13),
    );

    final id = await controller.createPlace(
      name: 'Punto de información',
      category: 'servicio',
      point: GeoPoint(latitude: -1.3691, longitude: -78.6481),
    );
    expect(document.snapshot!.places.any((place) => place.id == id), isTrue);
    await controller.movePlace(
      id,
      GeoPoint(latitude: -1.3692, longitude: -78.6482),
    );
    expect(
      document.snapshot!.places.firstWhere((place) => place.id == id).latitude,
      -1.3692,
    );
    await controller.updateEvents('20', <Map<String, Object?>>[
      <String, Object?>{'time': '18:00', 'title': 'Show actualizado'},
    ]);
    expect(
      document.snapshot!.places.first.events.single['title'],
      'Show actualizado',
    );
    await controller.hidePlace(id);
    expect(
      document.snapshot!.places.firstWhere((place) => place.id == id).isVisible,
      isFalse,
    );
    expect(store.backup, isNotNull);
  });
}
