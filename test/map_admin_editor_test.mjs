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
  MAP_DOCUMENT_STORAGE_KEY,
  MAP_DOCUMENT_BACKUP_KEY,
} = browserContext;

assert.equal(typeof MapAdminDocument, 'function');
assert.equal(typeof MapAdminAuth, 'object');
assert.equal(typeof MapAdminSession, 'function');
assert.equal(MAP_DOCUMENT_STORAGE_KEY, 'mr_map_document_v2');
assert.equal(MAP_DOCUMENT_BACKUP_KEY, 'mr_map_document_v2_backup');

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
assert.equal(exported.schemaVersion, 2);
assert.equal(exported.places.at(-1).events.length, 1);
assert.ok(exported.updatedAt);

assert.throws(
  () => doc.importJson('{"schemaVersion":99,"places":[]}'),
  /versión/i,
);
assert.throws(
  () =>
    doc.importJson(
      '{"schemaVersion":2,"places":[{"id":"x","cat":"servicio","name":"","x":1,"y":1}]}',
    ),
  /nombre/i,
);
assert.equal(doc.findPoint(created.id).name, 'Información principal');

const restored = new MapAdminDocument(seed, storage);
restored.load();
assert.equal(restored.findPoint(created.id).name, 'Información principal');

const mapHtml = readFileSync(
  new URL('../assets/map/index.html', import.meta.url),
  'utf8',
);
assert.doesNotMatch(mapHtml, /fonts\.googleapis\.com/);
assert.match(mapHtml, /#ovl\{display:none!important/);
assert.match(mapHtml, /<script src="\.\/admin_editor\.js"><\/script>/);

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

for (const id of [
  'adminLogin',
  'adminPanel',
  'adminPointList',
  'adminInspector',
  'adminCreatePoint',
  'adminUndoMove',
  'adminEventModal',
  'adminEventForm',
  'adminAddEvent',
  'adminExportJson',
  'adminImportJson',
  'adminImportModal',
  'adminRestoreBackup',
]) {
  assert.match(mapHtml, new RegExp(`id="${id}"`));
}
assert.match(mapHtml, /function openAdminLogin\(/);
assert.match(mapHtml, /function renderAdminPointList\(/);
assert.match(mapHtml, /function beginAdminDrag\(/);
assert.match(mapHtml, /function renderAdminEvents\(/);
assert.match(mapHtml, /function openAdminEventEditor\(/);
assert.match(mapHtml, /function importAdminDocument\(/);
assert.match(mapHtml, /function base2ll\(/);
assert.match(mapHtml, /id="adminCoordLat"/);
assert.match(mapHtml, /id="adminCoordLng"/);
assert.match(mapHtml, /adminSession\.requireCanEdit\(\)/);
assert.doesNotMatch(mapHtml, /\beditMode\b|\bmoveSelected\b|\bsetEdit\b/);

console.log('map_admin_editor_test: ok');
