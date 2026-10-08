import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';

const geometryUrl = new URL('../assets/map/map_geometry.js', import.meta.url);
const placesUrl = new URL('../assets/map/map_places.js', import.meta.url);
const svgUrl = new URL(
  '../assets/map/mushuc_runa_validated.svg',
  import.meta.url,
);

const browserContext = { console, JSON, Math };
browserContext.globalThis = browserContext;

if (existsSync(geometryUrl)) {
  runInNewContext(readFileSync(geometryUrl, 'utf8'), browserContext);
}
if (existsSync(placesUrl)) {
  runInNewContext(readFileSync(placesUrl, 'utf8'), browserContext);
}

const { MapGeometryV3, MR_MAP_PLACES_V3, MR_LEGACY_PLACES_V2, MR_MAP_LEGEND_V1 } =
  browserContext;

assert.equal(typeof MapGeometryV3, 'object');
assert.equal(MapGeometryV3.width, 1600);
assert.equal(MapGeometryV3.height, 1327);

const controls = [
  [-1.3684769962114673, -78.65151912830171],
  [-1.3721312850255056, -78.6506831995043],
  [-1.3657756022784497, -78.64414004716147],
  [-1.365766258405764, -78.64403182422295],
  [-1.3678490209497878, -78.6465192082527],
];
for (const [lat, lng] of controls) {
  const point = MapGeometryV3.toMap(lat, lng);
  const roundTrip = MapGeometryV3.toLatLng(point.x, point.y);
  assert.ok(Math.abs(roundTrip.lat - lat) < 1e-7);
  assert.ok(Math.abs(roundTrip.lng - lng) < 1e-7);
}

const first = MapGeometryV3.toMap(...controls[0]);
const second = MapGeometryV3.toMap(...controls[1]);
const forward = MapGeometryV3.distanceMeters(first, second);
const backward = MapGeometryV3.distanceMeters(second, first);
assert.ok(forward > 100);
assert.ok(Math.abs(forward - backward) < 1e-9);

const legacySeed = { id: 11, x: 333.3, y: 352.7 };
const officialSeed = { id: 11, x: 690, y: 120 };
assert.deepEqual(
  JSON.parse(
    JSON.stringify(
      MapGeometryV3.migrateLegacyPoint(
        { id: 11, x: 333.3, y: 352.7 },
        legacySeed,
        officialSeed,
      ),
    ),
  ),
  { x: 690, y: 120, needsReview: false },
);
const moved = MapGeometryV3.migrateLegacyPoint(
  { id: 11, x: 363.3, y: 382.7 },
  legacySeed,
  officialSeed,
);
assert.equal(moved.needsReview, true);
assert.ok(Number.isFinite(moved.x));
assert.ok(Number.isFinite(moved.y));

const custom = MapGeometryV3.migrateLegacyPoint(
  { id: 'custom-1', x: 950, y: 509 },
  null,
  null,
);
assert.equal(custom.needsReview, true);

assert.ok(Array.isArray(MR_MAP_PLACES_V3));
assert.ok(Array.isArray(MR_LEGACY_PLACES_V2));
assert.equal(MR_MAP_PLACES_V3.length, 80);
assert.equal(MR_LEGACY_PLACES_V2.length, 94);
assert.equal(MR_MAP_PLACES_V3.some((place) => place.cat === 'trans'), false);
assert.equal(
  MR_MAP_PLACES_V3.find((place) => place.recommendationId === 'megaescenario')
    .name,
  'Mega Escenario',
);
assert.deepEqual(Object.keys(MR_MAP_LEGEND_V1).sort(), [
  'accesses',
  'administration',
  'entertainment',
  'parking',
  'stands',
]);

assert.equal(existsSync(svgUrl), true);
const svg = readFileSync(svgUrl, 'utf8');
assert.match(svg, /viewBox="168 0 673\.89 559"/);
assert.doesNotMatch(svg, /(?:href|xlink:href)="https?:/i);

console.log('map_geometry_test: ok');
