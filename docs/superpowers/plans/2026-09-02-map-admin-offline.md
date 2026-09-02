# Map Admin Offline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar en la app actual un mapa satelital limpio que abra de inmediato y funcione offline, con un acceso administrador de demostración para crear, mover y editar lugares y sus eventos.

**Architecture:** La entrega usa el WebView ya existente como `MapCanvas` offline-first porque contiene la imagen base y la georreferencia del recinto dentro del paquete. Un modelo JavaScript independiente mantiene un documento versionado en `localStorage`, valida importaciones y conserva una copia válida. La interfaz Flutter sigue administrando permisos/GPS; el HTML ofrece la vista visitante y el editor `Lista + mapa`. La futura capa Google Maps podrá sustituir el canvas sin cambiar el documento, pero no se activa hasta disponer de una clave restringida.

**Tech Stack:** Flutter/Dart, `webview_flutter`, `geolocator`, HTML/CSS/JavaScript sin dependencias remotas, pruebas `flutter_test` y Node `assert`/`vm`.

**Spec:** `docs/superpowers/specs/2026-09-02-map-admin-editor-design.md`

## Global Constraints

- Modificar únicamente `/Users/afnaranjo/traiding/park-demo-flutter`; no crear otra copia de la app.
- Frontend local únicamente; no crear backend ni autenticación de producción.
- No guardar claves reales ni activar Google Maps sin una clave restringida.
- Conservar `LocationAccuracy.bestForNavigation` y `distanceFilter: 1`.
- No eliminar de forma irreversible puntos desde el editor; usar visible/oculto.
- Mantener los colores y tipografía visual establecidos por `AppTheme` y la interfaz actual del mapa.
- No hacer commit, push ni despliegue porque el usuario no los solicitó en esta intervención.
- Preservar todos los cambios locales existentes y no reestructurar `lib/main.dart` fuera de la sección Mapa.

---

### Task 1: Documento local versionado para puntos y eventos

**Files:**
- Create: `assets/map/admin_editor.js`
- Create: `test/map_admin_editor_test.mjs`
- Modify: `pubspec.yaml`

**Interfaces:**
- Consumes: puntos iniciales con `{id, cat, name, x, y, events?}` y una API de almacenamiento compatible con `getItem/setItem/removeItem`.
- Produces: `MapAdminDocument`, `MapAdminAuth`, `MAP_DOCUMENT_STORAGE_KEY`, `MAP_DOCUMENT_BACKUP_KEY`, métodos `load()`, `createPoint()`, `updatePoint()`, `movePoint()`, `undoMove()`, `addEvent()`, `updateEvent()`, `exportJson()` e `importJson()`.

- [ ] **Step 1: Escribir la prueba fallida del documento**

```js
const doc = new MapAdminDocument(seed, storage);
assert.equal(doc.load()[0].name, 'Mega Escenario');
const created = doc.createPoint({name:'Nuevo punto',cat:'servicio',x:950,y:509});
doc.movePoint(created.id, 1000, 540);
assert.equal(doc.undoMove(), true);
doc.addEvent(created.id,{title:'Show familiar',time:'15:00',status:'borrador'});
assert.equal(doc.exportObject().places.at(-1).events.length, 1);
assert.throws(() => doc.importJson('{"schemaVersion":99}'), /versión/i);
```

- [ ] **Step 2: Ejecutar la prueba y comprobar el fallo esperado**

Run: `node test/map_admin_editor_test.mjs`
Expected: FAIL porque `assets/map/admin_editor.js` todavía no existe.

- [ ] **Step 3: Implementar el modelo mínimo y la validación**

