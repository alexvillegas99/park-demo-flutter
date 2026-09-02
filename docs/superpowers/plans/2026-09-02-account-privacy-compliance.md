# Account Privacy Compliance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Añadir a la app Flutter existente una experiencia frontend de cuenta, privacidad, soporte y eliminación local que funcione offline y pueda conectarse después a un backend real.

**Architecture:** `AccessGate` mantiene una `AccessSession` en memoria y expone callbacks explícitos para cerrar o eliminar la sesión local. `RootShell` abre una página `AccountScreen` desde el encabezado; esa página contiene permisos, documentos offline, ayuda y acciones sensibles. Un servicio pequeño inyectable traduce el permiso de ubicación de `geolocator` a estados de interfaz sin pedir permiso desde Cuenta.

**Tech Stack:** Flutter/Dart, Material 3, `geolocator`, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-09-02-account-privacy-compliance-design.md`

## Global Constraints

- Modificar únicamente `/Users/afnaranjo/traiding/park-demo-flutter`; no crear otra copia.
- `Sign in with Apple` queda fuera de esta versión.
- El acceso Google continúa como demostración visual y no guarda tokens.
- No crear backend, autenticación productiva ni páginas web públicas.
- No enlazar `complejomushucruna.ec` ni inventar datos de contacto.
- La eliminación local no modifica el documento administrativo del mapa.
- Conservar los colores y tipografía de `AppTheme`.
- Alex autorizó después commit y push del resultado verificado. No realizar
  despliegue remoto ni crear una segunda copia del proyecto.
- Preservar todos los cambios locales existentes.

---

### Task 1: Modelo de sesión y acceso como visitante

**Files:**
- Create: `lib/account/account_session.dart`
- Modify: `lib/auth/access_flow.dart`
- Modify: `test/access_flow_test.dart`

**Interfaces:**
- Produces: `enum AccessProvider { guest, local, googleDemo }`.
- Produces: `AccessSession(displayName, email, provider)`, getter `isGuest`.
- Changes: `AccessGate.appBuilder` recibe `(AccessSession session, VoidCallback onSignOut, VoidCallback onDeleteLocalAccount)`.

- [ ] **Step 1: Escribir pruebas fallidas del acceso invitado y modelo**

Añadir a `test/access_flow_test.dart` pruebas que construyan la app, pulsen
`guest-access` y verifiquen `¡Hola, Visitante!`; también comprobar que el modelo
invitado no contiene correo y que `isGuest` es verdadero.

```dart
test('la sesión invitada no contiene identidad personal', () {
  const session = AccessSession.guest();
  expect(session.displayName, 'Visitante');
  expect(session.email, isEmpty);
  expect(session.isGuest, isTrue);
});
```

- [ ] **Step 2: Ejecutar la prueba y confirmar el fallo correcto**

Run: `flutter test test/access_flow_test.dart`
Expected: FAIL porque `AccessSession` y `guest-access` no existen.

- [ ] **Step 3: Implementar el modelo y el acceso invitado mínimo**

Crear el modelo inmutable:

```dart
enum AccessProvider { guest, local, googleDemo }

class AccessSession {
  const AccessSession({
    required this.displayName,
    required this.email,
    required this.provider,
  });

  const AccessSession.guest()
      : displayName = 'Visitante',
        email = '',
        provider = AccessProvider.guest;

