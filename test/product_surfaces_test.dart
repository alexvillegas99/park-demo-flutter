import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/account/account_session.dart';
import 'package:park_demo/main.dart';

Widget _testRootShell() {
  return MaterialApp(
    home: RootShell(
      session: const AccessSession(
        displayName: 'Familia',
        email: 'familia@example.com',
        provider: AccessProvider.local,
      ),
      onSignOut: () {},
      onDeleteLocalAccount: () {},
      mapScreenBuilder: (_) => const SizedBox(key: Key('test-map')),
    ),
  );
}

void main() {
  test(
    'el mapa móvil usa Google híbrido sin empaquetar el plano ilustrado',
    () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final source = File('lib/map/map_screen.dart').readAsStringSync();

      expect(pubspec, isNot(contains('assets/map/index.html')));
      expect(pubspec, isNot(contains('mushuc_runa_validated.svg')));
      expect(source, contains('MapType.hybrid'));
      expect(source, isNot(contains('WebViewWidget')));
      expect(
        source.toLowerCase(),
        isNot(contains('mapa vectorizado final accesos')),
      );
    },
  );

  testWidgets('Paquetes conserva la oferta completa fuera del menú principal', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PackagesScreen()));

    expect(find.text('Paquetes y entradas'), findsOneWidget);
    expect(find.text('Tuki Tuki'), findsOneWidget);
    expect(find.text('Tuki Punlla'), findsOneWidget);
    expect(find.text('All Day 2x1'), findsOneWidget);
    expect(find.textContaining('Tren'), findsNothing);
  });

  testWidgets('Comida conserva sabores y pedidos fuera del menú principal', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: FoodScreen()));

    expect(find.text('Sabores del complejo'), findsOneWidget);
    expect(find.text('Pedir'), findsWidgets);
    expect(find.textContaining('min'), findsWidgets);
  });

  testWidgets('Programación organiza los tres escenarios por día', (
    tester,
  ) async {
    await tester.pumpWidget(_testRootShell());

    await tester.tap(find.text('Programación'));
    await tester.pumpAndSettle();

    expect(find.text('Programación diaria'), findsOneWidget);
    expect(find.text('Plaza del Sol'), findsOneWidget);
    expect(find.text('Plaza de la Luna'), findsOneWidget);
    expect(find.text('Megaescenario'), findsOneWidget);
    expect(find.text('CONCIERTOS Y ARTISTAS INVITADOS'), findsOneWidget);
    expect(find.text('SHOWS DESDE LAS 18:00'), findsNothing);
    expect(find.text('Inauguración'), findsOneWidget);
    expect(find.text('Grupo Bodega'), findsOneWidget);

    await tester.tap(find.byKey(const Key('programming-day-2')));
    await tester.pumpAndSettle();

    expect(find.text('Show de Mickey Mouse'), findsOneWidget);
    expect(find.text('Mega Rumba'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('programming-venue-mega')),
        matching: find.text('Guaynaa'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('programming-venue-sol')),
        matching: find.text('Guaynaa'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('programming-venue-luna')),
        matching: find.text('Guaynaa'),
      ),
      findsNothing,
    );
  });

  testWidgets('Programación refleja cambios administrativos compartidos', (
    tester,
  ) async {
    final controller = ProgrammingController.defaults();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProgrammingScreen(controller: controller)),
      ),
    );

    expect(find.text('Inauguración'), findsOneWidget);
    expect(find.text('12:00'), findsOneWidget);

    final updated = controller
        .toJsonList()
        .map((day) => Map<String, dynamic>.from(day))
        .toList(growable: false);
    final firstDay = Map<String, dynamic>.from(updated.first);
    final sol = List<Map<String, dynamic>>.from(
      (firstDay['sol'] as List).map(
        (entry) => Map<String, dynamic>.from(entry as Map),
      ),
    );
    sol[0] = {'time': '12:30', 'title': 'Apertura actualizada'};
    firstDay['sol'] = sol;
    updated[0] = firstDay;

    expect(controller.replaceFromJson(updated), isTrue);
    await tester.pump();

    expect(find.text('Apertura actualizada'), findsOneWidget);
    expect(find.text('12:30'), findsOneWidget);
    expect(find.text('Inauguración'), findsNothing);
  });

  testWidgets('el botón central abre Runi', (tester) async {
    await tester.pumpWidget(_testRootShell());

    await tester.tap(find.byKey(const Key('runi-nav-button')));
    await tester.pumpAndSettle();

    expect(find.text('TU GUÍA INTELIGENTE'), findsOneWidget);
    expect(find.text('Paseo en Tren'), findsNothing);
    expect(find.text('PLAN BASADO EN'), findsOneWidget);
    expect(find.textContaining('Afluencia estimada'), findsOneWidget);
  });

  testWidgets('una recomendación de Runi abre la pestaña Mapa', (tester) async {
    await tester.pumpWidget(_testRootShell());
    await tester.tap(find.byKey(const Key('runi-nav-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('runi-step-0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('test-map')), findsOneWidget);
    expect(find.text('TU GUÍA INTELIGENTE'), findsNothing);
  });
}
