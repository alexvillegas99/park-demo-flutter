import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';

class MemoryStorage {
  constructor() {
    this.values = new Map();
  }

  getItem(key) {
    return this.values.has(key) ? this.values.get(key) : null;
  }

  setItem(key, value) {
    this.values.set(key, String(value));
  }

  removeItem(key) {
    this.values.delete(key);
  }
}

const browserContext = {
  console,
  Date,
  JSON,
  Math,
};
browserContext.globalThis = browserContext;
runInNewContext(
  readFileSync(new URL('../assets/map/admin_editor.js', import.meta.url), 'utf8'),
  browserContext,
);

const {
  MapAdminDocument,
  MapAdminAuth,
  MapAdminSession,
  MAP_DOCUMENT_SCHEMA_VERSION,
  MAP_DOCUMENT_STORAGE_KEY,
  MAP_DOCUMENT_BACKUP_KEY,
  MAP_DOCUMENT_LEGACY_KEY,
} = browserContext;

assert.equal(typeof MapAdminDocument, 'function');
assert.equal(typeof MapAdminAuth, 'object');
assert.equal(typeof MapAdminSession, 'function');
assert.equal(MAP_DOCUMENT_SCHEMA_VERSION, 3);
assert.equal(MAP_DOCUMENT_STORAGE_KEY, 'mr_map_document_v3');
assert.equal(MAP_DOCUMENT_BACKUP_KEY, 'mr_map_document_v3_backup');
assert.equal(MAP_DOCUMENT_LEGACY_KEY, 'mr_map_document_v2');

const seed = [
  {
    id: 20,
    cat: 'evento',
    name: 'Mega Escenario',
    x: 1181.6,
    y: 319.8,
    venue: 'mega',
    events: [
      {
        id: 'seed-event',
        title: 'Concierto nacional',
        time: '18:30',
        status: 'publicado',
      },
    ],
  },
  { id: 11, cat: 'acceso', name: 'Acceso 1', x: 333.3, y: 352.7 },
];

const legacySeed = [
  { id: 11, cat: 'acceso', name: 'Acceso 1', x: 333.3, y: 352.7 },
  { id: 20, cat: 'evento', name: 'Mega Escenario', x: 1181.6, y: 319.8 },
];
const officialSeed = [
  { id: 11, cat: 'acceso', name: 'Acceso 1', x: 690, y: 120 },
  {
    id: 20,
    cat: 'evento',
    name: 'Mega Escenario',
    x: 890,
    y: 755,
    recommendationId: 'megaescenario',
  },
];
const legacyStorage = new MemoryStorage();
legacyStorage.setItem(
  MAP_DOCUMENT_LEGACY_KEY,
  JSON.stringify({
    schemaVersion: 2,
    updatedAt: '2026-09-01T12:00:00.000Z',
    places: [
      {
        ...legacySeed[0],
        events: [],
      },
      {
        ...legacySeed[1],
        x: 1201.6,
        isVisible: false,
        events: [
          {
            id: 'legacy-event',
            title: 'Show conservado',
            time: '18:00',
            status: 'publicado',
          },
        ],
      },
      {
        id: 'custom-legacy',
        cat: 'servicio',
        name: 'Punto personalizado',
        x: 900,
        y: 500,
        events: [],
      },
      {
        id: 52,
        cat: 'trans',
        name: 'Estación de trasbordo',
        x: 376,
        y: 396.7,
        events: [],
      },
    ],
  }),
);
const migrationEmissions = [];
const migrated = new MapAdminDocument(officialSeed, legacyStorage, {
  legacySeed,
  migratePoint(point, legacyPoint, officialPoint) {
    const unchanged =
      legacyPoint &&
      officialPoint &&
      Math.hypot(point.x - legacyPoint.x, point.y - legacyPoint.y) <= 1;
    return unchanged
      ? { x: officialPoint.x, y: officialPoint.y, needsReview: false }
      : { x: 700, y: 600, needsReview: true };
  },
  onChange(document) {
    migrationEmissions.push(document);
  },
});
const migratedPlaces = migrated.load();
assert.equal(migratedPlaces.length, 3);
assert.equal(migrated.findPoint(11).x, 690);
assert.equal(migrated.findPoint(11).needsReview, false);
assert.equal(migrated.findPoint(20).x, 700);
assert.equal(migrated.findPoint(20).needsReview, true);
assert.equal(migrated.findPoint(20).isVisible, false);
assert.equal(migrated.findPoint(20).events[0].title, 'Show conservado');
assert.equal(migrated.findPoint('custom-legacy').needsReview, true);
assert.equal(migrated.findPoint(52), null);
assert.ok(legacyStorage.getItem(MAP_DOCUMENT_LEGACY_KEY));
assert.ok(legacyStorage.getItem(MAP_DOCUMENT_STORAGE_KEY));
assert.equal(migrationEmissions.length, 1);

