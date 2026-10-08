# Google Maps Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:subagent-driven-development` (recommended) or
> `superpowers:executing-plans` to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reemplazar el plano PDF visible por un mapa Google híbrido nativo con
GPS, rutas peatonales, distancias, recorrido diario, programación y edición
administrativa local.

**Architecture:** `MapScreen` pasará de un WebView con coordenadas `x/y` a un
`GoogleMap` nativo alimentado por modelos geográficos puros en Dart. La
migración del esquema 3 al 4, el enrutamiento A*, el filtrado GPS, la
persistencia y las reglas administrativas quedarán separados del widget para
ser probados sin el SDK de Google.

**Tech Stack:** Flutter/Dart, `google_maps_flutter: ^2.18.1`, `geolocator`,
`shared_preferences: ^2.5.6`, Google Maps SDK for Android/iOS, Flutter Test.

**Spec:**
`docs/superpowers/specs/2026-10-08-google-maps-navigation-design.md`

## Global Constraints

- Trabajar sobre `/Users/afnaranjo/traiding/park-demo-flutter`; no crear una
  copia de la aplicación ni un worktree.
- Mantener el alcance en frontend; no crear backend ni simular sincronización
  multiusuario.
- El PDF y `mushuc_runa_validated.svg` no pueden renderizarse en la experiencia
  final del visitante.
- Google Maps usa `MapType.hybrid`; iOS y Android consumen el mismo documento de
  puntos en latitud/longitud.
- No guardar, imprimir ni versionar claves de Google Maps. Usar archivos locales
  ignorados y ejemplos sin valores.
- Elevar Android a SDK mínimo 24 e iOS a 15, requeridos por
  `google_maps_flutter 2.18.1`.
- Conservar la línea gráfica: vino `#7A0708`, vino profundo `#5E0000`, dorado
  `#BEA458`, verde `#004F18`, blanco y marfil.
- Mostrar la precisión GPS real; nunca prometer precisión fija de un metro.
- Solo el rol administrador puede mutar puntos o programación. En esta fase la
  cuenta administrativa sigue siendo demostrativa y local.
- La eliminación de puntos es lógica (`isVisible=false`), nunca destructiva.
- No hacer commit ni push sin una solicitud explícita adicional de Alex. Cada
  tarea termina con verificación y `git diff`/`git status`, no con commit.
- Conservar cambios ajenos del worktree y no incluir `.superpowers/` en la app.

## Review Focus

- **Documento v3 personalizado:** migrar puntos movidos por el administrador sin
  devolverlos a la semilla ni perder eventos; Task 2 incluye la prueba.
- **Clave ausente o rechazada:** mostrar una configuración recuperable y no una
  pantalla blanca; Tasks 1 y 6 incluyen las pruebas.
- **GPS tardío, impreciso o con salto:** conservar la última muestra aceptada y
  evitar sumar metros falsos; Tasks 4 y 7 incluyen las pruebas.
- **Mapa sin red:** mantener selección, rutas y lista de lugares cercanos aunque
  no carguen las imágenes; Task 6 incluye la prueba.
- **Visitante intentando editar:** no exponer ni ejecutar mutaciones aunque se
  invoque el controlador directamente; Task 8 incluye la prueba.

---

## File Structure

### Archivos nuevos

- `lib/map/map_geo.dart`: punto geográfico, Haversine y proyección heredada.
- `lib/map/map_document_store.dart`: interfaz y persistencia local versionada.
- `lib/map/map_runtime_config.dart`: estado no secreto de configuración Maps.
- `lib/map/map_route_graph.dart`: red peatonal geográfica y A*.
- `lib/map/map_navigation_controller.dart`: ruta activa, progreso y recálculo.
- `lib/map/daily_walking_tracker.dart`: recorrido diario filtrado.
- `lib/map/map_view_model.dart`: selección, filtros, zoom y estados del mapa.
- `lib/map/map_connectivity_monitor.dart`: prueba acotada de disponibilidad de
  red con resolución inyectable.
