# Login and Onboarding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Añadir un acceso frontend y onboarding de tres preguntas antes de la app Mushuc Runa existente.

**Architecture:** Un `AccessGate` stateful controla las etapas acceso, registro,
onboarding y contenido sin introducir navegación global ni servicios externos.
El flujo vive en un archivo enfocado y entrega únicamente un nombre visible a
`RootShell`; las pantallas actuales permanecen intactas detrás del gate.

**Tech Stack:** Flutter 3, Dart, Material 3, flutter_test, iOS Simulator.

**Spec:** `docs/superpowers/specs/2026-08-31-login-onboarding-design.md`

## Global Constraints

- Trabajar únicamente en `/Users/afnaranjo/traiding/park-demo-flutter`.
- No añadir backend, Firebase, OAuth real, red ni credenciales.
- No persistir correos, contraseñas ni respuestas.
- No crear copia, rama, commit, push ni despliegue remoto.
- Conservar navegación, mapa, GPS y superficies existentes.
- Todo texto de interfaz debe usar español latino neutro sin voseo.

---

### Task 1: Contrato del flujo de acceso

**Files:**
- Create: `test/access_flow_test.dart`
- Create: `lib/auth/access_flow.dart`
- Modify: `lib/main.dart`

**Interfaces:**
- Produces: `AccessGate({required Widget Function(String) appBuilder})`.
- Produces: claves `login-email`, `login-password`, `login-submit`,
  `google-access`, `create-account` y `register-submit`.
- Consumes: `RootShell(displayName: String)` de la app existente.

- [ ] **Step 1: Escribir la prueba fallida del acceso inicial**

```dart
await tester.pumpWidget(const MushucRunaApp());
expect(find.text('Tu aventura comienza aquí'), findsOneWidget);
expect(find.byKey(const Key('google-access')), findsOneWidget);
expect(find.byKey(const Key('create-account')), findsOneWidget);
```

- [ ] **Step 2: Ejecutar la prueba y confirmar RED**

Run: `flutter test test/access_flow_test.dart`

Expected: falla porque el acceso todavía no existe.

- [ ] **Step 3: Crear el modelo de etapas y el gate mínimo**

```dart
enum AccessStage { login, register, onboarding, app }

class AccessGate extends StatefulWidget {
  const AccessGate({super.key, required this.appBuilder});
  final Widget Function(String displayName) appBuilder;
}
```

`MushucRunaApp` debe usar:

```dart
home: AccessGate(appBuilder: (name) => RootShell(displayName: name)),
```

- [ ] **Step 4: Implementar validación local del acceso y registro**

El correo debe contener `@`; la contraseña debe tener al menos seis caracteres;
el registro exige nombre y confirmación idéntica. `Continuar con Google` llama
al onboarding con `Visitante`. No se usa almacenamiento ni red.

- [ ] **Step 5: Ejecutar la prueba y confirmar GREEN**

Run: `flutter test test/access_flow_test.dart`

Expected: todas las pruebas de acceso pasan.

### Task 2: Onboarding de tres preguntas

**Files:**
- Modify: `lib/auth/access_flow.dart`
- Create: `test/onboarding_flow_test.dart`

**Interfaces:**
- Produces: `VisitReason`, `VisitFrequency`, `RecommendationReason`.
- Produce claves `onboarding-next`, `onboarding-back` y
  `onboarding-finish`.
- Consume el nombre capturado por `AccessGate`.

- [ ] **Step 1: Escribir la prueba fallida del recorrido completo**

```dart
await tester.tap(find.byKey(const Key('google-access')));
await tester.pumpAndSettle();
expect(find.text('¿Qué te trae a Mushuc Runa?'), findsOneWidget);
expect(find.text('1 de 3'), findsOneWidget);
```

La prueba selecciona `Todo`, `Primera vez` y `Diversión familiar`, y espera que
`Terminar` abra Inicio.

- [ ] **Step 2: Ejecutar la prueba y confirmar RED**

Run: `flutter test test/onboarding_flow_test.dart`

Expected: falla porque las preguntas todavía no existen.

- [ ] **Step 3: Implementar preguntas y selección**

Usar un `AnimatedSwitcher` para las tres etapas. Las preguntas 1 y 3 mantienen
`Set<String>` y la pregunta 2 un único `String?`. `Todo` limpia otras razones y
cualquier razón específica retira `Todo`.

- [ ] **Step 4: Implementar avance, retroceso y bloqueo**

`onboarding-next` es nulo hasta que la etapa actual tenga respuesta.
`onboarding-back` vuelve a la pregunta anterior y desde la primera vuelve al
registro o acceso de origen. `onboarding-finish` entrega el nombre al
`appBuilder`.

- [ ] **Step 5: Ejecutar la prueba y confirmar GREEN**

Run: `flutter test test/onboarding_flow_test.dart`

Expected: el recorrido de tres pasos termina en Inicio.

### Task 3: Saludo personalizado y regresión de la app

**Files:**
- Modify: `lib/main.dart`
- Modify: `test/app_navigation_test.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consume: `RootShell(displayName: String)`.
- Produce: `HomeScreen(displayName: String)` y texto `¡Hola, <nombre>!`.

- [ ] **Step 1: Adaptar pruebas existentes al gate**

Las pruebas de pantallas internas deben montar `RootShell(displayName:
'Familia')`; la prueba de arranque debe esperar la bienvenida del gate.

- [ ] **Step 2: Ejecutar la suite y confirmar fallos esperados**

Run: `flutter test`

Expected: solo fallan contratos aún no adaptados al saludo o al gate.

- [ ] **Step 3: Propagar el nombre sin alterar las pestañas**

```dart
class RootShell extends StatefulWidget {
  const RootShell({super.key, required this.displayName});
  final String displayName;
}
```

La pantalla cero recibe `HomeScreen(displayName: widget.displayName, ...)` y
renderiza `¡Hola, ${displayName.trim()}!`.

- [ ] **Step 4: Ejecutar regresión completa**

Run: `flutter test`

Expected: acceso, onboarding, Inicio, Mapa, Paquetes, Comida y GPS pasan.

### Task 4: Calidad y ejecución local

**Files:**
- Modify: `AGENTS.md` en la raíz de coordinación al cerrar la tarea.

**Interfaces:**
- Consume: aplicación y pruebas terminadas.
- Produce: app instalada y abierta en el simulador iOS existente.

- [ ] **Step 1: Formatear y analizar**

Run: `dart format lib test`

Run: `flutter analyze`

Expected: `No issues found`.

- [ ] **Step 2: Ejecutar todas las pruebas Flutter y del mapa**

Run: `flutter test`

Run: `node test/map_filter_test.mjs`

Expected: ambas suites pasan.

- [ ] **Step 3: Compilar para iOS Simulator**

Run: `flutter build ios --simulator`

Expected: `build/ios/iphonesimulator/Runner.app` se genera correctamente.

- [ ] **Step 4: Instalar, abrir y revisar visualmente**

Instalar `Runner.app` en el iPhone 17 Pro Max ya creado, abrir
`com.parkdemo.parkDemo` y confirmar acceso, registro, las tres preguntas y el
saludo final sin desbordamientos.

- [ ] **Step 5: Registrar el cierre**

Eliminar la tarea de `Trabajo activo` y añadir al final de `AGENTS.md` el
resultado, archivos, pruebas, riesgos y siguiente paso. No hacer commit ni push.
