import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/account/account_session.dart';
import 'package:park_demo/main.dart';

Widget _testRootShell({Widget Function(bool active)? mapScreenBuilder}) {
  return MaterialApp(
    home: RootShell(
      session: const AccessSession(
        displayName: 'Familia',
        email: 'familia@example.com',
        provider: AccessProvider.local,
      ),
      onSignOut: () {},
      onDeleteLocalAccount: () {},
      mapScreenBuilder:
          mapScreenBuilder ?? (_) => const SizedBox(key: Key('test-map')),
    ),
  );
}

void main() {
  testWidgets('la navegación expone las cuatro áreas y la acción Runi', (
    tester,
  ) async {
    await tester.pumpWidget(_testRootShell());

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Paquetes'), findsOneWidget);
    expect(find.text('Comida'), findsOneWidget);
    expect(find.byKey(const Key('runi-nav-button')), findsOneWidget);
  });

  testWidgets('el botón de cuenta abre Cuenta y privacidad', (tester) async {
    await tester.pumpWidget(_testRootShell());

    await tester.tap(find.byKey(const Key('account-button')));
    await tester.pumpAndSettle();

    expect(find.text('Cuenta y privacidad'), findsOneWidget);
    expect(find.text('familia@example.com'), findsOneWidget);
  });

  testWidgets('el mapa se prepara antes del primer toque', (tester) async {
    final activations = <bool>[];
    await tester.pumpWidget(
      _testRootShell(
        mapScreenBuilder: (active) {
          activations.add(active);
          return const SizedBox(key: Key('prepared-map'));
        },
      ),
    );

    expect(activations, const [false]);
    expect(
      find.byKey(const Key('prepared-map'), skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Atracciones populares'), findsOneWidget);
  });

  testWidgets('el mapa activa la ubicación solamente al abrir la pestaña', (
    tester,
  ) async {
    final activations = <bool>[];
    await tester.pumpWidget(
      _testRootShell(
        mapScreenBuilder: (active) {
          activations.add(active);
          return const SizedBox();
        },
      ),
    );

    expect(activations, const [false]);

    await tester.tap(find.text('Mapa'));
    await tester.pump();

    expect(activations, const [false, true]);
  });

  testWidgets('las pestañas conservan la posición de Inicio al navegar', (
    tester,
  ) async {
    await tester.pumpWidget(_testRootShell());

    final popular = find.text('Atracciones populares');
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -360),
    );
    await tester.pumpAndSettle();
    final scrolledTop = tester.getTopLeft(popular).dy;

    await tester.tap(find.text('Paquetes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(popular).dy, closeTo(scrolledTop, 1));
  });
}
