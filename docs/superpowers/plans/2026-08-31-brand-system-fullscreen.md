# Brand System and Fullscreen Access Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the documented Mushuc Runa screen palette throughout Flutter and the embedded map, while rebuilding login, registration, and onboarding as full-height mobile compositions.

**Architecture:** Introduce one small design module that owns official screen colors, theme construction, and typographic roles. Existing `AppColors` consumers remain stable by moving that class into the module instead of rewriting the whole app. Access screens consume the shared tokens and use reusable full-height sheet layouts; the map mirrors the tokens through CSS custom properties.

**Tech Stack:** Flutter 3 / Dart, Material 3, widget tests, embedded HTML/CSS/JavaScript, iOS Simulator.

**Spec:** `docs/superpowers/specs/2026-08-31-brand-system-fullscreen-design.md`

## Global Constraints

- Work only in `/Users/afnaranjo/traiding/park-demo-flutter`; do not create a clone, branch, worktree, or second app.
- Preserve the existing logo/wordmark representation and all frontend behavior.
- Use exact screen colors `#5E0000`, `#7A0708`, `#004F18`, `#BEA458`, and `#0A0203` as the brand source of truth.
- Respect Trajan as the institutional display role and modified Signboard as the existing wordmark role; do not bundle or claim proprietary font files that were not supplied.
- Keep system sans serif for UI copy, fields, filters, and dense data.
- Preserve semantic category and accessibility colors where replacing them would reduce comprehension.
- Do not add backend, OAuth, persistence, credentials, or network behavior.
- Do not commit, push, or deploy remotely; Alex requested local frontend review first.

---

### Task 1: Centralize brand colors and typographic roles

**Files:**
- Create: `lib/design/brand_theme.dart`
- Modify: `lib/main.dart:14-76`
- Modify: `lib/auth/access_flow.dart:1-220`
- Create: `test/brand_theme_test.dart`

**Interfaces:**
- Produces: `AppColors`, `BrandType.institutional`, `BrandType.wordmark`, and `AppTheme.light()`.
- Consumes: Flutter `ThemeData`, `ColorScheme`, and existing `AppColors` call sites.

- [ ] **Step 1: Write the failing theme test**

```dart
testWidgets('la app expone los colores oficiales en su tema', (tester) async {
  await tester.pumpWidget(const MushucRunaApp());
  final context = tester.element(find.byType(AccessGate));
  final theme = Theme.of(context);
  expect(theme.colorScheme.primary, const Color(0xFF7A0708));
  expect(theme.colorScheme.secondary, const Color(0xFFBEA458));
  expect(theme.colorScheme.tertiary, const Color(0xFF004F18));
  expect(theme.scaffoldBackgroundColor, AppColors.surface);
});
```

- [ ] **Step 2: Verify RED**

Run: `flutter test test/brand_theme_test.dart`

Expected: FAIL because the current theme uses approximate colors and the design module does not exist.

- [ ] **Step 3: Create the shared module**

Implement `lib/design/brand_theme.dart` with this public shape:

```dart
class AppColors {
  static const primary = Color(0xFF7A0708);
  static const primaryDk = Color(0xFF5E0000);
  static const primaryDeep = Color(0xFF5E0000);
  static const green = Color(0xFF004F18);
  static const gold = Color(0xFFBEA458);
  static const ink = Color(0xFF0A0203);
  // Light surfaces are derived neutrals for screen readability.
}

class BrandType {
  static const institutional = TextStyle(
    fontFamily: 'serif',
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );
  static const wordmark = TextStyle(
    fontWeight: FontWeight.w900,
    letterSpacing: -.5,
  );
}

class AppTheme {
  static ThemeData light() => ThemeData(/* official ColorScheme */);
}
```

Keep compatibility members used by `main.dart` (`primarySoft`, `goldDk`, `coral`, `orange`, `yellow`, `inkSoft`, `line`, `surface`, `cardBg`, `mapGreen`) and derive them from the official hierarchy.

- [ ] **Step 4: Connect existing consumers**

