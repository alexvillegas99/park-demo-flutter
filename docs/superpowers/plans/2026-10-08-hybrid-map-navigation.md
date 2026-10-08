# Hybrid Map Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convertir el mapa de Mushuc Runa en un navegador peatonal local que use el plano validado, muestre ubicación en vivo, trace rutas internas, mida recorrido estimado y mantenga sincronizados los puntos administrativos con Runi.

**Architecture:** El WebView conserva la presentación cartográfica, pero su lógica se divide en módulos JavaScript puros: geometría, lugares, grafo peatonal, navegación y seguimiento. Flutter administra permisos y ciclo de vida de ubicación, recibe el documento de lugares y abre las indicaciones exteriores en una pantalla interna. El documento administrativo sube a esquema 3 porque el plano oficial usa coordenadas distintas.

**Tech Stack:** Flutter/Dart, `webview_flutter`, `geolocator`, `url_launcher`, HTML/CSS/SVG, JavaScript sin dependencias, pruebas `flutter_test` y Node `assert`.

**Spec:** `docs/superpowers/specs/2026-10-08-hybrid-map-navigation-design.md`

## Global Constraints

- Trabajar únicamente en `/Users/afnaranjo/traiding/park-demo-flutter`; no crear otra copia ni otro worktree.
- Conservar los cambios locales existentes y no incluir `.superpowers/` en la app.
- No implementar backend, Google Maps SDK, Navigation SDK ni ubicación en segundo plano.
- El seguimiento funciona solo mientras la pestaña `Mapa` está visible.
- No mostrar categoría, filtro ni puntos de trasbordo; el documento v2 los conserva solo como respaldo histórico y la migración a v3 los excluye.
- La navegación interna y el plano deben funcionar sin internet después de instalar la app.
- Usar los umbrales exactos de la especificación: 10 s, 35 m, 20 m, 2 m, 3,5 m/s, 15 m por dos muestras, 35 m de conexión y radio `max(6 m, min(precisión, 15 m))`.
- La interfaz comunica `Recorrido estimado` y `≈`; nunca promete precisión de 1 m.
- Los datos locales migran de `mr_map_document_v2` a `mr_map_document_v3` sin sobrescribir la versión 2.
- Las credenciales administrativas actuales siguen siendo demostrativas; no presentarlas como seguridad real.
- No hacer commit ni push salvo solicitud explícita de Alex. Al final de cada tarea, revisar el diff y ejecutar sus pruebas dirigidas.
- Todo texto nuevo usa español latino neutro con `tú`, sin voseo.

## Review Focus

- Documento v2 corrupto, antiguo o parcialmente personalizado: conservar la última versión válida, no borrar eventos y marcar coordenadas proyectadas como `Revisar ubicación` (Task 2).
- Muestras GPS antiguas, duplicadas, imprecisas o fuera de orden: no mover la ruta de forma errática ni sumar metros falsos (Task 4).
- Punto administrativo oculto o a más de 35 m de la red: excluirlo de Runi y no inventar una conexión peatonal (Tasks 3 y 7).
- Coordenada exterior sin internet o redirección a un esquema externo: mantener orientación aproximada y pedir una acción explícita antes de salir de la app (Task 6).
- Recarga del WebView y cambios repetidos de pestaña: no duplicar streams, callbacks, metros ni documentos (Tasks 2, 5 y 6).

---

## File Map

**Create**

- `assets/map/mushuc_runa_validated.svg` — exportación del PDF oficial con el área cartográfica como `viewBox`.
- `assets/map/map_geometry.js` — transformación reversible entre latitud/longitud, plano v3 y plano legado.
- `assets/map/map_places.js` — posiciones oficiales v3, posiciones base v2, leyenda validada y `recommendationId` estables.
- `assets/map/route_graph.js` — nodos y aristas peatonales versionados.
- `assets/map/walking_navigation.js` — A*, ajuste a red y sesión de navegación.
- `assets/map/location_tracker.js` — validación de muestras y recorrido diario.
- `lib/map/map_document_controller.dart` — documento validado compartido por mapa y Runi.
- `lib/map/map_location_controller.dart` — permisos, stream visible y estado interior/exterior.
- `lib/map/external_directions_screen.dart` — Google Maps web dentro de la app y salida externa explícita.
- `test/map_geometry_test.mjs`, `test/walking_navigation_test.mjs`, `test/location_tracker_test.mjs`.
- `test/map_document_controller_test.dart`, `test/map_location_controller_test.dart`, `test/external_directions_test.dart`.

