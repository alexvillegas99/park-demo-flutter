import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/account/account_session.dart';
import 'package:park_demo/main.dart';
import 'package:park_demo/map/map_document_controller.dart';
import 'package:park_demo/map/map_document_store.dart';
import 'package:park_demo/map/map_screen.dart';

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

MapDocumentController _document() {
  final controller = MapDocumentController();
  controller.acceptJson(_seed());
  return controller;
}

class _MemoryStore implements MapDocumentStore {
  String? current;
  String? backup;

  @override
  Future<String?> readCurrent() async => current;

  @override
  Future<String?> readBackup() async => backup;

  @override
  Future<String?> restoreBackup() async => backup;

  @override
  Future<void> writeValidated(String currentJson, String? previousJson) async {
    backup = previousJson;
    current = currentJson;
  }
}

Widget _screen(AccessSession session, {MapDocumentController? document}) =>
    MaterialApp(
      home: Scaffold(
        body: MapScreen(
          active: false,
          programming: ProgrammingController.defaults(),
          mapDocument: document ?? _document(),
          session: session,
          mapsConfigured: true,
          connectivityCheck: () async => true,
          mapBuilder: (_, __, ___, ____) =>
              const ColoredBox(color: Colors.green),
        ),
      ),
    );

void main() {
  testWidgets('un visitante no ve controles administrativos', (tester) async {
    await tester.pumpWidget(_screen(const AccessSession.guest()));
    expect(find.byKey(const Key('map-admin-button')), findsNothing);
  });

  testWidgets('un administrador abre el panel del mismo mapa', (tester) async {
    await tester.pumpWidget(
      _screen(
        const AccessSession(
          displayName: 'Admin',
          email: 'admin@mushucruna.demo',
          provider: AccessProvider.local,
          role: AccessRole.admin,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('map-admin-button')));
    await tester.pumpAndSettle();
    expect(find.text('Administrar mapa'), findsOneWidget);
    expect(find.text('Mover puntos'), findsOneWidget);
    expect(find.text('Agregar punto'), findsOneWidget);
  });

  testWidgets('el inspector administrativo edita datos y eventos', (
    tester,
  ) async {
    final document = MapDocumentController();
    await document.initialize(() async => _seed(), _MemoryStore());
    await tester.pumpWidget(
      _screen(
        const AccessSession(
          displayName: 'Admin',
          email: 'admin@mushucruna.demo',
          provider: AccessProvider.local,
          role: AccessRole.admin,
        ),
        document: document,
      ),
    );
    await tester.tap(find.byKey(const Key('map-admin-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-edit-20')));
    await tester.pumpAndSettle();

    expect(find.text('Editar punto'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('admin-place-name')),
      'Megaescenario principal',
    );
    await tester.tap(find.byKey(const Key('admin-add-event')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('admin-event-time-0')),
      '18:30',
    );
    await tester.enterText(
      find.byKey(const Key('admin-event-title-0')),
      'Concierto principal',
    );
    await tester.tap(find.byKey(const Key('admin-save-place')));
    await tester.pumpAndSettle();

    final place = document.snapshot!.places.single;
    expect(place.name, 'Megaescenario principal');
    expect(place.events.single, <String, Object?>{
      'time': '18:30',
      'title': 'Concierto principal',
    });
  });
}
