import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/main.dart';

void main() {
  testWidgets('Paquetes presenta la oferta aprobada', (tester) async {
    await tester.pumpWidget(const MushucRunaApp());

    await tester.tap(find.text('Paquetes'));
    await tester.pumpAndSettle();

    expect(find.text('Paquetes y entradas'), findsOneWidget);
    expect(find.text('Tuki Tuki'), findsOneWidget);
    expect(find.text(r'$25'), findsWidgets);
  });

  testWidgets('Comida presenta sabores, espera y pedido', (tester) async {
    await tester.pumpWidget(const MushucRunaApp());

    await tester.tap(find.text('Comida'));
    await tester.pumpAndSettle();

    expect(find.text('Sabores del complejo'), findsOneWidget);
    expect(find.text('Pedir'), findsWidgets);
    expect(find.textContaining('min'), findsWidgets);
  });

  testWidgets('el botón central abre Runi', (tester) async {
    await tester.pumpWidget(const MushucRunaApp());

    await tester.tap(find.byKey(const Key('runi-nav-button')));
    await tester.pumpAndSettle();

    expect(find.text('TU GUÍA INTELIGENTE'), findsOneWidget);
  });
}