**Modify**

- `assets/map/index.html:1-1020` — composición, módulos, estado GPS, rutas y administración.
- `assets/map/map_filter.js:20-66` — encuadre contener/llenar y límites de desplazamiento.
- `assets/map/admin_editor.js:1-364` — esquema v3, migración, marca de revisión y emisiones.
- `assets/map/admin_editor.css` — estados de sincronización y advertencias.
- `lib/main.dart:1060-1175,2999-3290` — controladores compartidos, canales WebView y ciclo de vida.
- `lib/runi/runi_recommender.dart:1-620` — coordenadas/visibilidad administradas.
- `pubspec.yaml:55-64` — nuevos activos del mapa.
- `test/map_filter_test.mjs`, `test/map_admin_editor_test.mjs`, `test/map_geolocation_test.dart`, `test/runi_recommender_test.dart`, `test/app_navigation_test.dart`.
- `/Users/afnaranjo/traiding/AGENTS.md` — bitácora al finalizar.

---

### Task 1: Plano oficial, geometría v3 y viewport completo

**Files:**
- Create: `assets/map/mushuc_runa_validated.svg`
- Create: `assets/map/map_geometry.js`
- Create: `assets/map/map_places.js`
- Create: `test/map_geometry_test.mjs`
- Modify: `assets/map/map_filter.js:20-66`
- Modify: `test/map_filter_test.mjs:53-68`
- Modify: `pubspec.yaml:55-64`

**Interfaces:**
- Produces: `globalThis.MapGeometryV3` con `width`, `height`, `toMap(lat, lng)`, `toLatLng(x, y)`, `distanceMeters(a, b)` y `migrateLegacyPoint(point, legacySeed, officialSeed)`.
- Produces: `globalThis.MR_MAP_PLACES_V3`, `globalThis.MR_LEGACY_PLACES_V2` y `globalThis.MR_MAP_LEGEND_V1`.
- Produces: `MapViewModel.fit(viewportWidth, viewportHeight, mode)`, donde `mode` es `'contain'` o `'fill'`, y `clamp(offset, contentSize, viewportSize, margin = 0)`.

- [ ] **Step 1: Escribir las pruebas fallidas de geometría y encuadre**

En `test/map_geometry_test.mjs`, comprobar ida/vuelta de los cuatro accesos y un punto interior, error de retorno menor que `1e-7` grados, distancia simétrica, migración diferenciada entre punto estándar intacto y punto movido, presencia de las secciones de leyenda y ausencia de `href` HTTP externo en el SVG. En `test/map_filter_test.mjs`, cambiar la expectativa actual de cobertura: `fit(430, 932, 'contain')` debe contener ambos ejes y centrar el sobrante; tras ampliar, `clamp` debe permitir desplazamiento horizontal y vertical sin perder todo el plano.

- [ ] **Step 2: Ejecutar las pruebas y confirmar el fallo esperado**

Run: `node test/map_geometry_test.mjs && node test/map_filter_test.mjs`

Expected: FAIL porque `map_geometry.js`, los lugares v3 y el modo `contain` todavía no existen.

- [ ] **Step 3: Exportar el PDF oficial sin alterar la fuente**

Run: `pdftocairo -svg '/Users/afnaranjo/Downloads/mapa vectorizado final ACCESOS.pdf' assets/map/mushuc_runa_validated.svg`

Ajustar únicamente `width`, `height` y `viewBox` del SVG exportado para excluir la leyenda lateral izquierda y la franja decorativa inferior, conservando los seis accesos y la leyenda operativa derecha. Mantener el PDF original intacto y verificar que el SVG no contiene enlaces de red.

- [ ] **Step 4: Implementar `MapGeometryV3` y los lugares versionados**

Usar un lienzo lógico fijo de `1600 × 1327`. Guardar los cuatro controles de acceso y un control interior en `map_geometry.js`; resolver e invertir la transformación afín. Verificar los controles contra la vista satelital georreferenciada vigente y registrar el error del punto interior retenido; si excede 15 m, la UI mantiene lenguaje aproximado y la bitácora deja pendiente la calibración física. En `map_places.js`, trasladar los puntos estándar a ubicaciones verificadas contra el SVG, excluir todos los puntos `trans`, reproducir la leyenda aplicable como datos locales y añadir `recommendationId` a los nueve lugares usados por Runi. `migrateLegacyPoint` debe devolver `{x, y, needsReview}`: usa la posición oficial si el punto coincide con su semilla v2 dentro de 1 px; proyecta y marca revisión cuando fue movido o es personalizado.

