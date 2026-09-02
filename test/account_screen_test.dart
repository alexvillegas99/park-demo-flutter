import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/account/account_screen.dart';
import 'package:park_demo/account/account_session.dart';

class _FakePrivacyService implements AccountPrivacyService {
  _FakePrivacyService({
    this.status = AccountLocationStatus.allowed,
    this.opensSettings = true,
  });

  final AccountLocationStatus status;
  final bool opensSettings;
  int settingsCalls = 0;

  @override
  Future<AccountLocationStatus> readLocationStatus() async => status;

  @override
  Future<bool> openSystemSettings() async {
    settingsCalls += 1;
    return opensSettings;
  }
}

const _localSession = AccessSession(
  displayName: 'Alex',
  email: 'alex@example.com',
  provider: AccessProvider.local,
);

Widget _accountApp({
  VoidCallback? onSignOut,
  VoidCallback? onDelete,
  AccountPrivacyService? service,
}) {
  return MaterialApp(
    home: AccountScreen(
      session: _localSession,
      onSignOut: onSignOut ?? () {},
      onDeleteLocalAccount: onDelete ?? () {},
      privacyService: service ?? _FakePrivacyService(),
    ),
  );
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    320,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Cuenta reúne identidad, permisos, documentos y acciones', (
    tester,
  ) async {
    await tester.pumpWidget(_accountApp());
    await tester.pumpAndSettle();

    expect(find.text('Cuenta y privacidad'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('alex@example.com'), findsOneWidget);
    expect(find.text('Ubicación permitida'), findsOneWidget);
    await _reveal(tester, find.byKey(const Key('privacy-policy-link')));
    expect(find.text('Política de privacidad'), findsOneWidget);
    expect(find.text('Términos de uso'), findsOneWidget);
    expect(find.text('Ayuda y soporte'), findsOneWidget);
    await _reveal(tester, find.byKey(const Key('sign-out-button')));
    expect(find.byKey(const Key('sign-out-button')), findsOneWidget);
    expect(find.byKey(const Key('delete-account-button')), findsOneWidget);
  });

  testWidgets('los documentos legales y la ayuda están disponibles sin red', (
    tester,
  ) async {
    await tester.pumpWidget(_accountApp());
    await tester.pumpAndSettle();

    await _reveal(tester, find.byKey(const Key('privacy-policy-link')));
    await tester.tap(find.byKey(const Key('privacy-policy-link')));
    await tester.pumpAndSettle();
    expect(find.text('Datos de esta versión'), findsOneWidget);
    await _reveal(tester, find.textContaining('no conserva un historial'));
    expect(find.textContaining('no conserva un historial'), findsOneWidget);
    await _reveal(tester, find.text('Conservación y eliminación'));
    expect(find.text('Conservación y eliminación'), findsOneWidget);
    await _reveal(tester, find.textContaining('Versión de demostración'));
    expect(find.textContaining('Versión de demostración'), findsOneWidget);
    expect(find.textContaining('complejomushucruna.ec'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('terms-link')));
    await tester.pumpAndSettle();
    expect(find.text('Alcance informativo'), findsOneWidget);
    expect(find.text('Ubicación aproximada'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('support-link')));
    await tester.pumpAndSettle();
    expect(find.text('Preguntas frecuentes'), findsOneWidget);
    await _reveal(
      tester,
      find.text('Contacto oficial pendiente de confirmación'),
    );
    expect(
      find.text('Contacto oficial pendiente de confirmación'),
      findsOneWidget,
    );
  });

  testWidgets('cancelar y confirmar cierre de sesión son acciones distintas', (
    tester,
  ) async {
    var signOuts = 0;
    await tester.pumpWidget(_accountApp(onSignOut: () => signOuts += 1));
    await tester.pumpAndSettle();

    await _reveal(tester, find.byKey(const Key('sign-out-button')));
    await tester.tap(find.byKey(const Key('sign-out-button')));
    await tester.pumpAndSettle();
    expect(find.text('¿Cerrar sesión?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(signOuts, 0);

    await tester.tap(find.byKey(const Key('sign-out-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-sign-out')));
    await tester.pump();
    expect(signOuts, 1);
  });

  testWidgets('eliminar cuenta local exige dos decisiones', (tester) async {
    var deletions = 0;
    await tester.pumpWidget(_accountApp(onDelete: () => deletions += 1));
    await tester.pumpAndSettle();

    await _reveal(tester, find.byKey(const Key('delete-account-button')));
    await tester.tap(find.byKey(const Key('delete-account-button')));
    await tester.pumpAndSettle();
    expect(find.text('Eliminar cuenta local'), findsWidgets);
    expect(find.textContaining('programación administrativa'), findsOneWidget);
    expect(deletions, 0);

    await tester.tap(find.byKey(const Key('continue-delete-account')));
    await tester.pumpAndSettle();
    expect(
      find.text('Esta acción elimina los datos locales de esta demostración'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(deletions, 0);

    await tester.tap(find.byKey(const Key('continue-delete-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-account')));
    await tester.pump();
    expect(deletions, 1);
  });

  testWidgets('Cuenta informa si no puede abrir los ajustes del sistema', (
    tester,
  ) async {
    final service = _FakePrivacyService(
      status: AccountLocationStatus.blocked,
      opensSettings: false,
    );
    await tester.pumpWidget(_accountApp(service: service));
    await tester.pumpAndSettle();

    expect(find.text('Ubicación bloqueada'), findsOneWidget);
    await tester.tap(find.byKey(const Key('location-settings')));
    await tester.pumpAndSettle();

    expect(service.settingsCalls, 1);
    expect(
      find.text('No pudimos abrir Ajustes en este dispositivo'),
      findsOneWidget,
    );
  });
}
