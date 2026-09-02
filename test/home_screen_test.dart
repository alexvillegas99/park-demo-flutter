import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/main.dart';

void main() {
  testWidgets('Inicio presenta la experiencia familiar del rediseño', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeScreen(displayName: 'Familia')),
      ),
    );

    expect(find.text('¡Hola, Familia!'), findsOneWidget);
    expect(find.text('Atracciones populares'), findsOneWidget);
    expect(find.textContaining('2x1 en el paquete'), findsOneWidget);
    expect(find.text('Ver paquetes'), findsOneWidget);
  });

  testWidgets('Atracciones populares usa las cuatro fotografías locales', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeScreen(displayName: 'Familia')),
      ),
    );

    final assetNames = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => image.image)
        .whereType<AssetImage>()
        .map((asset) => asset.assetName)
        .toSet();

    expect(
      assetNames,
      containsAll(<String>{
        'assets/attractions/resbaladera-gigante.png',
        'assets/attractions/bosque-dinosaurios.png',
        'assets/attractions/paseo-tren.png',
        'assets/attractions/granja-interactiva.png',
      }),
    );
    expect(find.text('Granja interactiva'), findsOneWidget);
  });
}
