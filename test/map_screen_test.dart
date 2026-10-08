import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/account/account_session.dart';
import 'package:park_demo/main.dart';
import 'package:park_demo/map/map_document_controller.dart';
import 'package:park_demo/map/map_screen.dart';
import 'package:park_demo/map/widgets/map_place_sheet.dart';

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

const _lunaProgrammingDays = <MapVenueProgrammingDay>[
  MapVenueProgrammingDay(
    weekday: 'SÁB',
    day: '31',
    month: 'OCT',
    fullDate: 'Sábado 31 de octubre',
    events: [
      {'time': '12:00', 'title': 'Mega Rumba'},
    ],
  ),
  MapVenueProgrammingDay(
    weekday: 'DOM',
    day: '01',
    month: 'NOV',
    fullDate: 'Domingo 1 de noviembre',
    events: [
      {'time': '14:00', 'title': 'Milton Araujo'},
    ],
  ),
  MapVenueProgrammingDay(
    weekday: 'LUN',
    day: '02',
    month: 'NOV',
    fullDate: 'Lunes 2 de noviembre',
    events: [
      {'time': '17:00', 'title': 'Jaime E. Aymara'},
    ],
  ),
];

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
    expect(find.text('Programación por día'), findsOneWidget);
    expect(find.textContaining('Grupo Bodega'), findsOneWidget);
  });

  testWidgets('un escenario permite revisar su programación por día', (
    tester,
  ) async {
    await tester.pumpWidget(_screen());
    await tester.tap(find.byKey(const Key('marker-28')));
    await tester.pump();

    expect(find.byKey(const Key('map-venue-day-0')), findsOneWidget);
    expect(find.byKey(const Key('map-venue-day-2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('map-venue-day-2')));
    await tester.pumpAndSettle();

    expect(find.text('Domingo 1 de noviembre'), findsOneWidget);
    expect(find.textContaining('Milton Araujo'), findsOneWidget);
    expect(find.textContaining('Las Ñañas'), findsOneWidget);
  });

  testWidgets('la ficha abre automáticamente la programación del día actual', (
    tester,
  ) async {
    final place = _document().snapshot!.places.firstWhere(
      (candidate) => candidate.id == '28',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapPlaceSheet(
            place: place,
            programmingDays: _lunaProgrammingDays,
            today: DateTime(2026, 11, 1),
            onClose: () {},
            onNavigate: () {},
          ),
        ),
      ),
    );

    expect(find.text('Domingo 1 de noviembre'), findsOneWidget);
    expect(find.textContaining('Milton Araujo'), findsOneWidget);
    expect(find.textContaining('Mega Rumba'), findsNothing);
  });

  testWidgets('fuera del rango abre el próximo día o el último disponible', (
    tester,
  ) async {
    final place = _document().snapshot!.places.firstWhere(
      (candidate) => candidate.id == '28',
    );

    Future<void> showFor(DateTime today) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapPlaceSheet(
            place: place,
            programmingDays: _lunaProgrammingDays,
            today: today,
            onClose: () {},
            onNavigate: () {},
          ),
        ),
      ),
    );

    await showFor(DateTime(2026, 10, 20));
    expect(find.text('Sábado 31 de octubre'), findsOneWidget);
    expect(find.textContaining('Mega Rumba'), findsOneWidget);

    await showFor(DateTime(2026, 11, 5));
    expect(find.text('Lunes 2 de noviembre'), findsOneWidget);
    expect(find.textContaining('Jaime E. Aymara'), findsOneWidget);
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