Import `design/brand_theme.dart` in `main.dart`, remove the local `AppColors`, and replace the inline `ThemeData` with `AppTheme.light()`. Import the same module in `access_flow.dart` and make `_AccessColors` delegate to `AppColors` so the access UI cannot drift.

- [ ] **Step 5: Verify GREEN and checkpoint**

Run: `flutter test test/brand_theme_test.dart test/access_flow_test.dart test/onboarding_flow_test.dart`

Expected: theme test and existing access tests pass except the intentionally RED full-height assertions planned in Tasks 2 and 3.

Run: `git diff --check`.

---

### Task 2: Build the full-height login and registration surfaces

**Files:**
- Modify: `lib/auth/access_flow.dart:230-650`
- Modify: `test/access_flow_test.dart`

**Interfaces:**
- Consumes: `AppColors`, `BrandType`, `_WelcomeHero`, existing form callbacks and validators.
- Produces: widget keys `login-full-sheet` and `register-full-sheet`; reusable `_FullHeightAccessLayout` and `_AccessSheet` widgets.

- [ ] **Step 1: Confirm the existing RED test**

Run: `flutter test test/access_flow_test.dart --plain-name 'login y registro llenan la pantalla hasta el borde inferior'`

Expected: FAIL because `login-full-sheet` and `register-full-sheet` do not exist.

- [ ] **Step 2: Implement the full-height shell**

Create a private layout that uses `LayoutBuilder`, `SingleChildScrollView`, a `Stack`, and a sheet with a minimum height equal to the remaining viewport:

```dart
class _FullHeightAccessLayout extends StatelessWidget {
  const _FullHeightAccessLayout({
    required this.headerHeight,
    required this.header,
    required this.sheetKey,
    required this.sheet,
  });
  // Stack: full-width header at top; white sheet starts with overlap and
  // has minHeight = viewportHeight - sheetTop.
}
```

The layout must grow beyond the viewport when keyboard or validation errors need more room; no fixed clipping.

- [ ] **Step 3: Recompose login**

Use a 34–38% viewport photo header with safe-area-aware brand lockup. Start the white sheet with a 30–34 px overlap and include title, Google, divider, fields, primary action, account creation, spacer, and demo note inside the same surface. Remove the detached bottom note and outer mobile margins.

- [ ] **Step 4: Recompose registration**

Use a wine institutional header with back control and the existing wordmark. Place all four fields, primary action, and demo note inside `register-full-sheet`. Keep the exact validators and callback flow unchanged.

- [ ] **Step 5: Verify GREEN and responsive behavior**

Run: `flutter test test/access_flow_test.dart`.

Expected: all access tests pass with no `RenderFlex` exception at 430 × 932.

Run: `git diff --check`.

---

### Task 3: Convert onboarding to a full-height branded sheet

**Files:**
- Modify: `lib/auth/access_flow.dart:650-1100`
- Modify: `test/onboarding_flow_test.dart`

**Interfaces:**
- Consumes: existing answer sets, question index, callbacks, official brand tokens.
- Produces: `onboarding-full-sheet`; 88 px option rows; fixed visible bottom action.

- [ ] **Step 1: Confirm the existing RED test**

Run: `flutter test test/onboarding_flow_test.dart --plain-name 'el cuestionario llena la pantalla y deja la acción visible'`

Expected: FAIL because `onboarding-full-sheet` does not exist.

- [ ] **Step 2: Build the wine header**

Replace the safe-area card composition with a full scaffold stack. The top wine region contains the safe back button, official progress, institutional step label, and question icon. Compute the sheet start from `MediaQuery.padding.top` so it remains balanced on devices with and without Dynamic Island.

- [ ] **Step 3: Build the white question sheet**

Make `_QuestionCard` the edge-to-edge white sheet with rounded top corners. Keep question and description at the top, wrap option rows in the scrollable middle, and keep the Continue/Finish action in a non-scrolling bottom area padded by `MediaQuery.padding.bottom`.

Set `_OnboardingOptionCard` height to at least 88 and retain the selected wine fill, gold check, multi-select rules, odd final full-width row, and semantics.

