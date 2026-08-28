# Mushuc Runa App Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:executing-plans` to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the local Flutter application to match the approved Mushuc
Runa wine, gold and ivory redesign while preserving the existing real fair map,
POIs, search, routes and Flutter GPS bridge.

**Architecture:** Adapt the existing Flutter application in place, preserving
its current `lib/main.dart` structure. The center Runi action opens a native
bottom sheet instead of becoming a fifth page. Keep the existing self-contained
HTML map as the functional map engine and change only its presentation layer and
Flutter loading/error chrome. Do not create another checkout, app copy or branch.

**Tech Stack:** Flutter 3 / Dart, Material 3, `webview_flutter`, `geolocator`,
`url_launcher`, self-contained HTML/CSS/JavaScript map.

**Spec:** `/Users/afnaranjo/Downloads/Mushuc Runa App Rediseño.zip`, especially
`Mushuc Runa App.dc.html` and `.thumbnail`. The `github.md` file is context only;
it does not authorize Git operations.

## Global Constraints

- The ZIP is the visual source of truth for all four screens and the Runi sheet.
- Preserve the current map image, POI catalogue, category filters, search,
  routing, drag/zoom behavior and geolocation bridge.
- Use the approved palette: wine `#7A1315`, deep wine `#56090B`, gold
  `#E2B563`, warm gold `#C08A3E`, ivory `#FAF3E6`, ink `#33201A`.
- Use neutral Latin American Spanish with `tú`; never introduce voseo.
- Work only in the existing local checkout. Do not commit, push or deploy.
- Preserve all existing SDK migration changes in `ios/` and `pubspec.lock`.

---

### Task 1: Navigation and visual foundation

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/main.dart`
- Test: `test/app_navigation_test.dart`

**Interfaces:**
- Produces: `MushucRunaApp`, `RootShell({WidgetBuilder? mapBuilder})`,
  `MrColors`, `MrTheme`, `showRuniSheet(BuildContext)`.
- Consumes: the four screen widgets created in later tasks; temporary screen
  shells may be used until those tasks are green.

- [ ] **Step 1: Write the failing navigation test**

```dart
testWidgets('la navegación abre las cuatro áreas y Runi', (tester) async {
  await tester.pumpWidget(MushucRunaApp(
    mapBuilder: (_) => const Text('Mapa funcional'),
  ));
  expect(find.text('¡Hola, familia!'), findsOneWidget);
  await tester.tap(find.text('Mapa'));
  await tester.pumpAndSettle();
  expect(find.text('Mapa funcional'), findsOneWidget);
  await tester.tap(find.text('Paquetes'));
  await tester.pumpAndSettle();
  expect(find.text('Paquetes y entradas'), findsOneWidget);
  await tester.tap(find.byKey(const Key('runi-nav-button')));
  await tester.pumpAndSettle();
  expect(find.text('TU GUÍA INTELIGENTE'), findsOneWidget);
  await tester.tap(find.text('Comida'));
  await tester.pumpAndSettle();
  expect(find.text('Sabores del complejo'), findsOneWidget);
});
```

- [ ] **Step 2: Run RED**

Run: `flutter test test/app_navigation_test.dart`

Expected: failure because the approved navigation, page titles and Runi action
do not exist.

- [ ] **Step 3: Implement the foundation**

Create the palette/theme and a floating five-position navigation bar with four
destinations plus the elevated gold Runi button. Replace the eager
`IndexedStack` with lazy active-page construction so widget tests do not create
an unavailable native WebView platform.

- [ ] **Step 4: Run GREEN**

Run: `flutter test test/app_navigation_test.dart`

Expected: PASS.

### Task 2: Home experience

**Files:**
- Modify: `lib/main.dart`
- Test: `test/home_screen_test.dart`

**Interfaces:**
- Produces: `HomeScreen({VoidCallback? onOpenPackages, VoidCallback? onOpenRuni})`.
- Consumes: `MrColors` and shared theme typography.

- [ ] **Step 1: Write the failing Home behavior test**

```dart
testWidgets('Inicio presenta la experiencia familiar y abre paquetes',
    (tester) async {
  var opened = false;
  await tester.pumpWidget(MaterialApp(
    home: HomeScreen(onOpenPackages: () => opened = true),
  ));
  expect(find.text('Atracciones populares'), findsOneWidget);
  expect(find.textContaining('2x1 en el paquete'), findsOneWidget);
  await tester.tap(find.text('Ver paquetes'));
  expect(opened, isTrue);
});
```

- [ ] **Step 2: Run RED**

Run: `flutter test test/home_screen_test.dart`

Expected: failure because the redesigned Home widget does not exist.

- [ ] **Step 3: Implement Home**

Build the branded header, family greeting, Runi recommendation, horizontal
attraction cards, wine 2x1 promotion and the three factual stat cards. Use local
brand assets where imagery adds value; do not depend on remote Unsplash images.

- [ ] **Step 4: Run GREEN**

Run: `flutter test test/home_screen_test.dart`

Expected: PASS.

### Task 3: Packages, food and Runi sheet

**Files:**
- Modify: `lib/main.dart`
- Test: `test/product_surfaces_test.dart`

**Interfaces:**
- Produces: `PackagesScreen`, `FoodScreen`, `showRuniSheet(BuildContext)`.
- Consumes: `MrColors` and copied local campaign artwork.

- [ ] **Step 1: Write failing product-surface tests**

```dart
testWidgets('Paquetes muestra precios y beneficios', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: PackagesScreen()));
  expect(find.text('Tuki Tuki'), findsOneWidget);
  expect(find.text(r'$25'), findsWidgets);
  expect(find.textContaining('Parque de dinosaurios'), findsWidgets);
});

