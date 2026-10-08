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
    expect(find.text('Atracciones'), findsOneWidget);
    expect(find.text('De recorrido'), findsOneWidget);
  });

  testWidgets('Atracciones populares usa las tres fotografías locales', (
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
        'assets/attractions/granja-interactiva.png',
      }),
    );
    expect(assetNames, isNot(contains('assets/attractions/paseo-tren.png')));
    expect(find.text('Granja interactiva'), findsOneWidget);
  });

  testWidgets('Inicio destaca el bosque gratuito y retira el tren', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeScreen(displayName: 'Familia')),
      ),
    );

    expect(find.text('Bosque de Dinosaurios'), findsOneWidget);
    expect(find.text('Gratuito'), findsOneWidget);
    expect(find.text('Paseo en Tren'), findsNothing);
  });

  testWidgets('Inicio retira por completo la promoción All Day', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeScreen(displayName: 'Familia')),
      ),
    );

    expect(find.text('SOLO SÁBADOS'), findsNothing);
    expect(find.textContaining('2x1 en el paquete'), findsNothing);
    expect(find.text('Ver paquetes'), findsNothing);
  });

  testWidgets('Inicio muestra el banner de premios debajo de los indicadores', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeScreen(displayName: 'Familia')),
      ),
    );

    final banner = find.byKey(const Key('home-prize-banner'));
    expect(banner, findsOneWidget);
    expect(find.text('09–18h'), findsNothing);
    expect(find.text('Abierto hoy'), findsNothing);
    expect(find.text('12 km'), findsOneWidget);
    expect(find.text('De recorrido'), findsOneWidget);
    expect(
      find.textContaining('Promoción sujeta a términos y restricciones'),
      findsOneWidget,
    );

    final bannerImage = tester.widget<Image>(
      find.descendant(of: banner, matching: find.byType(Image)),
    );
    expect(
      (bannerImage.image as AssetImage).assetName,
      'assets/attractions/premios-finados-2026.png',
    );
    expect(
      tester.getTopLeft(banner).dy,
      greaterThan(tester.getBottomLeft(find.text('Atracciones')).dy),
    );
  });
}