- `lib/map/map_admin_controller.dart`: mutaciones autorizadas y respaldo.
- `lib/map/map_screen.dart`: composición de la experiencia Google Maps.
- `lib/map/map_screen_controller.dart`: coordinación entre ubicación, cámara,
  ruta y estado visual.
- `lib/map/widgets/map_search_filters.dart`: búsqueda y filtros compactos.
- `lib/map/widgets/map_navigation_card.dart`: métricas y acciones de ruta.
- `lib/map/widgets/map_place_sheet.dart`: detalle y programación del lugar.
- `lib/map/widgets/map_admin_sheet.dart`: alta y edición administrativa.
- `assets/map/map_document_v4.json`: semilla geográfica validada.
- `assets/map/route_graph_v2.json`: red peatonal geográfica.
- `tool/migrate_map_v3_to_v4.dart`: migración reproducible desde los datos
  actuales.
- `android/secrets.properties.example` y
  `ios/Flutter/GoogleMapsSecrets.xcconfig.example`: plantillas sin claves.
- Pruebas Dart correspondientes en `test/`.

### Archivos modificados

- `pubspec.yaml` y `pubspec.lock`: dependencias y activos.
- `.gitignore`: archivos locales con claves.
- `android/app/build.gradle.kts` y `android/app/src/main/AndroidManifest.xml`:
  SDK mínimo e inyección de clave.
- `ios/Podfile`, `ios/Flutter/Debug.xcconfig`,
  `ios/Flutter/Release.xcconfig`, `ios/Runner/Info.plist` y
  `ios/Runner/AppDelegate.swift`: iOS 15 e inicialización Maps.
- `lib/account/account_session.dart` y `lib/auth/access_flow.dart`: rol local.
- `lib/map/map_document_controller.dart`: esquema 4 y operaciones inmutables.
- `lib/map/map_location_controller.dart`: filtros compatibles con la pantalla
  nativa.
- `lib/runi/runi_recommender.dart`: continuidad por distancia geográfica.
- `lib/main.dart`: importar `MapScreen` y retirar la clase WebView embebida.
- `test/app_navigation_test.dart`, `test/product_surfaces_test.dart` y pruebas
  existentes afectadas por el nuevo contrato.
- `AGENTS.md`: continuidad, resultados y pendientes.

### Legado conservado temporalmente

`assets/map/index.html`, sus scripts y `mushuc_runa_validated.svg` se mantienen
en disco hasta completar la comparación de datos. Task 10 los retira del bundle;
no se borran sin una revisión específica.

---

### Task 1: Google Maps dependency and secret-safe platform configuration

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Modify: `.gitignore`
- Modify: `android/app/build.gradle.kts`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Create: `android/secrets.properties.example`
- Modify: `ios/Podfile`
- Modify: `ios/Flutter/Debug.xcconfig`
- Modify: `ios/Flutter/Release.xcconfig`
- Modify: `ios/Runner/Info.plist`
- Modify: `ios/Runner/AppDelegate.swift`
- Create: `ios/Flutter/GoogleMapsSecrets.xcconfig.example`
- Create: `lib/map/map_runtime_config.dart`
- Test: `test/map_runtime_config_test.dart`

**Interfaces:**
- Produces: `MapRuntimeConfig.mapsConfigured` (`bool`) y
  `MapRuntimeConfig.missingKeyMessage` (`String`).
- Consumes: `bool.fromEnvironment('GOOGLE_MAPS_CONFIGURED', defaultValue:false)`;
  no consume la clave.

- [ ] **Step 1: Write the failing runtime-configuration test**

Crear pruebas que afirmen que el valor predeterminado es `false`, el mensaje
contiene `configurar el mapa` y ninguna constante expone `API_KEY`.

- [ ] **Step 2: Run the test and verify the failure**

Run: `flutter test test/map_runtime_config_test.dart`

Expected: FAIL porque `MapRuntimeConfig` no existe.

- [ ] **Step 3: Add packages and platform floors**

