(function (root) {
  'use strict';

  const WALK_STORAGE_KEY = 'mr_walk_day_v1';
  const MAX_SAMPLE_AGE_MS = 10000;
  const MAX_ROUTE_ACCURACY_METERS = 35;
  const MAX_WALK_ACCURACY_METERS = 20;
  const MIN_WALK_DELTA_METERS = 2;
  const MAX_WALK_SPEED_METERS_PER_SECOND = 3.5;
  const LATITUDE_METERS = 111132;

  function finite(value) {
    const number = Number(value);
    return Number.isFinite(number) ? number : null;
  }

  function distanceMeters(first, second) {
    const firstLat = finite(first && first.lat);
    const firstLng = finite(first && first.lng);
    const secondLat = finite(second && second.lat);
    const secondLng = finite(second && second.lng);
    if ([firstLat, firstLng, secondLat, secondLng].includes(null)) return Infinity;
    const averageLatitude = ((firstLat + secondLat) / 2) * Math.PI / 180;
    const north = (secondLat - firstLat) * LATITUDE_METERS;
    const east = (secondLng - firstLng) * 111320 * Math.cos(averageLatitude);
    return Math.hypot(east, north);
  }

  function response(routeAccepted, walkAccepted, reason, deltaMeters) {
    return {
      routeAccepted,
      walkAccepted,
      reason,
      deltaMeters: Number.isFinite(deltaMeters) ? deltaMeters : 0,
    };
  }

  class LocationSampleFilter {
    static evaluate(sample, previous, nowMs) {
      const now = finite(nowMs);
      const timestamp = finite(sample && sample.timestamp);
      const accuracy = finite(sample && sample.accuracy);
      if (
        !sample || now === null || timestamp === null || accuracy === null ||
        finite(sample.lat) === null || finite(sample.lng) === null
      ) {
        return response(false, false, 'invalid', 0);
      }
      if (sample.inside !== true) return response(false, false, 'outside', 0);
      if (now - timestamp > MAX_SAMPLE_AGE_MS) {
        return response(false, false, 'stale', 0);
      }
      if (timestamp > now + 1000) return response(false, false, 'future', 0);
      if (accuracy > MAX_ROUTE_ACCURACY_METERS) {
        return response(false, false, 'inaccurate_route', 0);
      }
      if (!previous) {
        return response(true, false, 'baseline', 0);
      }
      const previousTimestamp = finite(previous.timestamp);
      if (previousTimestamp === null) return response(true, false, 'baseline', 0);
      if (timestamp < previousTimestamp) {
        return response(false, false, 'out_of_order', 0);
      }
      const deltaMeters = distanceMeters(previous, sample);
      if (
        timestamp === previousTimestamp &&
        deltaMeters < 0.01
      ) {
        return response(false, false, 'duplicate', 0);
      }
      const elapsedSeconds = (timestamp - previousTimestamp) / 1000;
      if (elapsedSeconds <= 0) return response(false, false, 'out_of_order', 0);
      if (deltaMeters / elapsedSeconds > MAX_WALK_SPEED_METERS_PER_SECOND) {
        return response(false, false, 'speed_jump', deltaMeters);
      }
      if (accuracy > MAX_WALK_ACCURACY_METERS) {
        return response(true, false, 'inaccurate_walk', deltaMeters);
      }
      if (deltaMeters < MIN_WALK_DELTA_METERS) {
        return response(true, false, 'movement_noise', deltaMeters);
      }
      return response(true, true, 'accepted', deltaMeters);
    }
  }

  function localDateKey(timestamp) {
    const date = new Date(timestamp);
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${date.getFullYear()}-${month}-${day}`;
  }

  class DailyWalkTracker {
    constructor(storage, clock) {
      this.storage = storage || root.localStorage;
      this.clock = typeof clock === 'function' ? clock : () => Date.now();
      this.state = this._read() || {
        date: localDateKey(this.clock()),
        meters: 0,
        lastSample: null,
      };
      this._ensureDate(this.clock());
    }

    update(sample, nowMs) {
      const now = finite(nowMs) ?? this.clock();
      this._ensureDate(now);
      const evaluation = LocationSampleFilter.evaluate(
        sample,
        this.state.lastSample,
        now,
      );
      if (evaluation.reason === 'baseline') {
        this.state.lastSample = this._copySample(sample);
        this._write();
      } else if (evaluation.walkAccepted) {
        this.state.meters += evaluation.deltaMeters;
        this.state.lastSample = this._copySample(sample);
        this._write();
      }
      return {...this.snapshot(), evaluation};
    }

    resetForDate(localDate) {
      this.state = {date: String(localDate), meters: 0, lastSample: null};
      this._write();
      return this.snapshot();
    }

    snapshot() {
      return {
        date: this.state.date,
        meters: this.state.meters,
        hasBaseline: Boolean(this.state.lastSample),
      };
    }

    _ensureDate(nowMs) {
      const date = localDateKey(nowMs);
      if (this.state.date !== date) this.resetForDate(date);
    }

    _copySample(sample) {
      return {
        lat: Number(sample.lat),
        lng: Number(sample.lng),
        x: finite(sample.x),
        y: finite(sample.y),
        accuracy: Number(sample.accuracy),
        timestamp: Number(sample.timestamp),
        inside: sample.inside === true,
      };
    }

    _read() {
      const raw = this.storage && this.storage.getItem(WALK_STORAGE_KEY);
      if (!raw) return null;
      try {
        const parsed = JSON.parse(raw);
        if (
          !parsed || typeof parsed.date !== 'string' ||
          !Number.isFinite(Number(parsed.meters))
        ) {
          return null;
        }
        return {
          date: parsed.date,
          meters: Math.max(0, Number(parsed.meters)),
          lastSample: parsed.lastSample || null,
        };
      } catch (_) {
        return null;
      }
    }

    _write() {
      if (!this.storage) return;
      this.storage.setItem(WALK_STORAGE_KEY, JSON.stringify(this.state));
    }
  }

  Object.assign(root, {
    LocationSampleFilter,
    DailyWalkTracker,
    WALK_STORAGE_KEY,
  });
})(typeof globalThis !== 'undefined' ? globalThis : window);
