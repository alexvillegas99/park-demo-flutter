import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/account/account_session.dart';
import 'package:park_demo/main.dart';
import 'package:park_demo/map/map_document_controller.dart';
import 'package:park_demo/map/map_screen.dart';

MapDocumentController _document() {
  final controller = MapDocumentController();
  controller.acceptJson(
    jsonEncode(<String, Object?>{
      'schemaVersion': 4,
      'updatedAt': '2026-10-08T12:00:00Z',
      'places': <Object?>[
        for (final entry in <({String id, String name, String? venue})>[
          (id: '20', name: 'Mega Escenario', venue: 'mega'),
          (id: '28', name: 'Plaza de la Luna', venue: 'luna'),
          (id: '93', name: 'Plaza del Sol', venue: 'sol'),
        ])
          <String, Object?>{
            'id': entry.id,
            'cat': 'evento',
            'name': entry.name,
            'latitude': -1.369,
            'longitude': -78.648,
            'isVisible': true,
            'isFeatured': true,
            'needsReview': false,
            'venue': entry.venue,
            'events': <Object?>[],
          },
      ],
    }),
  );
  return controller;
}

Widget _screen({bool configured = true, String? initialPlaceId}) => MaterialApp(
  home: Scaffold(
    body: MapScreen(
      active: false,
      programming: ProgrammingController.defaults(),
      mapDocument: _document(),
      session: const AccessSession.guest(),
      initialPlaceId: initialPlaceId,
      mapsConfigured: configured,
      connectivityCheck: () async => true,
      mapBuilder: (context, model, onPlaceTap, onZoom) => SizedBox.expand(
        key: const Key('fake-map-canvas'),
        child: Padding(
          padding: const EdgeInsets.only(top: 160),
          child: Column(
            children: model.places
                .map(
                  (place) => TextButton(
                    key: Key('marker-${place.id}'),
                    onPressed: () => onPlaceTap(place.id),
                    child: Text(place.name),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('usa un lienzo nativo amplio y controles compactos', (
    tester,
  ) async {
    await tester.pumpWidget(_screen());
    await tester.pump();
    expect(find.byKey(const Key('fake-map-canvas')), findsOneWidget);
    expect(find.byKey(const Key('map-search-field')), findsOneWidget);
    expect(find.text('Ver todo'), findsOneWidget);
    expect(find.text('Mi ubicación'), findsOneWidget);
    expect(find.textContaining('plano ilustrado'), findsNothing);
  });

  testWidgets('seleccionar un escenario abre detalle con programación', (
    tester,
  ) async {
    await tester.pumpWidget(_screen());
    await tester.tap(find.byKey(const Key('marker-20')));
    await tester.pump();
    expect(find.byKey(const Key('map-place-sheet')), findsOneWidget);
    expect(find.text('Programación de hoy'), findsOneWidget);
    expect(find.textContaining('Grupo Bodega'), findsOneWidget);
  });

  testWidgets('sin clave muestra un estado recuperable y no monta el mapa', (
    tester,
  ) async {
    await tester.pumpWidget(_screen(configured: false));
    expect(find.textContaining('Falta configurar el mapa'), findsOneWidget);
    expect(find.byKey(const Key('fake-map-canvas')), findsNothing);
  });

  testWidgets('una recomendación abre el mismo punto del mapa', (tester) async {
    await tester.pumpWidget(_screen(initialPlaceId: '20'));
    await tester.pump();

    expect(find.byKey(const Key('map-place-sheet')), findsOneWidget);
    expect(find.text('Mega Escenario'), findsWidgets);
    expect(find.textContaining('Grupo Bodega'), findsOneWidget);
  });
}