Agregar `google_maps_flutter: ^2.18.1` y `shared_preferences: ^2.5.6`; establecer
`minSdk = 24` y `platform :ios, '15.0'`.

- [ ] **Step 4: Add ignored key plumbing and keyless examples**

Ignorar `android/secrets.properties` e
`ios/Flutter/GoogleMapsSecrets.xcconfig`. Android lee
`GOOGLE_MAPS_API_KEY` del archivo local como `manifestPlaceholder`; iOS incluye
el xcconfig opcional, expone `$(GOOGLE_MAPS_API_KEY)` mediante `Info.plist` y
`AppDelegate` solo llama `GMSServices.provideAPIKey` si el valor no está vacío.

- [ ] **Step 5: Implement `MapRuntimeConfig`**

Crear la clase inmutable con las dos propiedades del contrato y sin leer la
clave real.

- [ ] **Step 6: Resolve dependencies and rerun the test**

Run: `flutter pub get && flutter test test/map_runtime_config_test.dart`

Expected: dependency resolution succeeds; test PASS.

- [ ] **Step 7: Checkpoint without committing**

Run: `git diff --check && git status --short`

Expected: no whitespace errors; only Task 1 files plus prior user changes.

---

### Task 2: Geographic schema v4, deterministic migration, and seed assets

**Files:**
- Create: `lib/map/map_geo.dart`
- Modify: `lib/map/map_document_controller.dart`
- Create: `tool/migrate_map_v3_to_v4.dart`
- Create: `assets/map/map_document_v4.json`
- Create: `assets/map/route_graph_v2.json`
- Modify: `pubspec.yaml`
- Test: `test/map_geo_test.dart`
- Test: `test/map_document_controller_test.dart`
- Test: `test/map_migration_test.dart`

**Interfaces:**
- Produces: `GeoPoint(latitude: double, longitude: double)`;
  `MapGeo.distanceMeters(GeoPoint, GeoPoint) -> double`;
  `LegacyMapProjection.toGeo(double x, double y) -> GeoPoint`;
  `MapDocumentMigration.migrateV3(Map<String,Object?>) -> Map<String,Object?>`;
  `MapPlace.latitude`, `MapPlace.longitude` and `MapPlace.point`.
- Consumes: los cuatro controles geográficos actuales de
  `assets/map/map_geometry.js` y los documentos vigentes v3.

- [ ] **Step 1: Write failing geographic and migration tests**

Probar round-trip de los cuatro controles con error menor a `0.75 m`, simetría
Haversine, rechazo de latitud/longitud inválidas, migración de un punto v3
personalizado, preservación de eventos y rechazo de IDs duplicados.

- [ ] **Step 2: Run the focused tests and verify failure**

Run:
`flutter test test/map_geo_test.dart test/map_document_controller_test.dart test/map_migration_test.dart`

Expected: FAIL por interfaces geográficas ausentes.

- [ ] **Step 3: Implement the pure geographic domain**

Crear `GeoPoint`, Haversine y la transformación afín heredada con las
constantes actuales. `GeoPoint` valida rangos y no depende de Google Maps.

- [ ] **Step 4: Evolve the document to schema 4**

Cambiar `mapDocumentSchemaVersion` a `4`, sustituir `x/y` por
`latitude/longitude`, aceptar solamente v4 en `MapDocumentSnapshot.fromJson` y
mantener `recommendationId`, `venue`, `events`, `isFeatured`, `isVisible` y
`needsReview`.

- [ ] **Step 5: Implement and run the migration tool**

El script lee los datos v3 actuales, transforma lugares y nodos, conserva IDs y
eventos, y escribe JSON ordenado de forma estable. Ejecutarlo una sola vez para
generar los dos activos v4.

Run: `dart run tool/migrate_map_v3_to_v4.dart --check`

Expected: generated output matches committed assets and reports zero invalid
coordinates.

- [ ] **Step 6: Rerun focused tests**

Run:
`flutter test test/map_geo_test.dart test/map_document_controller_test.dart test/map_migration_test.dart`

Expected: all PASS.