```js
const MAP_DOCUMENT_SCHEMA_VERSION = 2;
const MAP_DOCUMENT_STORAGE_KEY = 'mr_map_document_v2';
const MAP_DOCUMENT_BACKUP_KEY = 'mr_map_document_v2_backup';

class MapAdminDocument {
  constructor(seed, storage) {
    this.seed = JSON.parse(JSON.stringify(seed));
    this.storage = storage;
    this.places = [];
    this.undoStack = [];
  }
  load() {
    const saved = this.storage.getItem(MAP_DOCUMENT_STORAGE_KEY);
    const source = saved ? JSON.parse(saved) : {
      schemaVersion: MAP_DOCUMENT_SCHEMA_VERSION,
      places: this.seed,
    };
    this.places = this._validateDocument(source).places;
    return this.places;
  }
  createPoint(input) {
    const point = this._validatePoint({
      id: `custom-${Date.now()}`,
      cat: input.cat,
      name: input.name,
      x: input.x,
      y: input.y,
      isVisible: true,
      isFeatured: false,
      events: [],
    });
    this.places.push(point);
    this._persist();
    return point;
  }
  exportObject() {
    return {
      schemaVersion: MAP_DOCUMENT_SCHEMA_VERSION,
      updatedAt: new Date().toISOString(),
      places: JSON.parse(JSON.stringify(this.places)),
    };
  }
  exportJson() { return JSON.stringify(this.exportObject(), null, 2); }
  importJson(text) {
    const validated = this._validateDocument(JSON.parse(text));
    this.storage.setItem(MAP_DOCUMENT_BACKUP_KEY, this.exportJson());
    this.places = validated.places;
    this._persist();
    return this.places;
  }
}
```

Completar la clase con los métodos públicos exactos declarados en `Interfaces` y
helpers privados `_persist`, `_validateDocument`, `_validatePoint` y
`_validateEvent`. La validación exige nombre, categoría conocida, coordenadas
finitas dentro de `0..1900 × 0..1018`, identificadores únicos y eventos con
título/hora/estado. Cada método mutador llama `_persist()` únicamente después de
que el nuevo estado completo haya superado `_validateDocument()`.

- [ ] **Step 4: Ejecutar la prueba del documento**

Run: `node test/map_admin_editor_test.mjs`
Expected: PASS y salida `map_admin_editor_test: ok`.

- [ ] **Step 5: Registrar el recurso en Flutter y verificar assets**

Añadir bajo `flutter/assets`:

```yaml
- assets/map/admin_editor.js
```

Run: `flutter pub get`
Expected: exit 0, sin agregar paquetes ni cambiar SDKs.

### Task 2: Mapa visitante limpio e inmediato

**Files:**
- Modify: `assets/map/index.html`
- Modify: `test/map_admin_editor_test.mjs`
- Modify: `lib/main.dart`
- Modify: `test/map_geolocation_test.dart`

**Interfaces:**
- Consumes: base satelital inline, georreferencia `GF`, puente `FlutterGeo` y `MapAdminDocument`.
- Produces: mapa offline visible desde el primer frame, sin overlay ilustrado ni fuente remota, y `MapExperienceConfig` con política offline-first.

- [ ] **Step 1: Añadir pruebas fallidas de la política offline-first**

```dart
test('el mapa usa primero el recurso offline incluido', () {
  expect(MapExperienceConfig.bundledMapFirst, isTrue);
  expect(MapExperienceConfig.remoteFontsEnabled, isFalse);
});
```

En Node, leer `index.html` y comprobar que no contiene `fonts.googleapis.com`,
que `#ovl` está oculto y que carga `admin_editor.js`.

- [ ] **Step 2: Ejecutar las pruebas y confirmar el fallo**

Run: `flutter test test/map_geolocation_test.dart && node test/map_admin_editor_test.mjs`
Expected: FAIL por ausencia de `MapExperienceConfig` y referencias antiguas.

- [ ] **Step 3: Retirar dependencias visuales remotas y la capa ilustrada**