const emissionStorage = new MemoryStorage();
const emissions = [];
const emittingDoc = new MapAdminDocument(officialSeed, emissionStorage, {
  onChange(document) {
    emissions.push(document);
  },
});
emittingDoc.load();
const emittedPoint = emittingDoc.createPoint({
  name: 'Punto emitido',
  cat: 'servicio',
  x: 800,
  y: 500,
});
emittingDoc.movePoint(emittedPoint.id, 810, 510);
emittingDoc.undoMove();
emittingDoc.updatePoint(emittedPoint.id, { name: 'Punto confirmado' });
assert.equal(emissions.length, 5);
const repeated = emittingDoc.exportObject();
assert.equal(emittingDoc.applyExternalDocument(repeated), false);
assert.equal(emissions.length, 5);

const storage = new MemoryStorage();
const doc = new MapAdminDocument(seed, storage);
const loaded = doc.load();
assert.equal(loaded.length, 2);
assert.equal(loaded[0].name, 'Mega Escenario');
assert.equal(loaded[0].isVisible, true);
assert.equal(loaded[0].isFeatured, true);
assert.equal(loaded[1].events.length, 0);

const created = doc.createPoint({
  name: 'Nuevo punto',
  cat: 'servicio',
  x: 950,
  y: 509,
});
assert.match(String(created.id), /^custom-/);
assert.equal(doc.findPoint(created.id).name, 'Nuevo punto');
assert.ok(storage.getItem(MAP_DOCUMENT_STORAGE_KEY));

doc.movePoint(created.id, 1000, 540);
assert.equal(doc.findPoint(created.id).x, 1000);
assert.equal(doc.findPoint(created.id).y, 540);
assert.equal(doc.undoMove(), true);
assert.equal(doc.findPoint(created.id).x, 950);
assert.equal(doc.findPoint(created.id).y, 509);
assert.equal(doc.undoMove(), false);

doc.updatePoint(created.id, {
  name: 'Información principal',
  cat: 'servicio',
  isVisible: false,
  isFeatured: true,
});
assert.equal(doc.findPoint(created.id).name, 'Información principal');
assert.equal(doc.findPoint(created.id).isVisible, false);
assert.equal(doc.findPoint(created.id).isFeatured, true);

const createdEvent = doc.addEvent(created.id, {
  title: 'Show familiar',
  time: '15:00',
  status: 'borrador',
});
assert.match(createdEvent.id, /^event-/);
assert.equal(doc.findPoint(created.id).events.length, 1);
doc.updateEvent(created.id, createdEvent.id, { status: 'publicado' });
assert.equal(doc.publishedEventsFor(created.id).length, 0);
doc.updatePoint(created.id, { isVisible: true });
assert.equal(doc.publishedEventsFor(created.id).length, 1);

const exported = JSON.parse(doc.exportJson());
assert.equal(exported.schemaVersion, 3);
assert.equal(exported.places.at(-1).events.length, 1);
assert.ok(exported.updatedAt);

assert.throws(
  () => doc.importJson('{"schemaVersion":99,"places":[]}'),
  /versión/i,
);
assert.throws(
  () =>
    doc.importJson(
      '{"schemaVersion":3,"places":[{"id":"x","cat":"servicio","name":"","x":1,"y":1}]}',
    ),
  /nombre/i,
);
assert.equal(doc.findPoint(created.id).name, 'Información principal');

const restored = new MapAdminDocument(seed, storage);
restored.load();
assert.equal(restored.findPoint(created.id).name, 'Información principal');

assert.equal(
  MapAdminAuth.accepts('admin@mushucruna.demo', 'Mushuc2026!'),
  true,
);
assert.equal(MapAdminAuth.accepts('visitante', 'Mushuc2026!'), false);

const adminSession = new MapAdminSession();
assert.equal(adminSession.canEdit, false);
assert.equal(adminSession.login('visitante', 'Mushuc2026!'), false);
assert.equal(adminSession.canEdit, false);
assert.throws(() => adminSession.requireCanEdit(), /administrador/i);
assert.equal(
  adminSession.login('admin@mushucruna.demo', 'Mushuc2026!'),
  true,
);
assert.equal(adminSession.canEdit, true);
assert.doesNotThrow(() => adminSession.requireCanEdit());
adminSession.logout();
assert.equal(adminSession.canEdit, false);

const pubspec = readFileSync(new URL('../pubspec.yaml', import.meta.url), 'utf8');
const nativeMap = readFileSync(
  new URL('../lib/map/map_screen.dart', import.meta.url),
  'utf8',
);
assert.doesNotMatch(pubspec, /assets\/map\/index\.html/);
assert.doesNotMatch(pubspec, /mushuc_runa_validated\.svg/);
assert.match(nativeMap, /MapType\.hybrid/);
assert.doesNotMatch(nativeMap, /WebViewWidget/);

console.log('map_admin_editor_test: ok');