testWidgets('Comida muestra tiempos y acción de pedido', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: FoodScreen()));
  expect(find.text('Sabores del complejo'), findsOneWidget);
  expect(find.text('Pedir'), findsWidgets);
  expect(find.textContaining('min'), findsWidgets);
});
```

- [ ] **Step 2: Run RED**

Run: `flutter test test/product_surfaces_test.dart`

Expected: failure because the approved product surfaces do not exist.

- [ ] **Step 3: Implement the surfaces**

Build package cards for Tuki Tuki, Tuki Punlla and All Day using the ZIP content,
with visible adult/child prices and benefit lists. Build the food list with
warm cards, category icons, ratings, wait times and safe non-transactional
prototype actions. Build the Runi sheet with the approved recommendation,
itinerary timeline and message field presentation.

- [ ] **Step 4: Run GREEN**

Run: `flutter test test/product_surfaces_test.dart test/app_navigation_test.dart`

Expected: PASS.

### Task 4: Functional map reskin

**Files:**
- Modify: `lib/main.dart`
- Modify: `assets/map/index.html`
- Test: `test/map_shell_test.dart`

**Interfaces:**
- Produces: `MapScreen`, retaining the `FlutterGeo` JavaScript channel and the
  current fair coordinates/radius.
- Consumes: `MrColors`; existing HTML functions for POIs, filtering, routing,
  zooming and geolocation.

- [ ] **Step 1: Write the failing map-shell test**

```dart
testWidgets('Mapa conserva una construcción inyectable en navegación',
    (tester) async {
  await tester.pumpWidget(MushucRunaApp(
    mapBuilder: (_) => const Semantics(
      label: 'Mapa real Mushuc Runa',
      child: SizedBox.expand(),
    ),
  ));
  await tester.tap(find.text('Mapa'));
  await tester.pumpAndSettle();
  expect(find.bySemanticsLabel('Mapa real Mushuc Runa'), findsOneWidget);
});
```

- [ ] **Step 2: Run RED**

Run: `flutter test test/map_shell_test.dart`

Expected: failure before the injectable lazy map boundary exists.

- [ ] **Step 3: Implement the map presentation**

Move the existing Flutter GPS bridge into `MapScreen`. Restyle the HTML map with
ivory floating panels, category chips matching the prototype, wine/gold selected
states, branded pins, gold current-position treatment, cream info card, matching
zoom buttons and mobile-safe spacing above the Flutter navigation bar. Do not
change POI coordinates, base-map data, route calculations or georeferencing.

- [ ] **Step 4: Run GREEN and browser interaction checks**

Run: `flutter test test/map_shell_test.dart test/app_navigation_test.dart`

Then verify in a real browser/WebView: drag, pinch/zoom, category toggle,
search, open/close a POI card and route action.

Expected: tests PASS and all interactions remain usable.

### Task 5: Assets and integrated local simulation

**Files:**
- Create: `assets/brand/` campaign images copied from the approved ZIP
- Modify: `pubspec.yaml`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: all prior tasks.
- Produces: a locally runnable, visually verified iOS application.

- [ ] **Step 1: Register local assets and remove remote-image dependence from the redesigned screens**

Copy only the approved artwork used by the implementation with descriptive
names and register `assets/brand/` in `pubspec.yaml`.

- [ ] **Step 2: Run complete automated verification**

Run: `dart format lib test`

Run: `flutter analyze`

Run: `flutter test`

Expected: formatting succeeds, analyzer reports no issues and all tests pass.

- [ ] **Step 3: Run and inspect on iPhone simulator**

Run the app on the available iPhone 17 Pro Max simulator. Inspect all four
screens, Runi, long content scrolling, safe areas, map overlays and bottom-nav
clearance. Capture screenshots for comparison with the ZIP thumbnail.

- [ ] **Step 4: Record continuity**

Move the active task in `/Users/afnaranjo/traiding/AGENTS.md` to the work log,
including files, commands, results, residual risks and the next recommended
step. Do not commit or push.