- [ ] **Step 5: Implementar `contain`, `fill` y límites con margen**

`contain` usa `Math.min(viewportWidth / width, viewportHeight / height)`; `fill` usa `Math.max(...)`. El zoom mínimo es el encuadre `contain`, el máximo continúa en `8`, y el margen de arrastre no puede dejar menos de 48 px del plano visibles.

- [ ] **Step 6: Registrar los activos y ejecutar las pruebas**

Añadir el SVG y los nuevos `.js` a `pubspec.yaml`. Run: `node test/map_geometry_test.mjs && node test/map_filter_test.mjs && git diff --check`.

Expected: ambas pruebas imprimen `ok`; el diff nuevo no introduce errores de espacios.

---

### Task 2: Documento administrativo v3 y sincronización con Flutter

**Files:**
- Create: `lib/map/map_document_controller.dart`
- Create: `test/map_document_controller_test.dart`
- Modify: `assets/map/admin_editor.js:1-364`
- Modify: `test/map_admin_editor_test.mjs:1-220`
- Modify: `assets/map/index.html:303-380,490-505,840-980`
- Modify: `assets/map/admin_editor.css`

**Interfaces:**
- Consumes: `MapGeometryV3.migrateLegacyPoint`, `MR_MAP_PLACES_V3`, `MR_LEGACY_PLACES_V2` de Task 1.
- Produces JS: `new MapAdminDocument(seedV3, storage, {legacySeed, migratePoint, onChange})`, `applyExternalDocument(value)` y `exportObject()` con esquema 3.
- Produces Dart: `MapPlace`, `MapDocumentSnapshot.parse(Object?)`, y `MapDocumentController.acceptJson(String) -> bool`, `toJson()`, `List<MapPlace> get visiblePlaces`, `List<MapPlace> get visibleRecommendationPlaces`.

- [ ] **Step 1: Escribir pruebas fallidas de migración, emisión y validación**

En Node, sembrar `mr_map_document_v2` con un punto intacto, uno movido, uno personalizado y eventos. Afirmar que v3 conserva metadatos, deja v2 intacto, usa coordenada oficial para el intacto, marca los otros `needsReview`, emite después de cargar/crear/mover/deshacer/editar/importar/restaurar y no emite un documento inválido. En Dart, comprobar rechazo de esquema incorrecto, JSON corrupto, fecha más antigua o igual, coordenada fuera del lienzo y recepción repetida tras recargar; comprobar que el documento válido reemplaza el anterior una sola vez y excluye ocultos.

- [ ] **Step 2: Ejecutar y confirmar fallos**

Run: `node test/map_admin_editor_test.mjs && flutter test --no-pub test/map_document_controller_test.dart`

Expected: FAIL por ausencia del esquema 3, callback `onChange` y controlador Dart.

- [ ] **Step 3: Implementar la migración no destructiva en JavaScript**

Cambiar a `MAP_DOCUMENT_SCHEMA_VERSION = 3`, `mr_map_document_v3` y respaldo v3. Leer v2 solo cuando no haya v3 válido; nunca escribir sobre v2. Persistir `updatedAt` como estado del documento, no regenerarlo al consultar. Validar `needsReview` y `recommendationId`. Ejecutar `onChange(clone(exportObject()))` una sola vez por escritura válida.

- [ ] **Step 4: Implementar el puente del documento**

En HTML, crear `notifyFlutterMapDocument(document)` y `window.setMapDocumentFromFlutter(document)`. La recepción externa aplica únicamente documentos más nuevos y válidos. Mostrar `Cambios aplicados en la app` tras la confirmación local y `Revisar ubicación` en puntos migrados que requieren validación.

- [ ] **Step 5: Implementar `MapDocumentController`**

El controlador valida esquema, `updatedAt`, límites `1600 × 1327`, identificadores únicos y listas. `acceptJson` devuelve `false` sin mutar ante cualquier error o documento más antiguo. Notifica una vez por reemplazo y expone copias inmutables.

- [ ] **Step 6: Ejecutar las pruebas dirigidas**