- [ ] **Step 4: Verify GREEN and flow behavior**

Run: `flutter test test/onboarding_flow_test.dart`.

Expected: all onboarding layout, three-step flow, and back/persistence tests pass.

Run: `git diff --check`.

---

### Task 4: Apply official tokens to the whole app and embedded map

**Files:**
- Modify: `lib/main.dart`
- Modify: `assets/map/index.html`
- Test: `test/app_navigation_test.dart`
- Test: `test/home_screen_test.dart`
- Test: `test/product_surfaces_test.dart`
- Test: `test/map_filter_test.mjs`

**Interfaces:**
- Consumes: shared `AppColors` and `BrandType`; existing map functions and POI semantics.
- Produces: consistent brand chrome across Home, Map, Packages, Food, Runi, navigation, and modal surfaces.

- [ ] **Step 1: Add consumer-level brand assertions**

Extend a home/navigation test to inspect the active navigation item or primary action and assert that its resolved foreground/background uses `AppColors.primary`. Keep the assertion on a rendered control rather than grepping source.

- [ ] **Step 2: Verify RED if a rendered control still uses an approximate color**

Run: `flutter test test/app_navigation_test.dart test/home_screen_test.dart test/product_surfaces_test.dart`.

Expected: a new exact-color assertion fails until the shared tokens are applied.

- [ ] **Step 3: Replace incompatible inline brand values**

Use `AppColors` and `BrandType` for institutional headers, wordmark text, primary actions, selected navigation, modal headers, and decorative gold details. Leave semantic POI/category colors when they convey distinct meaning. Do not refactor unrelated layout or data.

- [ ] **Step 4: Align the map CSS**

Define and use:

```css
:root {
  --brand-wine: #7a0708;
  --brand-wine-dark: #5e0000;
  --brand-green: #004f18;
  --brand-gold: #bea458;
  --brand-ink: #0a0203;
}
```

Apply them to map header, active filters, event pins, selected details, buttons, and institutional text without changing map geometry, filters, GPS, or data.

- [ ] **Step 5: Verify app and map behavior**

Run: `flutter test`.

Run: `node test/map_filter_test.mjs`.

Expected: all Flutter and JavaScript tests pass.

---

### Task 5: Verify, build, install, and visually review

**Files:**
- Modify: `AGENTS.md` after verification only.

**Interfaces:**
- Consumes: completed Tasks 1–4.
- Produces: local `Runner.app` installed on simulator `254301F4-DF73-4698-ADE9-0642A856969F`.

- [ ] **Step 1: Format and inspect changes**

Run: `dart format lib/design/brand_theme.dart lib/auth/access_flow.dart lib/main.dart test/brand_theme_test.dart test/access_flow_test.dart test/onboarding_flow_test.dart`.

Run: `git diff --check`.

- [ ] **Step 2: Run the complete verification suite**

Run: `flutter test`.

Run: `flutter analyze`.

Run: `node test/map_filter_test.mjs`.

Expected: zero failures and zero analyzer issues.

- [ ] **Step 3: Build for iOS Simulator**

Run: `flutter build ios --simulator`.

Expected: `build/ios/iphonesimulator/Runner.app` is produced successfully.

- [ ] **Step 4: Install and launch locally**

Run:

```bash
xcrun simctl terminate 254301F4-DF73-4698-ADE9-0642A856969F com.parkdemo.parkDemo
xcrun simctl install 254301F4-DF73-4698-ADE9-0642A856969F build/ios/iphonesimulator/Runner.app
xcrun simctl launch 254301F4-DF73-4698-ADE9-0642A856969F com.parkdemo.parkDemo
```

- [ ] **Step 5: Capture visual evidence**

Capture the login screen from the simulator and generate widget-test captures for onboarding and Home if direct interaction is unavailable. Check full-height coverage, official color hierarchy, typographic roles, safe areas, tap targets, and absence of overflow.

- [ ] **Step 6: Record completion without Git publication**

Move `park-fullscreen-access-20260831` from active work to the end of `AGENTS.md`, recording files, tests, simulator state, risks, and that no commit/push/deployment occurred.
