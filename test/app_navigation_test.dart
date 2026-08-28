import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/main.dart';

void main() {
  testWidgets('la navegación expone las cuatro áreas y la acción Runi', (
    tester,
  ) async {
    await tester.pumpWidget(const MushucRunaApp());

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Paquetes'), findsOneWidget);
    expect(find.text('Comida'), findsOneWidget);
    expect(find.byKey(const Key('runi-nav-button')), findsOneWidget);
  });

  testWidgets('las pestañas conservan la posición de Inicio al navegar', (
    tester,
  ) async {
    await tester.pumpWidget(const MushucRunaApp());

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
