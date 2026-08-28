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
} = browserContext;

assert.equal(typeof MapFilterModel, 'function');

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

const view = new MapViewModel(1900, 1018);
const fitted = view.fit(440, 760);
assert.ok(fitted.scaledWidth >= 440);
assert.ok(fitted.scaledHeight >= 760);
assert.ok(fitted.overlayOpacity >= 0.75);
assert.equal(view.zoom(fitted.scale, 0.1, 440, 760), fitted.scale);
assert.equal(view.clamp(500, fitted.scaledWidth, 440), 0);
assert.equal(
  view.clamp(-5000, fitted.scaledWidth, 440),
  440 - fitted.scaledWidth,
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

console.log('map_filter_test: ok');