- [ ] **Step 7: Checkpoint without committing**

Run: `git diff --check && git status --short`

---

### Task 3: Local persistence, backups, and application bootstrap

**Files:**
- Create: `lib/map/map_document_store.dart`
- Modify: `lib/map/map_document_controller.dart`
- Modify: `lib/main.dart`
- Test: `test/map_document_store_test.dart`
- Modify: `test/map_document_controller_test.dart`

**Interfaces:**
- Produces: abstract `MapDocumentStore.readCurrent()`, `readBackup()`,
  `writeValidated(currentJson, previousJson)` and `restoreBackup()`;
  `SharedPreferencesMapDocumentStore` using `SharedPreferencesAsync`;
  `MapDocumentController.initialize(seedLoader, store) -> Future<void>`;
  `MapDocumentController.replace(snapshot, {required bool persist})`.
- Consumes: schema 4 from Task 2.

- [ ] **Step 1: Write failing store and bootstrap tests**

Cubrir semilla sin datos locales, documento local más reciente, documento
corrupto que vuelve a semilla, guardado con respaldo y restauración.

- [ ] **Step 2: Run the tests and verify failure**

Run:
`flutter test test/map_document_store_test.dart test/map_document_controller_test.dart`

Expected: FAIL porque el store y `initialize` no existen.

- [ ] **Step 3: Implement store interfaces and fake-friendly controller API**

Usar dos claves con allowlist: `mushuc.map.current.v4` y
`mushuc.map.backup.v4`. Validar JSON antes de escribir y conservar el documento
anterior como respaldo.

- [ ] **Step 4: Initialize before exposing map and Runi**

`RootShell` muestra un estado breve de preparación hasta que
`MapDocumentController.initialize` cargue semilla o documento local; Runi nunca
recibe una lista vacía por una carrera de inicialización.

- [ ] **Step 5: Rerun tests**

Run:
`flutter test test/map_document_store_test.dart test/map_document_controller_test.dart test/app_navigation_test.dart`

Expected: all PASS.

- [ ] **Step 6: Checkpoint without committing**

Run: `git diff --check && git status --short`

---

### Task 4: Native route graph, navigation progress, and daily walking

**Files:**
- Create: `lib/map/map_route_graph.dart`
- Create: `lib/map/map_navigation_controller.dart`
- Create: `lib/map/daily_walking_tracker.dart`
- Modify: `lib/map/map_location_controller.dart`
- Test: `test/map_route_graph_test.dart`
- Test: `test/map_navigation_controller_test.dart`
- Test: `test/daily_walking_tracker_test.dart`
- Modify: `test/map_location_controller_test.dart`

**Interfaces:**
- Produces: `MapRouteGraph.fromJson`, `nearestNode`, `route(origin,destination)`;
  `MapRoute(polyline,totalMeters,accessId)`;
  `MapNavigationController.start`, `update`, `finish`;
  `MapNavigationState` with completed/remaining polylines, remaining meters,
  progress, arrival and recalculations;
  `DailyWalkingTracker.update(MapLocationSample) -> double`.
- Consumes: `GeoPoint`, `MapGeo.distanceMeters` and route asset v2.

- [ ] **Step 1: Port the behavioral tests before porting code**

Recrear en Dart los casos JS actuales: componentes conectados, Luna a
Megaescenario, distancia de red mayor o igual a directa, recálculo tras dos
muestras fuera de ruta, llegada con radio dinámico y rechazo de destino sin
conexión.

Añadir GPS tardío, precisión mayor a `35 m`, timestamp fuera de orden, salto
imposible y cambio de fecha sin doble conteo.

- [ ] **Step 2: Run the new tests and verify failure**

Run:
`flutter test test/map_route_graph_test.dart test/map_navigation_controller_test.dart test/daily_walking_tracker_test.dart`

Expected: FAIL because native classes are absent.

- [ ] **Step 3: Implement A* and route projection in Dart**

Usar IDs estables, pesos Haversine y tolerancia de ajuste `35 m`. No trazar
línea directa si el punto no conecta con la red.