  final String displayName;
  final String email;
  final AccessProvider provider;
  bool get isGuest => provider == AccessProvider.guest;
}
```

Actualizar `AccessGate` para crear sesiones `local`, `googleDemo` o `guest`, y
añadir el botón secundario `Continuar como visitante` con key `guest-access`.

- [ ] **Step 4: Implementar limpieza local de sesión**

Añadir `_clearSession({required bool deleted})`, limpiar los seis controladores y
las tres respuestas, volver a `AccessStage.login` y mostrar uno de estos avisos:
`Sesión cerrada correctamente` o `Cuenta y datos locales eliminados`.

- [ ] **Step 5: Ejecutar las pruebas del acceso**

Run: `flutter test test/access_flow_test.dart`
Expected: PASS.

### Task 2: Pantalla Cuenta y estado de ubicación

**Files:**
- Create: `lib/account/account_screen.dart`
- Create: `test/account_screen_test.dart`
- Modify: `lib/main.dart`
- Modify: `test/app_navigation_test.dart`
- Modify: `test/home_screen_test.dart`
- Modify: `test/product_surfaces_test.dart`

**Interfaces:**
- Produces: `enum AccountLocationStatus { notRequested, allowed, limited, blocked }`.
- Produces: `abstract interface class AccountPrivacyService` con
  `Future<AccountLocationStatus> readLocationStatus()` y
  `Future<bool> openSystemSettings()`.
- Produces: `GeolocatorAccountPrivacyService` como implementación predeterminada.
- Produces: `AccountScreen(session, onSignOut, onDeleteLocalAccount, privacyService)`.

- [ ] **Step 1: Escribir pruebas fallidas de navegación y permisos**

En `test/account_screen_test.dart`, crear un servicio falso determinista y
verificar que `AccountScreen` muestra identidad, `Ubicación permitida`,
`Política de privacidad`, `Términos de uso`, `Ayuda y soporte`, `Cerrar sesión`
y `Eliminar cuenta local`.

En `test/app_navigation_test.dart`, verificar que `account-button` abre la página
`Cuenta y privacidad`.

- [ ] **Step 2: Ejecutar las pruebas y confirmar el fallo correcto**

Run: `flutter test test/account_screen_test.dart test/app_navigation_test.dart`
Expected: FAIL porque la pantalla y el botón no existen.

- [ ] **Step 3: Implementar servicio de permisos**

Mapear `LocationPermission` así:

```dart
switch (permission) {
  case LocationPermission.always:
    return AccountLocationStatus.allowed;
  case LocationPermission.whileInUse:
    return AccountLocationStatus.limited;
  case LocationPermission.deniedForever:
    return AccountLocationStatus.blocked;
  case LocationPermission.denied:
  case LocationPermission.unableToDetermine:
    return AccountLocationStatus.notRequested;
}
```

`openSystemSettings()` delega en `Geolocator.openAppSettings()`.

- [ ] **Step 4: Construir `AccountScreen` con jerarquía editorial**

Usar `CustomScrollView`, encabezado vino, una tarjeta de identidad, títulos de
sección y filas separadas por divisores. Las acciones usan keys:
`privacy-policy-link`, `terms-link`, `support-link`, `location-settings`,
`sign-out-button` y `delete-account-button`.

Si el estado de ubicación está bloqueado o limitado, mostrar `Abrir ajustes`.
Si la apertura falla, mostrar `No pudimos abrir Ajustes en este dispositivo`.

- [ ] **Step 5: Integrar botón de cuenta y callbacks en `RootShell`**

Cambiar `_MrHeader` para recibir `onAccount`, añadir un botón circular con key
`account-button`, y hacer que `RootShell` reciba `AccessSession`, `onSignOut` y
`onDeleteLocalAccount`. `_openAccount()` usa `Navigator.push` y cierra las rutas
antes de ejecutar un callback de sesión.

- [ ] **Step 6: Actualizar constructores de prueba y ejecutar**

Run: `flutter test test/account_screen_test.dart test/app_navigation_test.dart test/home_screen_test.dart test/product_surfaces_test.dart`
Expected: PASS.

### Task 3: Documentos offline y soporte honesto

**Files:**
- Modify: `lib/account/account_screen.dart`
- Modify: `test/account_screen_test.dart`

**Interfaces:**
- Produces: `PrivacyPolicyScreen`, `TermsOfUseScreen`, `SupportScreen`.
- Produces: constante visible `Versión de demostración · 2 de septiembre de 2026`.

- [ ] **Step 1: Escribir pruebas fallidas de contenido legal y soporte**

Verificar que cada fila abre una página completa y que aparecen textos sobre
datos en memoria, uso de ubicación, transferencia a mapas externos, ausencia de
backend y contacto oficial pendiente. Confirmar que no existe ninguna URL con
`complejomushucruna.ec`.

- [ ] **Step 2: Ejecutar la prueba y confirmar el fallo correcto**

Run: `flutter test test/account_screen_test.dart`
Expected: FAIL porque las páginas todavía no existen.

- [ ] **Step 3: Implementar política de privacidad offline**

Crear una página con las secciones `Datos de esta versión`, `Ubicación`,
`Servicios externos`, `Conservación y eliminación` y `Cambios futuros`, usando
únicamente el comportamiento real descrito en la especificación.

- [ ] **Step 4: Implementar términos y ayuda offline**

Términos: alcance informativo, horarios sujetos a cambios, ubicación aproximada,
ausencia de compras y propiedad de contenido. Soporte: preguntas frecuentes de
acceso, mapa, ubicación y eliminación, más la advertencia visible de que el
contacto oficial debe confirmarse antes del lanzamiento.

- [ ] **Step 5: Ejecutar la prueba de documentos**

Run: `flutter test test/account_screen_test.dart`
Expected: PASS.

### Task 4: Confirmaciones de cierre y eliminación

**Files:**
- Modify: `lib/account/account_screen.dart`
- Modify: `test/account_screen_test.dart`
- Modify: `test/access_flow_test.dart`

**Interfaces:**
- `sign-out-button` abre un `AlertDialog`; `confirm-sign-out` ejecuta callback.
- `delete-account-button` abre una página explicativa; `continue-delete-account`
  abre confirmación final; `confirm-delete-account` ejecuta callback.

- [ ] **Step 1: Escribir pruebas fallidas de cancelar y confirmar**

Comprobar cuatro casos: cancelar cierre no ejecuta callback; confirmar cierre lo
ejecuta una vez; cancelar eliminación no ejecuta callback; confirmar eliminación
lo ejecuta una vez y vuelve al acceso mediante `AccessGate`.

- [ ] **Step 2: Ejecutar y confirmar el fallo correcto**

Run: `flutter test test/account_screen_test.dart test/access_flow_test.dart`
Expected: FAIL por ausencia de los flujos de confirmación.

- [ ] **Step 3: Implementar cierre de sesión**

El diálogo usa título `¿Cerrar sesión?`, texto `Podrás volver a ingresar cuando
quieras`, botón neutral `Cancelar` y botón principal `Cerrar sesión`.

- [ ] **Step 4: Implementar eliminación en dos pasos**

La página enumera que se eliminan identidad, respuestas y sesión local, y que no
se elimina la programación administrativa del recinto. El diálogo final usa
`Esta acción elimina los datos locales de esta demostración` y dos botones
claramente distintos.

- [ ] **Step 5: Ejecutar pruebas de acciones sensibles**

Run: `flutter test test/account_screen_test.dart test/access_flow_test.dart`
Expected: PASS.

### Task 5: Regresión, simulador y bitácora

**Files:**
- Modify: `/Users/afnaranjo/traiding/AGENTS.md`
- Verify: todos los archivos anteriores

**Interfaces:**
- Produces: evidencia de pruebas, compilación e instalación local.

- [ ] **Step 1: Formatear y analizar**

Run: `dart format lib/account lib/auth/access_flow.dart lib/main.dart test`
Expected: formato correcto.

Run: `flutter analyze`
Expected: `No issues found!`.

- [ ] **Step 2: Ejecutar todas las pruebas**

Run: `flutter test`
Expected: todas las pruebas PASS.

Run: `node test/map_admin_editor_test.mjs`
Expected: `map_admin_editor_test: ok`.

Run: `node test/map_filter_test.mjs`
Expected: `map_filter_test: ok`.

- [ ] **Step 3: Compilar e instalar en el simulador existente**

Run: `flutter build ios --simulator --debug`
Expected: genera `build/ios/iphonesimulator/Runner.app`.

Run: `xcrun simctl install 254301F4-DF73-4698-ADE9-0642A856969F build/ios/iphonesimulator/Runner.app`
Expected: exit 0.

Run: `xcrun simctl launch 254301F4-DF73-4698-ADE9-0642A856969F com.parkdemo.parkDemo`
Expected: devuelve PID y abre la app.

- [ ] **Step 4: Verificar visualmente el flujo principal**

Entrar como invitado, abrir Cuenta, cancelar y confirmar un cierre de sesión;
volver a entrar, abrir eliminación, cancelar antes de confirmar y comprobar que
los documentos legales y soporte abren sin internet.

- [ ] **Step 5: Cerrar la bitácora y publicar en Git**

Mover `park-account-compliance-frontend-20260902` de `Trabajo activo` al
`Registro de trabajo`, incluyendo archivos, pruebas y bloqueadores de publicación.
Revisar que no existan secretos, crear un commit con todos los cambios válidos y
hacer push a `origin/main` sin usar fuerza.
