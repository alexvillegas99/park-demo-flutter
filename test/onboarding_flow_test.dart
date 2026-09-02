import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/main.dart';

Widget _testApp() {
  return MushucRunaApp(
    mapScreenBuilder: (_) => const SizedBox(key: Key('test-map')),
  );
}

void main() {
  testWidgets('el cuestionario llena la pantalla y deja la acción visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.tap(find.byKey(const Key('google-access')));
    await tester.pumpAndSettle();

    final sheet = find.byKey(const Key('onboarding-full-sheet'));
    final next = find.byKey(const Key('onboarding-next'));
    final shows = find.byKey(const Key('onboarding-option-Shows'));

    expect(sheet, findsOneWidget);
    expect(tester.getBottomRight(sheet).dy, greaterThanOrEqualTo(924));
    expect(tester.getBottomRight(next).dy, greaterThan(870));
    expect(tester.getSize(shows).height, greaterThanOrEqualTo(88));
  });

  testWidgets('la pregunta usa opciones táctiles amplias y una fila completa', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.tap(find.byKey(const Key('google-access')));
    await tester.pumpAndSettle();

    final shows = find.byKey(const Key('onboarding-option-Shows'));
    final all = find.byKey(const Key('onboarding-option-Todo'));

    expect(tester.getSize(shows).height, greaterThanOrEqualTo(78));
    expect(
      tester.getSize(all).width,
      greaterThan(tester.getSize(shows).width * 1.8),
    );
  });

  testWidgets('Google visual recorre las tres preguntas y entra a Inicio', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());

    await tester.tap(find.byKey(const Key('google-access')));
    await tester.pumpAndSettle();

    expect(find.text('¿Qué te trae a Mushuc Runa?'), findsOneWidget);
    expect(find.text('1 de 3'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('onboarding-next')))
          .onPressed,
      isNull,
    );

    await tester.ensureVisible(find.byKey(const Key('onboarding-option-Todo')));
    await tester.tap(find.byKey(const Key('onboarding-option-Todo')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();

    expect(find.text('¿Cuántas veces nos has visitado?'), findsOneWidget);
    expect(find.text('2 de 3'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('onboarding-option-Primera vez')),
    );
    await tester.tap(find.byKey(const Key('onboarding-option-Primera vez')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();

    expect(
      find.text('¿Qué te haría recomendar nuestra experiencia?'),
      findsOneWidget,
    );
    expect(find.text('3 de 3'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('onboarding-option-Diversión familiar')),
    );
    await tester.tap(
      find.byKey(const Key('onboarding-option-Diversión familiar')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('onboarding-finish')));
    await tester.pumpAndSettle();

    expect(find.text('¡Hola, Visitante!'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Paquetes'), findsOneWidget);
  });

  testWidgets('el cuestionario permite volver sin perder la respuesta', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.tap(find.byKey(const Key('google-access')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('onboarding-option-Conciertos')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-back')));
    await tester.pumpAndSettle();

    expect(find.text('¿Qué te trae a Mushuc Runa?'), findsOneWidget);
    final concerts = tester.widget<Semantics>(
      find.byKey(const Key('onboarding-option-Conciertos')),
    );
    expect(concerts.properties.selected, isTrue);
  });
}
