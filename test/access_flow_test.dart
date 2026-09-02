import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/account/account_screen.dart';
import 'package:park_demo/account/account_session.dart';
import 'package:park_demo/main.dart';

Widget _testApp() {
  return MushucRunaApp(
    mapScreenBuilder: (_) => const SizedBox(key: Key('test-map')),
  );
}

Future<void> _revealInAccount(WidgetTester tester, Finder finder) async {
  final accountScroll = find.descendant(
    of: find.byType(AccountScreen),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(finder, 340, scrollable: accountScroll.first);
  await tester.pumpAndSettle();
}

void main() {
  test('la sesión invitada no contiene identidad personal', () {
    const session = AccessSession.guest();

    expect(session.displayName, 'Visitante');
    expect(session.email, isEmpty);
    expect(session.isGuest, isTrue);
  });

  testWidgets('login y registro llenan la pantalla hasta el borde inferior', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    final loginSheet = find.byKey(const Key('login-full-sheet'));
    expect(loginSheet, findsOneWidget);
    expect(tester.getBottomRight(loginSheet).dy, greaterThanOrEqualTo(924));

    await tester.ensureVisible(find.byKey(const Key('create-account')));
    await tester.tap(find.byKey(const Key('create-account')));
    await tester.pumpAndSettle();

    final registerSheet = find.byKey(const Key('register-full-sheet'));
    expect(registerSheet, findsOneWidget);
    expect(tester.getBottomRight(registerSheet).dy, greaterThanOrEqualTo(924));
  });

  testWidgets('el acceso no desborda en el ancho de un iPhone', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('el acceso aprovecha el espacio inferior para orientar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    final supportPanel = find.byKey(const Key('login-support-panel'));
    expect(supportPanel, findsOneWidget);
    expect(tester.getSize(supportPanel).height, greaterThanOrEqualTo(72));
    expect(find.text('Todo listo para explorar'), findsOneWidget);
    expect(
      find.text('Mapa, shows y atracciones en un solo lugar'),
      findsOneWidget,
    );
  });

  testWidgets('la app inicia en un acceso agradable y no en Inicio', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());

    expect(find.text('Tu aventura comienza aquí'), findsOneWidget);
    expect(find.byKey(const Key('google-access')), findsOneWidget);
    expect(find.byKey(const Key('login-email')), findsOneWidget);
    expect(find.byKey(const Key('login-password')), findsOneWidget);
    expect(find.byKey(const Key('create-account')), findsOneWidget);
    expect(find.byKey(const Key('guest-access')), findsOneWidget);
    expect(find.text('Atracciones populares'), findsNothing);
  });

  testWidgets('el visitante entra sin entregar datos personales', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());

    await tester.ensureVisible(find.byKey(const Key('guest-access')));
    await tester.tap(find.byKey(const Key('guest-access')));
    await tester.pumpAndSettle();

    expect(find.text('¡Hola, Visitante!'), findsOneWidget);
    expect(find.text('Atracciones populares'), findsOneWidget);
  });

  testWidgets('cerrar sesión limpia el acceso y confirma el resultado', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.ensureVisible(find.byKey(const Key('guest-access')));
    await tester.tap(find.byKey(const Key('guest-access')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-button')));
    await tester.pumpAndSettle();

    await _revealInAccount(tester, find.byKey(const Key('sign-out-button')));
    await tester.tap(find.byKey(const Key('sign-out-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-sign-out')));
    await tester.pumpAndSettle();

    expect(find.text('Tu aventura comienza aquí'), findsOneWidget);
    expect(find.text('Sesión cerrada correctamente'), findsOneWidget);
  });

  testWidgets('eliminar la cuenta local vuelve al acceso con confirmación', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.ensureVisible(find.byKey(const Key('guest-access')));
    await tester.tap(find.byKey(const Key('guest-access')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('account-button')));
    await tester.pumpAndSettle();

    await _revealInAccount(
      tester,
      find.byKey(const Key('delete-account-button')),
    );
    await tester.tap(find.byKey(const Key('delete-account-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('continue-delete-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-account')));
    await tester.pumpAndSettle();

    expect(find.text('Tu aventura comienza aquí'), findsOneWidget);
    expect(find.text('Cuenta y datos locales eliminados'), findsOneWidget);
  });

  testWidgets('el acceso local valida los datos y abre un saludo derivado', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());

    await tester.ensureVisible(find.byKey(const Key('login-submit')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    expect(find.text('Escribe un correo válido'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'alex@example.com',
    );
    await tester.enterText(find.byKey(const Key('login-password')), 'secreto');
    await tester.ensureVisible(find.byKey(const Key('login-submit')));
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('¡Hola, Alex!'), findsOneWidget);
    expect(find.text('Atracciones populares'), findsOneWidget);
  });

  testWidgets('crear cuenta valida el formulario antes del cuestionario', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());

    await tester.ensureVisible(find.byKey(const Key('create-account')));
    await tester.tap(find.byKey(const Key('create-account')));
    await tester.pumpAndSettle();
    expect(find.text('Crea tu cuenta'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('register-name')),
      'Alex Naranjo',
    );
    await tester.enterText(
      find.byKey(const Key('register-email')),
      'alex@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register-password')),
      'secreto',
    );
    await tester.enterText(
      find.byKey(const Key('register-confirm')),
      'diferente',
    );
    await tester.ensureVisible(find.byKey(const Key('register-submit')));
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pump();
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('register-confirm')),
      'secreto',
    );
    await tester.ensureVisible(find.byKey(const Key('register-submit')));
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pumpAndSettle();

    expect(find.text('¿Qué te trae a Mushuc Runa?'), findsOneWidget);
    expect(find.text('1 de 3'), findsOneWidget);
  });
}