Run: `node test/map_admin_editor_test.mjs && flutter test --no-pub test/map_document_controller_test.dart && git diff --check`.

Expected: Node imprime `map_admin_editor_test: ok`; Flutter pasa todas las pruebas del controlador.

---

### Task 3: Grafo peatonal y motor A*

**Files:**
- Create: `assets/map/route_graph.js`
- Create: `assets/map/walking_navigation.js`
- Create: `test/walking_navigation_test.mjs`
- Modify: `pubspec.yaml:55-70`

**Interfaces:**
- Consumes: `MapGeometryV3.distanceMeters` y las coordenadas v3 de Task 1.
- Produces: `globalThis.MR_ROUTE_GRAPH_V1 = {version, nodes, edges}`.
- Produces: `WalkingRouteGraph.snap(point, toleranceMeters)`, `route(origin, destination)`, `distanceToRoute(point, polyline)`.
- Produces: `WalkingNavigationSession.start(origin, destination)`, `update(sample)` y `finish()`; el estado contiene `polyline`, `completedPolyline`, `totalMeters`, `remainingMeters`, `progress`, `arrived`, `offRouteCount` y `accessId`.

- [ ] **Step 1: Escribir pruebas fallidas del grafo**

Comprobar que los seis accesos, Plaza del Sol, Plaza de la Luna, Megaescenario, Mushuc Park y patios de comida se conectan a menos de 35 m; que todos pertenecen al mismo componente; que Luna → Mega devuelve al menos tres coordenadas, distancia no menor que la directa y extremos correctos; que un destino a más de 35 m devuelve advertencia; que una muestra desviada no recalcula y dos muestras a más de 15 m sí; que el radio de llegada se limita entre 6 y 15 m.

- [ ] **Step 2: Ejecutar y confirmar el fallo**

Run: `node test/walking_navigation_test.mjs`

Expected: FAIL porque el grafo y el motor no existen.

- [ ] **Step 3: Trazar y versionar la red validada**

Trazar los corredores caminables visibles del SVG, incluyendo conexiones a los seis accesos y destinos principales. Cada nodo usa `{id, x, y}` y cada arista `{from, to}`; el peso se calcula con `MapGeometryV3.distanceMeters`, no con píxeles. No conectar atravesando stands, canchas, cercas ni zonas verdes cerradas.

- [ ] **Step 4: Implementar A* y ajuste a red**

Usar distancia métrica al destino como heurística. `snap` devuelve error tipado cuando excede 35 m. La polilínea incluye origen, nodos y destino ajustado; la distancia restante se calcula sobre el tramo no recorrido, no como línea recta.

- [ ] **Step 5: Implementar la sesión de navegación**

Mantener dos contadores consecutivos de desvío, recalcular solo en el segundo, cortar el tramo recorrido por la proyección más cercana y marcar llegada con `max(6, min(accuracy, 15))`.

- [ ] **Step 6: Ejecutar pruebas y registrar activos**

Run: `node test/walking_navigation_test.mjs && git diff --check`.

Expected: `walking_navigation_test: ok`; el grafo queda incluido en `pubspec.yaml`.

---

### Task 4: Filtro GPS y recorrido diario estimado

**Files:**
- Create: `assets/map/location_tracker.js`
- Create: `test/location_tracker_test.mjs`
- Modify: `pubspec.yaml:55-72`

**Interfaces:**
- Produces: `LocationSampleFilter.evaluate(sample, previous, nowMs)` con `{routeAccepted, walkAccepted, reason, deltaMeters}`.
- Produces: `DailyWalkTracker.update(sample, nowMs)`, `snapshot()` y `resetForDate(localDate)` usando `mr_walk_day_v1`.
- Sample exacto: `{lat, lng, x, y, accuracy, timestamp, inside}`.

- [ ] **Step 1: Escribir las pruebas fallidas de los umbrales**

Cubrir muestra de 11 s, precisión de 36 m para ruta, 21 m para recorrido, movimiento de 1,9 m, velocidad de 3,6 m/s, duplicado idéntico, timestamp anterior, muestra exterior y una secuencia válida de 2 m o más. Comprobar que la fecha local persiste durante el día y reinicia al día siguiente sin arrastrar la última muestra.

- [ ] **Step 2: Ejecutar y confirmar el fallo**

Run: `node test/location_tracker_test.mjs`