- Eliminar el `<link>` de Google Fonts.
- Aplicar `#ovl{display:none!important}`.
- Ocultar el control de opacidad y convertir el botón de capa en `Centrar mapa`.
- Cargar `./admin_editor.js` antes del script principal.
- Cambiar la tipografía web a la pila local `Nunito, system-ui, -apple-system, sans-serif`, con fallback local inmediato.

- [ ] **Step 4: Mostrar el WebView desde el inicio en Flutter**

Definir:

```dart
class MapExperienceConfig {
  static const bundledMapFirst = true;
  static const remoteFontsEnabled = false;
  static const demoAdminEmail = 'admin@mushucruna.demo';
}
```

En `MapScreen.build`, retirar `Image.asset('assets/fair_map.png')` y no ocultar
el `WebViewWidget` mientras carga. Mantener un indicador pequeño no bloqueante
hasta `onPageFinished`.

- [ ] **Step 5: Repetir las pruebas de mapa**

Run: `flutter test test/map_geolocation_test.dart && node test/map_admin_editor_test.mjs`
Expected: PASS.

### Task 3: Acceso administrador y editor Lista + mapa

**Files:**
- Modify: `assets/map/index.html`
- Modify: `assets/map/admin_editor.js`
- Modify: `test/map_admin_editor_test.mjs`

**Interfaces:**
- Consumes: `MapAdminDocument`, `POIS`, `buildPins()`, `renderPins()`, `onPin()` y transformaciones `tx/ty/sc`.
- Produces: botón `Administrar`, diálogo de acceso demo, panel responsive `#adminPanel`, lista buscable, inspector del lugar y arrastre directo de marcadores.

- [ ] **Step 1: Añadir pruebas fallidas de autenticación y edición**

```js
assert.equal(MapAdminAuth.accepts('admin@mushucruna.demo','Mushuc2026!'), true);
assert.equal(MapAdminAuth.accepts('visitante','Mushuc2026!'), false);
doc.updatePoint(20,{name:'Mega Escenario principal',isVisible:false});
assert.equal(doc.findPoint(20).isVisible, false);
```

La inspección estática de `index.html` debe encontrar `adminLogin`,
`adminPanel`, `adminPointList`, `adminInspector`, `adminCreatePoint` y
`adminUndoMove`.

- [ ] **Step 2: Ejecutar Node y confirmar el fallo**

Run: `node test/map_admin_editor_test.mjs`
Expected: FAIL porque no existen los componentes administrativos.

- [ ] **Step 3: Construir el acceso demo y panel responsive**

- Añadir botón `Administrar` con icono de escudo.
- Mostrar advertencia `Acceso local de demostración` y las credenciales demo.
- En pantallas anchas, panel lateral de 330 px y mapa restante.
- En teléfonos, panel inferior de máximo 48 % para conservar visibles lista y mapa.
- Añadir búsqueda, filtro `Todos/Visibles/Ocultos`, lista y botón `Nuevo punto`.
- Usar colores vino `#7A0708`, verde `#004F18`, oro `#BEA458`, blanco e
  `#FAF7EF`.

- [ ] **Step 4: Conectar selección, inspector y arrastre**

- Seleccionar una fila centra y resalta el marcador.
- El inspector edita nombre, categoría, visibilidad y destacado.
- `Nuevo punto` aparece en el centro visible del mapa como borrador.
- Arrastrar el marcador seleccionado actualiza `x/y` en vivo.
- Soltar persiste; `Deshacer` restaura la posición anterior.
- Los lugares ocultos no aparecen en modo visitante, pero sí atenuados en admin.

- [ ] **Step 5: Ejecutar la prueba administrativa**

Run: `node test/map_admin_editor_test.mjs`
Expected: PASS.

### Task 4: Eventos por lugar e importación/exportación segura

**Files:**
- Modify: `assets/map/index.html`
- Modify: `assets/map/admin_editor.js`
- Modify: `test/map_admin_editor_test.mjs`

