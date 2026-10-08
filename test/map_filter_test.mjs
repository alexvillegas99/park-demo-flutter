import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';

const browserContext = {};
browserContext.globalThis = browserContext;
runInNewContext(
  readFileSync(new URL('../assets/map/map_filter.js', import.meta.url), 'utf8'),
  browserContext,
);
const {
  MapFilterModel,
  MapViewModel,
  MapMarkerIcons,
  LocationStatusModel,
  MapProgrammingModel,
} = browserContext;

assert.equal(typeof MapFilterModel, 'function');
assert.equal(typeof MapProgrammingModel, 'function');

const points = [
  { id: 1, cat: 'evento', name: 'Mega Escenario' },
  { id: 2, cat: 'bano', name: 'Baños 1' },
  { id: 3, cat: 'comida', name: 'Patio de comidas' },
];

const model = new MapFilterModel();
assert.equal(model.active, 'todos');
assert.deepEqual(points.filter((point) => model.matches(point)), points);

model.select('bano');
assert.equal(model.active, 'bano');
assert.deepEqual(
  points.filter((point) => model.matches(point)).map((point) => point.id),
  [2],
);

model.select('comida');
assert.equal(model.active, 'comida');
assert.deepEqual(
  points.filter((point) => model.matches(point)).map((point) => point.id),
  [3],
);

model.search = 'mega';
model.select('todos');
assert.deepEqual(
  points.filter((point) => model.matches(point)).map((point) => point.id),
  [1],
);

const view = new MapViewModel(1600, 1327);
const fitted = view.fit(430, 932, 'contain');
assert.ok(fitted.scaledWidth <= 430);
assert.ok(fitted.scaledHeight <= 932);
assert.equal(fitted.x, 0);
assert.ok(fitted.y > 0);
assert.ok(fitted.overlayOpacity >= 0.75);
const filled = view.fit(430, 932, 'fill');
assert.ok(filled.scaledWidth >= 430);
assert.ok(filled.scaledHeight >= 932);
assert.equal(view.zoom(fitted.scale, 0.1, 430, 932), fitted.scale);
assert.equal(view.clamp(500, 800, 430, 48), 48);
assert.equal(
  view.clamp(-5000, 800, 430, 48),
  430 - 800 - 48,
);

const accessIcon = MapMarkerIcons.forCategory('acceso');
assert.match(accessIcon, /<svg/);
assert.match(accessIcon, /aria-label="Acceso"/);
assert.doesNotMatch(accessIcon, /➡️/);

const locationStatus = new LocationStatusModel();
const plain = (value) => JSON.parse(JSON.stringify(value));
assert.deepEqual(plain(locationStatus.view('searching')), {
  label: 'Buscando ubicación…',
  active: true,
  markerVisible: false,
});
assert.deepEqual(plain(locationStatus.view('located')), {
  label: 'Estás aquí',
  active: true,
  markerVisible: true,
});
assert.deepEqual(plain(locationStatus.view('denied')), {
  label: 'Activa tu ubicación',
  active: false,
  markerVisible: false,
});
assert.deepEqual(plain(locationStatus.view('outside')), {
  label: 'Fuera del recinto',
  active: false,
  markerVisible: false,
});

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
}

const programmingDays = [
  {
    weekday: 'VIE',
    day: '30',
    month: 'OCT',
    fullDate: 'Viernes 30 de octubre',
    sol: [{ time: '12:00', title: 'Inauguración' }],
    luna: [],
    mega: [{ time: '18:00', title: 'Grupo Bodega' }],
  },
  {
    weekday: 'DOM',
    day: '01',
    month: 'NOV',
    fullDate: 'Domingo 1 de noviembre',
    sol: [{ time: '14:00', title: 'Show de Mickey Mouse' }],
    luna: [{ time: '12:00', title: 'Mega Rumba' }],
    mega: [{ time: '18:00', title: 'Guaynaa' }],
  },
];
const programmingStorage = new MemoryStorage();
const programming = new MapProgrammingModel(programmingStorage);
programming.setDays(programmingDays);
assert.equal(programming.selectedIndex, 0);
assert.equal(programming.selectedDay.fullDate, 'Viernes 30 de octubre');
assert.deepEqual(plain(programming.scheduleForVenue('sol')), [
  { time: '12:00', title: 'Inauguración' },
]);
assert.deepEqual(plain(programming.scheduleForVenue('luna')), []);
assert.equal(programming.selectDay(1), true);
assert.equal(programming.selectedDay.fullDate, 'Domingo 1 de noviembre');
assert.deepEqual(plain(programming.scheduleForVenue('mega')), [
  { time: '18:00', title: 'Guaynaa' },
]);
assert.deepEqual(plain(programming.scheduleForVenue('desconocido')), []);
assert.equal(programming.selectDay(9), false);

assert.equal(
  programming.updateEntry('mega', 1, 0, {
    time: '19:15',
    title: 'Guaynaa actualizado',
  }),
  true,
);
assert.deepEqual(plain(programming.scheduleForVenue('mega')), [
  { time: '19:15', title: 'Guaynaa actualizado' },
]);
assert.ok(programmingStorage.getItem('mr_fair_programming_v1'));

const restoredProgramming = new MapProgrammingModel(programmingStorage);
assert.equal(restoredProgramming.setDays(programmingDays), true);
assert.equal(restoredProgramming.selectDay(1), true);
assert.deepEqual(plain(restoredProgramming.scheduleForVenue('mega')), [
  { time: '19:15', title: 'Guaynaa actualizado' },
]);
assert.equal(
  restoredProgramming.updateEntry('desconocido', 1, 0, { time: '20:00' }),
  false,
);
assert.equal(
  restoredProgramming.updateEntry('mega', 1, 9, { time: '20:00' }),
  false,
);

console.log('map_filter_test: ok');
