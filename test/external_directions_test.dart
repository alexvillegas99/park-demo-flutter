import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/map/external_directions_screen.dart';

void main() {
  test('construye una URL HTTPS peatonal y codificada', () {
    final uri = ExternalDirectionsUri.googleWalking(
      destinationLat: -1.3690877,
      destinationLng: -78.6477924,
    );

    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.queryParameters['api'], '1');
    expect(uri.queryParameters['destination'], '-1.3690877,-78.6477924');
    expect(uri.queryParameters['travelmode'], 'walking');
  });

  test('solo permite navegación web segura de Google Maps', () {
    expect(
      ExternalDirectionsUri.isAllowed(
        Uri.parse('https://www.google.com/maps/dir/?api=1'),
      ),
      isTrue,
    );
    expect(
      ExternalDirectionsUri.isAllowed(
        Uri.parse('https://maps.google.com/maps?q=Mushuc'),
      ),
      isTrue,
    );
    for (final value in <String>[
      'comgooglemaps://?q=Mushuc',
      'intent://maps.google.com/#Intent;scheme=https;end',
      'maps://?q=Mushuc',
      'https://example.com/maps',
    ]) {
      expect(ExternalDirectionsUri.isAllowed(Uri.parse(value)), isFalse);
    }
  });

  testWidgets('el error conserva orientación y no abre fuera automáticamente', (
    tester,
  ) async {
    var externalOpens = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ExternalDirectionsScreen(
          destinationLat: -1.369,
          destinationLng: -78.648,
          destinationName: 'Acceso 1',
          webViewOverride: const ColoredBox(color: Colors.white),
          initialErrorMessage: 'Sin conexión disponible',
          onOpenExternal: (_) async {
            externalOpens += 1;
            return true;
          },
        ),
      ),
    );

    expect(find.text('Cómo llegar a Acceso 1'), findsOneWidget);
    expect(find.text('Sin conexión disponible'), findsOneWidget);
    expect(find.text('Abrir en navegador'), findsOneWidget);
    expect(externalOpens, 0);

    await tester.tap(find.text('Abrir en navegador'));
    await tester.pump();
    expect(externalOpens, 1);
  });
}