**Interfaces:**
- Consumes: punto seleccionado y operaciones atómicas de `MapAdminDocument`.
- Produces: pestañas `Lugares/Eventos`, formulario de evento, estados `borrador/publicado/cancelado`, importación validada y exportación JSON copiable.

- [ ] **Step 1: Añadir pruebas fallidas de publicación e importación**

```js
const event = doc.addEvent(20,{title:'Concierto nacional',time:'18:30',status:'borrador'});
doc.updateEvent(20,event.id,{status:'publicado'});
assert.equal(doc.publishedEventsFor(20).length, 1);
const before = doc.exportJson();
assert.throws(() => doc.importJson('{"schemaVersion":2,"places":[]}'), /lugar/i);
assert.equal(doc.exportJson(), before);
```

- [ ] **Step 2: Ejecutar la prueba y confirmar el fallo**

Run: `node test/map_admin_editor_test.mjs`
Expected: FAIL por métodos o validaciones todavía ausentes.

- [ ] **Step 3: Implementar el inspector de eventos**

- Listar eventos del lugar seleccionado.
- Abrir un formulario compacto con título, hora y estado.
- Permitir guardar borrador, publicar o marcar cancelado.
- Impedir publicar sin título u hora.
- Mostrar en la tarjeta visitante únicamente eventos publicados. Los eventos
  heredados con estados informativos se migran a `publicado`.

- [ ] **Step 4: Implementar importación/exportación**

- `Exportar JSON` muestra el documento legible y lo copia al portapapeles.
- `Importar JSON` acepta texto pegado, valida sin mutar, muestra resumen y pide
  confirmación antes de aplicar.
- Una importación inválida conserva el documento y muestra el motivo.
- `Restaurar respaldo` recupera la última versión válida guardada.

- [ ] **Step 5: Ejecutar pruebas del editor completo**

Run: `node test/map_admin_editor_test.mjs && node test/map_filter_test.mjs`
Expected: ambas pruebas PASS.

### Task 5: Integración, regresión y simulador iOS

**Files:**
- Modify: `AGENTS.md`
- Verify: todos los archivos anteriores

**Interfaces:**
- Consumes: app Flutter y mapa administrador completados.
- Produces: evidencia de análisis, pruebas y ejecución local; bitácora coordinada.

- [ ] **Step 1: Formatear y analizar**

Run: `dart format lib test`
Expected: formato correcto sin alterar assets generados.

Run: `flutter analyze`
Expected: `No issues found!`.

- [ ] **Step 2: Ejecutar toda la suite**

Run: `flutter test`
Expected: todas las pruebas PASS.

Run: `node test/map_filter_test.mjs && node test/map_admin_editor_test.mjs`
Expected: ambas pruebas PASS.

- [ ] **Step 3: Ejecutar en el simulador existente**

Run: `flutter devices` para resolver el identificador real y luego
`flutter run -d <identificador-resuelto>`.

Expected: la app abre en el simulador, muestra el acceso y permite entrar al mapa.

- [ ] **Step 4: Verificación manual proporcional al riesgo**

- Abrir Mapa y comprobar que no aparece la capa ilustrada ni un área vacía.
- Confirmar `Estás aquí` con ubicación simulada dentro del recinto.
- Entrar con `admin@mushucruna.demo` / `Mushuc2026!`.
- Crear un punto, moverlo, deshacer, volver a mover y guardar.
- Añadir un evento publicado y comprobarlo en modo visitante.
- Reiniciar la app y confirmar persistencia.
- Simular ausencia de internet y confirmar mapa, puntos, eventos y GPS local.

- [ ] **Step 5: Cerrar la bitácora sin Git**

Mover `park-map-admin-editor-design-20260902` de `Trabajo activo` al final del
`Registro de trabajo` de `/Users/afnaranjo/traiding/AGENTS.md`, detallando
archivos, pruebas, limitaciones y que no hubo commit/push/despliegue.
