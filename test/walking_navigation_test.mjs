import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {runInNewContext} from 'node:vm';

const context = {console, Date, JSON, Math, Map, Set};
context.globalThis = context;
for (const file of [
  'map_geometry.js',
  'map_places.js',
  'route_graph.js',
  'walking_navigation.js',
]) {
  runInNewContext(
    readFileSync(new URL(`../assets/map/${file}`, import.meta.url), 'utf8'),
    context,
  );
}

const {
  MapGeometryV3,
  MR_MAP_PLACES_V3,
  MR_ROUTE_GRAPH_V1,
  WalkingRouteGraph,
  WalkingNavigationSession,
} = context;

assert.equal(MR_ROUTE_GRAPH_V1.version, 1);
assert.equal(typeof WalkingRouteGraph, 'function');
assert.equal(typeof WalkingNavigationSession, 'function');

const graph = new WalkingRouteGraph(MR_ROUTE_GRAPH_V1, MapGeometryV3);
const requiredIds = [11, 12, 13, 14, 15, 16, 20, 21, 28, 30, 31, 93];
for (const id of requiredIds) {
  const place = MR_MAP_PLACES_V3.find((candidate) => candidate.id === id);
  assert.ok(place, `Falta el lugar ${id}`);
  const snapped = graph.snap(place, 35);
  assert.ok(snapped.distanceMeters <= 35, `${place.name} está desconectado`);
}

const components = graph.connectedComponents();
assert.equal(components.length, 1, 'La red peatonal debe formar un solo componente');

const luna = MR_MAP_PLACES_V3.find((place) => place.id === 28);
const mega = MR_MAP_PLACES_V3.find((place) => place.id === 20);
const lunaToMega = graph.route(luna, mega);
assert.ok(lunaToMega.polyline.length >= 3);
assert.equal(lunaToMega.polyline[0].x, luna.x);
assert.equal(lunaToMega.polyline[0].y, luna.y);
assert.equal(lunaToMega.polyline.at(-1).x, mega.x);
assert.equal(lunaToMega.polyline.at(-1).y, mega.y);
assert.ok(
  lunaToMega.distanceMeters >= MapGeometryV3.distanceMeters(luna, mega),
);

assert.throws(
  () => graph.route({x: 1595, y: 10}, mega),
  (error) => error && error.code === 'point_not_connected',
);

const session = new WalkingNavigationSession(graph);
const initial = session.start(luna, mega);
assert.equal(initial.offRouteCount, 0);
assert.equal(initial.arrived, false);
const firstDeviation = session.update({x: 600, y: 735, accuracy: 7});
assert.equal(firstDeviation.offRouteCount, 1);
assert.equal(firstDeviation.recalculations, 0);
const secondDeviation = session.update({x: 602, y: 735, accuracy: 7});
assert.equal(secondDeviation.offRouteCount, 0);
assert.equal(secondDeviation.recalculations, 1);

const minimumArrival = session.start(luna, mega);
const sixMetersAway = {
  x: mega.x - 5 / MapGeometryV3.distanceMeters({x: 0, y: 0}, {x: 1, y: 0}),
  y: mega.y,
  accuracy: 1,
};
assert.equal(session.update(sixMetersAway).arrived, true);
assert.equal(minimumArrival.arrivalRadiusMeters, 6);

session.start(luna, mega);
const fourteenMetersAway = {
  x: mega.x - 14 / MapGeometryV3.distanceMeters({x: 0, y: 0}, {x: 1, y: 0}),
  y: mega.y,
  accuracy: 50,
};
const cappedArrival = session.update(fourteenMetersAway);
assert.equal(cappedArrival.arrivalRadiusMeters, 15);
assert.equal(cappedArrival.arrived, true);

assert.ok(graph.distanceToRoute({x: 500, y: 1000}, lunaToMega.polyline) > 15);
assert.equal(session.finish(), null);

console.log('walking_navigation_test: ok');