- [ ] **Step 4: Implement navigation and daily tracking**

Recalcular después de dos muestras consecutivas a más de `15 m` de la ruta;
radio de llegada `max(6, min(accuracy,15))`; no sumar segmentos con muestra
rechazada ni mayores a la velocidad peatonal permitida por el filtro vigente.

- [ ] **Step 5: Rerun routing and location tests**

Run:
`flutter test test/map_route_graph_test.dart test/map_navigation_controller_test.dart test/daily_walking_tracker_test.dart test/map_location_controller_test.dart`

Expected: all PASS.

- [ ] **Step 6: Checkpoint without committing**

Run: `git diff --check && git status --short`

---

### Task 5: Map view model, search, filters, zoom visibility, and nearby list

**Files:**
- Create: `lib/map/map_view_model.dart`
- Create: `lib/map/map_connectivity_monitor.dart`
- Test: `test/map_view_model_test.dart`
- Test: `test/map_connectivity_monitor_test.dart`
- Modify: `test/map_filter_test.mjs` only if it references runtime behavior that
  is now owned by Dart.

**Interfaces:**
- Produces: `MapCategory`, `MapViewState`, `MapViewModel.selectPlace`,
  `setSearch`, `setCategory`, `setZoom`, `setConnectivity`,
  `visiblePlaces`, `nearbyPlaces` and `fitBoundsPoints`;
  `MapConnectivityMonitor.check() -> Future<bool>` con un
  `HostResolver.resolve(String host)` inyectable.
- Consumes: initialized `MapDocumentController` and optional current `GeoPoint`.

- [ ] **Step 1: Write failing state tests**

Probar que los tres escenarios destacados aparecen en la vista inicial, puntos
secundarios aparecen al acercar o filtrar, búsqueda ignora tildes/mayúsculas,
selección siempre permanece visible y modo sin red ordena cercanos por metros.
Añadir monitor con DNS disponible, error y timeout de tres segundos; el timeout
debe producir `false` sin lanzar al widget.

- [ ] **Step 2: Run and verify failure**

Run:
`flutter test test/map_view_model_test.dart test/map_connectivity_monitor_test.dart`

Expected: FAIL because `MapViewModel` does not exist.

- [ ] **Step 3: Implement immutable view state**

Umbrales iniciales: destacados siempre; servicios y atracciones desde zoom
`18.0`; zonas desde `18.8`; una categoría seleccionada ignora esos umbrales.
Cada cambio notifica una sola vez.

Implementar el monitor con `InternetAddress.lookup('maps.googleapis.com')`,
timeout de tres segundos, comprobación solo al entrar/reanudar y botón de
reintento; no usarlo para afirmar que una petición futura está garantizada.

- [ ] **Step 4: Rerun the test**

Run:
`flutter test test/map_view_model_test.dart test/map_connectivity_monitor_test.dart`

Expected: PASS.

- [ ] **Step 5: Checkpoint without committing**

Run: `git diff --check && git status --short`

---

### Task 6: Native Google Map screen and brand interface

**Files:**
- Create: `lib/map/map_screen.dart`
- Create: `lib/map/map_screen_controller.dart`
- Create: `lib/map/widgets/map_search_filters.dart`
- Create: `lib/map/widgets/map_navigation_card.dart`
- Create: `lib/map/widgets/map_place_sheet.dart`
- Modify: `lib/main.dart`
- Test: `test/map_screen_test.dart`
- Test: `test/map_screen_controller_test.dart`
- Modify: `test/product_surfaces_test.dart`
- Modify: `test/app_navigation_test.dart`

**Interfaces:**
- Produces: `MapScreen(active, programming, mapDocument, session,
  locationController?, mapBuilder?)`; `MapCanvasModel` containing camera,
  markers, polylines and circles; injectable `MapCanvasBuilder` for tests;
  `MapScreenController` como coordinador puro del estado de pantalla.
- Consumes: Tasks 1–5 controllers and `ProgrammingController`.

- [ ] **Step 1: Write failing widget tests with an injected fake canvas**

