import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {runInNewContext} from 'node:vm';

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

const context = {console, Date, JSON, Math};
context.globalThis = context;
runInNewContext(
  readFileSync(new URL('../assets/map/location_tracker.js', import.meta.url), 'utf8'),
  context,
);

const {LocationSampleFilter, DailyWalkTracker, WALK_STORAGE_KEY} = context;
assert.equal(typeof LocationSampleFilter.evaluate, 'function');
assert.equal(typeof DailyWalkTracker, 'function');
assert.equal(WALK_STORAGE_KEY, 'mr_walk_day_v1');

const baseTime = new Date(2026, 9, 8, 9, 0, 0).getTime();
const point = (metersNorth, overrides = {}) => ({
  lat: -1.369 + metersNorth / 111132,
  lng: -78.648,
  x: 800,
  y: 600 + metersNorth,
  accuracy: 8,
  timestamp: baseTime,
  inside: true,
  ...overrides,
});

const previous = point(0, {timestamp: baseTime - 2000});

let result = LocationSampleFilter.evaluate(
  point(4, {timestamp: baseTime - 11000}),
  previous,
  baseTime,
);
assert.equal(result.routeAccepted, false);
assert.equal(result.reason, 'stale');

result = LocationSampleFilter.evaluate(
  point(4, {accuracy: 36}),
  previous,
  baseTime,
);
assert.equal(result.routeAccepted, false);
assert.equal(result.walkAccepted, false);
assert.equal(result.reason, 'inaccurate_route');

result = LocationSampleFilter.evaluate(
  point(4, {accuracy: 21}),
  previous,
  baseTime,
);
assert.equal(result.routeAccepted, true);
assert.equal(result.walkAccepted, false);
assert.equal(result.reason, 'inaccurate_walk');

result = LocationSampleFilter.evaluate(point(1.9), previous, baseTime);
assert.equal(result.routeAccepted, true);
assert.equal(result.walkAccepted, false);
assert.equal(result.reason, 'movement_noise');

result = LocationSampleFilter.evaluate(
  point(8, {timestamp: baseTime}),
  point(0, {timestamp: baseTime - 2000}),
  baseTime,
);
assert.equal(result.routeAccepted, false);
assert.equal(result.reason, 'speed_jump');

result = LocationSampleFilter.evaluate(previous, previous, baseTime);
assert.equal(result.routeAccepted, false);
assert.equal(result.reason, 'duplicate');

result = LocationSampleFilter.evaluate(
  point(4, {timestamp: baseTime - 3000}),
  previous,
  baseTime,
);
assert.equal(result.routeAccepted, false);
assert.equal(result.reason, 'out_of_order');

result = LocationSampleFilter.evaluate(
  point(4, {inside: false}),
  previous,
  baseTime,
);
assert.equal(result.routeAccepted, false);
assert.equal(result.walkAccepted, false);
assert.equal(result.reason, 'outside');

result = LocationSampleFilter.evaluate(
  point(6, {timestamp: baseTime}),
  previous,
  baseTime,
);
assert.equal(result.routeAccepted, true);
assert.equal(result.walkAccepted, true);
assert.ok(result.deltaMeters >= 5.9 && result.deltaMeters <= 6.1);

const storage = new MemoryStorage();
let clock = baseTime;
const tracker = new DailyWalkTracker(storage, () => clock);
assert.equal(tracker.update(point(0, {timestamp: baseTime}), baseTime).meters, 0);
clock += 3000;
const validSecond = point(6, {timestamp: clock});
assert.ok(tracker.update(validSecond, clock).meters >= 5.9);

const restored = new DailyWalkTracker(storage, () => clock);
assert.ok(restored.snapshot().meters >= 5.9);
assert.equal(restored.snapshot().date, '2026-10-08');

clock = new Date(2026, 9, 9, 9, 0, 0).getTime();
const nextDay = restored.update(point(100, {timestamp: clock}), clock);
assert.equal(nextDay.date, '2026-10-09');
assert.equal(nextDay.meters, 0);
assert.equal(nextDay.hasBaseline, true);

restored.resetForDate('2026-10-10');
assert.equal(restored.snapshot().date, '2026-10-10');
assert.equal(restored.snapshot().meters, 0);
assert.equal(restored.snapshot().hasBaseline, false);

console.log('location_tracker_test: ok');