Expected: FAIL porque `location_tracker.js` no existe.

- [ ] **Step 3: Implementar evaluación pura y almacenamiento inyectable**

Aceptar `storage` y reloj como dependencias de constructor para pruebas deterministas. Una muestra puede servir para ruta con precisión entre 20 y 35 m, pero no suma recorrido. No actualizar la última muestra acumulable por ruido menor de 2 m, duplicado, salto o dato exterior.

- [ ] **Step 4: Ejecutar las pruebas**

Run: `node test/location_tracker_test.mjs && git diff --check`.

Expected: `location_tracker_test: ok`.

---

### Task 5: Integración visual del navegador dentro del WebView

**Files:**
- Modify: `assets/map/index.html:1-1020`
- Modify: `assets/map/map_filter.js`
- Modify: `assets/map/admin_editor.css`
- Modify: `test/map_filter_test.mjs`
- Modify: `test/map_admin_editor_test.mjs`

**Interfaces:**
- Consumes: todos los módulos JavaScript de Tasks 1–4.
- Produces: `window.setMapLocationSample(sample)`, `window.setMapLocationError(code, message)`, `window.setMapDocumentFromFlutter(document)` y `window.stopMapTracking()`.
- Emits: `FlutterMapDocument.postMessage(json)` y `FlutterDirections.postMessage(json)`.

- [ ] **Step 1: Añadir aserciones HTML fallidas**

Exigir referencias a los cinco módulos nuevos y al SVG externo; ausencia de la imagen base64 antigua; dos paths SVG `routeCompleted` y `routeRemaining`; banda con `Precisión` y `Recorrido estimado`; acciones `Ver todo`, `Recentrar`, `Iniciar ruta` y `Finalizar`; canales `FlutterMapDocument` y `FlutterDirections`; leyenda bajo demanda.

- [ ] **Step 2: Ejecutar pruebas y confirmar el fallo**

Run: `node test/map_filter_test.mjs && node test/map_admin_editor_test.mjs`

Expected: FAIL por ausencia de la nueva estructura.

- [ ] **Step 3: Sustituir el lienzo sin duplicar la app**

Eliminar la imagen JPEG base64 del HTML y usar `mushuc_runa_validated.svg` como única base. Inicializar el mundo en `contain`, conservar zoom/pinza y permitir desplazamiento en ambos ejes. Mantener búsqueda, filtros, puntos y panel administrativo existentes con la línea gráfica vino, dorado, marfil y verde.

- [ ] **Step 4: Integrar ubicación, ruta y recorrido**

`setMapLocationSample` transforma la muestra, elimina inmediatamente el marcador interior cuando `inside === false`, alimenta filtro/contador/sesión y actualiza precisión, metros diarios, restante, progreso y tramo dorado. La ficha muestra distancia directa con `≈` antes de iniciar ruta y distancia por grafo después.

- [ ] **Step 5: Integrar estados exterior, sin red y punto sin conexión**

Para exterior, seleccionar el acceso de menor distancia métrica, mostrar distancia aproximada y enviar sus coordenadas a `FlutterDirections` solo al pulsar `Cómo llegar`. Para punto a más de 35 m de la red, mostrar advertencia y no dibujar línea recta como si fuera ruta.

- [ ] **Step 6: Integrar administración y accesibilidad**

Toda mutación usa el documento v3 y conserva el marcador visitante. Los tres escenarios siguen siendo marcadores grandes. Añadir roles, nombres accesibles y foco a controles nuevos; la leyenda no puede bloquear el botón de cierre ni la navegación inferior.

- [ ] **Step 7: Ejecutar las suites JavaScript**

Run: `node test/map_geometry_test.mjs && node test/map_filter_test.mjs && node test/map_admin_editor_test.mjs && node test/walking_navigation_test.mjs && node test/location_tracker_test.mjs`.

Expected: las cinco suites imprimen `ok`.

---

### Task 6: Ciclo de vida Flutter y direcciones exteriores dentro de la app

**Files:**
- Create: `lib/map/map_location_controller.dart`
- Create: `lib/map/external_directions_screen.dart`
- Create: `test/map_location_controller_test.dart`
- Create: `test/external_directions_test.dart`
- Modify: `lib/main.dart:2999-3290`
- Modify: `test/map_geolocation_test.dart`
- Modify: `test/app_navigation_test.dart`