Verificar: mapa ocupa el espacio disponible; búsqueda compacta; tres destacados;
selección abre tarjeta; escenario muestra programación; `Ver todo` y
`Mi ubicación`; estado sin clave; estado sin red conserva lista y acciones; no
aparece texto ni imagen del plano PDF.

- [ ] **Step 2: Run and verify failure**

Run:
`flutter test test/map_screen_test.dart test/map_screen_controller_test.dart test/product_surfaces_test.dart test/app_navigation_test.dart`

Expected: FAIL because the native screen contract is absent.

- [ ] **Step 3: Extract `MapScreen` from `main.dart`**

Retirar la clase WebView embebida, importar el nuevo archivo y pasar
`AccessSession` desde `RootShell`. Conservar `ExternalDirectionsScreen` para la
ruta hacia el acceso externo.

- [ ] **Step 4: Implement the production Google canvas**

Construir `GoogleMap` con `MapType.hybrid`, centro del recinto, zoom inicial
`17.6`, zoom mínimo `15`, zoom máximo `21`, gestos activados, ubicación nativa
oculta y controles propios accesibles. Convertir `MapCanvasModel` a
`Marker`, `Polyline` y `Circle`.

- [ ] **Step 5: Implement compact overlays and branded marker bitmaps**

Usar los colores corporativos, etiquetas persistentes solo para los tres
escenarios y tamaños táctiles mínimos de `44x44`. Evitar tarjetas que cubran más
del tercio inferior salvo cuando el usuario abra detalle.

- [ ] **Step 6: Implement recoverable missing-key and offline states**

Sin configuración, mostrar `Falta configurar el mapa` con instrucciones breves.
Sin red, mantener controles, selección y lista cercana; no mostrar el PDF.

- [ ] **Step 7: Rerun widget tests**

Run:
`flutter test test/map_screen_test.dart test/map_screen_controller_test.dart test/product_surfaces_test.dart test/app_navigation_test.dart`

Expected: all PASS.

- [ ] **Step 8: Checkpoint without committing**

Run: `git diff --check && git status --short`

---

### Task 7: Live GPS, camera behavior, route rendering, and lifecycle

**Files:**
- Modify: `lib/map/map_screen.dart`
- Modify: `lib/map/map_screen_controller.dart`
- Modify: `lib/map/map_view_model.dart`
- Modify: `lib/map/map_location_controller.dart`
- Modify: `test/map_screen_test.dart`
- Modify: `test/map_location_controller_test.dart`
- Modify: `test/map_navigation_controller_test.dart`

**Interfaces:**
- Produces: `MapScreenController.onLocation`, `startRoute`, `stopRoute`,
  `recenter`, `fitVenue`; `MapCanvasModel.userCircle`, completed/remaining
  route polylines and camera command.
- Consumes: location stream, navigation and walking controllers.

- [ ] **Step 1: Add failing lifecycle and route-display tests**

Cubrir inicio al activar pestaña, detención al salir, muestra aceptada que mueve
el punto y actualiza metros, muestra rechazada que no mueve ni suma, usuario que
explora sin recentrado forzado, ruta activa que sigue posición y llegada que
finaliza una sola vez.

- [ ] **Step 2: Run and verify failure**

Run:
`flutter test test/map_screen_test.dart test/map_location_controller_test.dart test/map_navigation_controller_test.dart`

Expected: new cases FAIL.

- [ ] **Step 3: Wire accepted GPS samples to state**

Representar la exactitud con `Circle.radius=accuracy`; mostrar `± n m`; enviar
solo muestras aceptadas al recorrido y navegación.

- [ ] **Step 4: Render progress and camera commands**

Ruta restante vino, completada dorada, ancho legible a cualquier zoom. Recentrar
solo por acción del usuario, inicio de ruta o seguimiento activo.

- [ ] **Step 5: Rerun focused tests**

Run:
`flutter test test/map_screen_test.dart test/map_location_controller_test.dart test/map_navigation_controller_test.dart test/daily_walking_tracker_test.dart`