**Interfaces:**
- Produces: `MapLocationSample(latitude, longitude, accuracy, timestamp, inside)`.
- Produces: `abstract interface class MapPositionSource` con `ensurePermission()`, `watch()` y `stop()`.
- Produces: `MapLocationController.setActive(bool)` y stream `updates` sin suscripciones duplicadas.
- Produces: `ExternalDirectionsUri.googleWalking(destinationLat, destinationLng)` y `ExternalDirectionsScreen`.
- Consumes: `window.setMapLocationSample`, `window.setMapLocationError` y `FlutterDirections` de Task 5.

- [ ] **Step 1: Escribir pruebas fallidas del ciclo de vida**

Con un `FakeMapPositionSource`, comprobar que página lista + pestaña inactiva no inicia; activar inicia una vez; activar otra vez no duplica; desactivar cancela; reactivar crea una sola suscripción nueva; una muestra exterior se emite con `inside=false`. Mantener precisión `bestForNavigation` y `distanceFilter=1` como solicitud al sistema.

- [ ] **Step 2: Escribir pruebas fallidas de URL y navegación segura**

Comprobar URL HTTPS con `api=1`, destino codificado y `travelmode=walking`; aceptar únicamente hosts Google Maps permitidos dentro del WebView; bloquear `comgooglemaps:`, `intent:`, `maps:` y otros esquemas; ante error de red conservar la pantalla de orientación y exponer `Abrir en navegador` solo como acción del usuario, sin invocar `url_launcher` automáticamente.

- [ ] **Step 3: Ejecutar y confirmar fallos**

Run: `flutter test --no-pub test/map_location_controller_test.dart test/external_directions_test.dart test/map_geolocation_test.dart test/app_navigation_test.dart`

Expected: FAIL porque los controladores y la pantalla no existen.

- [ ] **Step 4: Implementar el controlador de ubicación**

Encapsular Geolocator detrás de `MapPositionSource`. Calcular `inside` respecto a `FairLocation` sin descartar muestras exteriores. Cancelar stream al ocultar mapa o disponer el controlador. Traducir permiso denegado, servicio apagado y error del stream a estados explícitos.

- [ ] **Step 5: Reemplazar el puente de geolocalización del navegador**

`MapScreen` recibe actualizaciones del controlador y ejecuta JSON serializado con `jsonEncode`; no interpolar texto sin escapar. Al cambiar `active`, iniciar o detener tanto Dart como JavaScript. En `onPageFinished`, inyectar programación y el documento vigente una sola vez.

- [ ] **Step 6: Implementar direcciones web internas**

Al recibir `FlutterDirections`, validar latitud/longitud/nombre y abrir `ExternalDirectionsScreen`. Mantener la navegación HTTPS dentro del WebView. Si falla o intenta un esquema externo, mostrar el estado de error y el botón explícito que usa `url_launcher`.

- [ ] **Step 7: Ejecutar las pruebas Flutter dirigidas**

Run: `flutter test --no-pub test/map_location_controller_test.dart test/external_directions_test.dart test/map_geolocation_test.dart test/app_navigation_test.dart`.

Expected: todas pasan sin requerir un plugin de plataforma activo.

---

### Task 7: Puntos administrados como fuente de verdad para Runi

**Files:**
- Modify: `lib/runi/runi_recommender.dart:1-620`
- Modify: `lib/main.dart:1060-1175,3023-3150`
- Modify: `test/runi_recommender_test.dart`
- Modify: `test/map_document_controller_test.dart`
- Modify: `test/onboarding_flow_test.dart`

**Interfaces:**
- Consumes: `List<MapPlace> MapDocumentController.visibleRecommendationPlaces` de Task 2; `RootShell` convierte cada elemento a `RuniPlaceOverride`.
- Produces: `RuniPlaceOverride(recommendationId, name, x, y, isVisible)`.
- Extends: `RuniRecommendationEngine.build(..., Iterable<RuniPlaceOverride> places = const [])`.

- [ ] **Step 1: Escribir pruebas fallidas de actualización y ocultamiento**

Mover `plaza-luna` en un documento v3 y comprobar que la continuidad de Runi usa esa coordenada; ocultar `megaescenario` y comprobar que no aparece como lugar ni como evento; enviar un punto sin `recommendationId` y comprobar que no reemplaza candidatos por coincidencia accidental de nombre.

- [ ] **Step 2: Ejecutar y confirmar el fallo**

Run: `flutter test --no-pub test/runi_recommender_test.dart test/map_document_controller_test.dart test/onboarding_flow_test.dart`

Expected: FAIL porque `build` todavía usa el catálogo fijo.

- [ ] **Step 3: Implementar overrides estables**

Fusionar únicamente por `recommendationId`. Sobrescribir nombre y coordenadas de candidatos visibles, excluir candidatos ocultos y excluir eventos cuyo escenario esté oculto. Conservar comportamiento determinista y el catálogo como respaldo cuando todavía no llegó un documento del WebView.

- [ ] **Step 4: Compartir el controlador en `RootShell`**

Crear una única instancia por sesión, pasarla a `MapScreen` y leerla al abrir Runi. El canal `FlutterMapDocument` llama `acceptJson`; una recarga del WebView no crea otro controlador. Conservar el `mapScreenBuilder(bool active)` usado por pruebas.

- [ ] **Step 5: Ejecutar pruebas dirigidas**

Run: `flutter test --no-pub test/runi_recommender_test.dart test/map_document_controller_test.dart test/onboarding_flow_test.dart test/app_navigation_test.dart`.

Expected: todas pasan; ningún plan recomienda un lugar oculto.

---

### Task 8: Verificación integral, simulador y bitácora

**Files:**
- Modify only if a defect is found: files owned by Tasks 1–7.
- Modify: `/Users/afnaranjo/traiding/AGENTS.md`

**Interfaces:**
- Consumes: entrega completa de Tasks 1–7.
- Produces: evidencia reproducible de pruebas, compilación, modo offline y revisión visual.

- [ ] **Step 1: Ejecutar calidad estática y todas las pruebas**

Run: `dart format lib/main.dart lib/map lib/runi/runi_recommender.dart test/map_document_controller_test.dart test/map_location_controller_test.dart test/external_directions_test.dart test/map_geolocation_test.dart test/runi_recommender_test.dart test/app_navigation_test.dart test/onboarding_flow_test.dart && flutter analyze --no-pub && flutter test --no-pub && node test/map_geometry_test.mjs && node test/map_filter_test.mjs && node test/map_admin_editor_test.mjs && node test/walking_navigation_test.mjs && node test/location_tracker_test.mjs && git diff --check`.

Expected: cero hallazgos, todas las pruebas pasan y el diff nuevo está limpio. No formatear ni revertir archivos ajenos fuera del alcance.

- [ ] **Step 2: Compilar iOS y Android**

Run: `flutter build ios --simulator --debug --no-pub`.

Run Android cuando exista dispositivo/SDK local: `flutter build apk --debug --no-pub`.

Expected: iOS genera `build/ios/iphonesimulator/Runner.app`; Android genera APK o se registra con precisión la limitación del entorno.

- [ ] **Step 3: Verificar en iPhone 17 Pro Max simulado**

Instalar sin borrar datos locales. Confirmar: carga sin recorte; `Ver todo`; pan vertical/horizontal; zoom; accesos/baños/escenarios contra el PDF; ubicación simulada en Plaza de la Luna; ruta a Megaescenario; restante y progreso; dos muestras desviadas recalculan; llegada; recorrido diario; marcador exterior eliminado; pantalla interna de indicaciones.

- [ ] **Step 4: Verificar administración y Runi en la misma sesión**

Entrar como administrador, mover un destino, ocultar otro y editar un evento. Confirmar `Cambios aplicados en la app`, nueva ruta, advertencia si queda fuera de red y ausencia del oculto en Runi. Recargar el WebView y confirmar que no se duplican puntos, streams ni metros.

- [ ] **Step 5: Verificar modo offline y rendimiento local**

Con red desactivada después de instalar, abrir mapa, navegar entre dos puntos y recargar. El SVG, lugares, grafo y lógica deben cargar localmente. Medir tres aperturas frías en simulador; registrar tiempo hasta `hideSplash` y tamaño de activos. Si el SVG retrasa visiblemente la carga, optimizarlo sin rasterizar textos ni eliminar accesos y repetir.

- [ ] **Step 6: Revisar el diff y actualizar la bitácora**

Registrar en `/Users/afnaranjo/traiding/AGENTS.md` objetivo, resultado, decisiones, archivos, comandos, resultados, pendientes y siguiente paso. Mantener los cambios sin commit ni push hasta que Alex lo solicite expresamente.