Expected: all PASS.

- [ ] **Step 6: Checkpoint without committing**

Run: `git diff --check && git status --short`

---

### Task 8: Role-gated native admin editor and local recovery

**Files:**
- Modify: `lib/account/account_session.dart`
- Modify: `lib/auth/access_flow.dart`
- Create: `lib/map/map_admin_controller.dart`
- Create: `lib/map/widgets/map_admin_sheet.dart`
- Modify: `lib/map/map_screen.dart`
- Modify: `lib/map/map_document_controller.dart`
- Test: `test/map_admin_controller_test.dart`
- Test: `test/map_admin_screen_test.dart`
- Modify: `test/onboarding_flow_test.dart`

**Interfaces:**
- Produces: `AccessRole.visitor/admin`, `AccessSession.isAdmin`;
  `MapAdminController.createPlace`, `movePlace`, `updatePlace`, `hidePlace`,
  `updateEvents`, `restoreBackup`; admin marker drag callbacks.
- Consumes: validated store and schema from Tasks 2–3.

- [ ] **Step 1: Write failing authorization and mutation tests**

Probar rol visitante y cuenta normal sin controles; email mock administrativo
con rol admin; llamada directa de visitante rechazada; crear; mover; ocultar;
editar evento; documento inválido sin guardado; restaurar respaldo; reinicio
conserva cambio.

- [ ] **Step 2: Run and verify failure**

Run:
`flutter test test/map_admin_controller_test.dart test/map_admin_screen_test.dart test/onboarding_flow_test.dart`

Expected: FAIL because native admin contracts are absent.

- [ ] **Step 3: Add explicit local roles**

`AccessSession` recibe `role`, por defecto visitante. El acceso local de
`admin@mushucruna.demo` asigna `AccessRole.admin`; ninguna otra coincidencia de
nombre o proveedor eleva permisos.

- [ ] **Step 4: Implement guarded mutations**

Cada método recibe o conserva la sesión autorizada, valida el documento completo,
actualiza `updatedAt`, respalda y persiste. `hidePlace` sustituye borrar.

- [ ] **Step 5: Implement the admin interface on the same map**

Botón solo para admin, pulsación larga confirmada para crear, modo Mover que
activa `draggable`, inspector para nombre/categoría/visibilidad/relevancia y
editor de eventos. Salir del modo desactiva todos los arrastres.

- [ ] **Step 6: Rerun admin tests**

Run:
`flutter test test/map_admin_controller_test.dart test/map_admin_screen_test.dart test/onboarding_flow_test.dart test/map_document_store_test.dart`

Expected: all PASS.

- [ ] **Step 7: Checkpoint without committing**

Run: `git diff --check && git status --short`

---

### Task 9: Programming and Runi geographic integration

**Files:**
- Modify: `lib/runi/runi_recommender.dart`
- Modify: `lib/main.dart`
- Modify: `lib/map/map_screen.dart`
- Modify: `test/runi_recommender_test.dart`
- Modify: `test/map_screen_test.dart`
- Modify: `test/product_surfaces_test.dart`

**Interfaces:**
- Produces: `RuniPlaceOverride(latitude,longitude)`; continuity score based on
  `MapGeo.distanceMeters`; map selection by recommendation place ID.
- Consumes: `MapPlace.point`, `venue`, `ProgrammingController` and map selection.

- [ ] **Step 1: Write failing geographic Runi tests**

Actualizar la prueba de lugar administrado a latitud/longitud; probar que mover
un lugar cambia continuidad de forma determinista, que ocultarlo elimina eventos
y que nunca reaparecen Tren o Trasbordo.

- [ ] **Step 2: Run and verify failure**

Run:
`flutter test test/runi_recommender_test.dart test/map_screen_test.dart`

Expected: FAIL because overrides still use `x/y`.

- [ ] **Step 3: Replace Runi coordinates and scale continuity in meters**

Usar Haversine y normalizar continuidad a la escala peatonal del recinto, sin
cambiar pesos de perfil, horario, afluencia o variedad.

- [ ] **Step 4: Connect recommendations and programming to map selection**

Una recomendación selecciona el mismo `MapPlace` que un marcador; escenario abre
la programación vigente; cambios admin notifican a ambos controladores.

- [ ] **Step 5: Rerun integration tests**

Run:
`flutter test test/runi_recommender_test.dart test/map_screen_test.dart test/product_surfaces_test.dart`

Expected: all PASS.

- [ ] **Step 6: Checkpoint without committing**

Run: `git diff --check && git status --short`

---

### Task 10: Retire the illustrated runtime, verify both platforms, and perform visual acceptance

**Files:**
- Modify: `pubspec.yaml`
- Modify: obsolete JS assertions in `test/map_admin_editor_test.mjs`
- Modify: `AGENTS.md`
- Keep unbundled for reference: `assets/map/index.html`, supporting JS/CSS and
  `assets/map/mushuc_runa_validated.svg`

**Interfaces:**
- Consumes: all previous tasks.
- Produces: final mobile map implementation and verification record.

- [ ] **Step 1: Write the final regression assertions**

Assert that `pubspec.yaml` no longer bundles `assets/map/index.html` or
`mushuc_runa_validated.svg`, `MapScreen` does not construct a WebView, the PDF
name is absent from visitor strings and `MapType.hybrid` remains configured.

- [ ] **Step 2: Run the regression assertions and verify they fail before cleanup**

Run:
`flutter test test/product_surfaces_test.dart test/map_screen_test.dart`

Expected: cleanup-specific case FAIL.

- [ ] **Step 3: Remove legacy map assets from the Flutter bundle**

Retirar las entradas HTML/JS/CSS/SVG del bloque `assets` sin borrar los archivos
de referencia. Mantener `webview_flutter` porque
`ExternalDirectionsScreen` todavía lo usa.

- [ ] **Step 4: Format and run the full automated suite**

Run:

```bash
dart format lib test tool
flutter analyze --no-pub
flutter test
node test/map_geometry_test.mjs
node test/walking_navigation_test.mjs
node test/location_tracker_test.mjs
```

Expected: formatter clean; analyzer `No issues found`; all Flutter tests PASS;
legacy algorithm comparison tests PASS until they are formally retired.

- [ ] **Step 5: Build Android and iOS without exposing a key**

Run:

```bash
flutter build apk --debug
flutter build ios --simulator --debug --no-codesign
```

Expected: both builds succeed with local ignored configuration or empty local
placeholders; no key appears in console or `git diff`.

- [ ] **Step 6: Configure restricted local keys outside Git**

Alex introduce las claves de Android e iOS mediante los archivos ignorados. No
leerlas ni imprimirlas. Ejecutar con
`--dart-define=GOOGLE_MAPS_CONFIGURED=true`.

- [ ] **Step 7: Run simulator field-flow acceptance**

En iPhone y Android: abrir Mapa; comprobar satélite; arrastre en ambos ejes;
pinch; tres escenarios; seleccionar Plaza de la Luna; iniciar ruta a
Megaescenario; simular movimiento; confirmar metros restantes, recorrido y
recalculo; probar escenario/programación; entrar como visitante y admin; mover un
punto; reiniciar y confirmar persistencia.

- [ ] **Step 8: Inspect the final worktree**

Run:

```bash
git diff --check
git status --short
git diff --stat
rg -n 'AIza|GOOGLE_MAPS_API_KEY=.+' . \
  --glob '!build/**' --glob '!.dart_tool/**' --glob '!*.example'
```

Expected: no whitespace errors; no real key; `.superpowers/` remains untracked or
excluded; only intended app and documentation changes.

- [ ] **Step 9: Update project continuity without committing**

Mover `park-real-map-redesign-20261008` de Trabajo activo a Registro de trabajo
en `/Users/afnaranjo/traiding/AGENTS.md`, detallando archivos, pruebas, carencia
o presencia de claves sin valores, riesgos y siguiente paso. No commit ni push.
