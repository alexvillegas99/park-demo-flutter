class MapFilterModel {
  constructor() {
    this.active = 'todos';
    this.search = '';
  }

  select(category) {
    this.active = category;
  }

  matches(point) {
    const categoryMatches =
      this.active === 'todos' || point.cat === this.active;
    const searchMatches =
      !this.search || point.name.toLowerCase().includes(this.search);
    return categoryMatches && searchMatches;
  }
}

class MapViewModel {
  constructor(width, height) {
    this.width = width;
    this.height = height;
  }

  containScale(viewportWidth, viewportHeight) {
    return Math.min(
      viewportWidth / this.width,
      viewportHeight / this.height,
    );
  }

  fillScale(viewportWidth, viewportHeight) {
    return Math.max(
      viewportWidth / this.width,
      viewportHeight / this.height,
    );
  }

  minimumScale(viewportWidth, viewportHeight) {
    return this.containScale(viewportWidth, viewportHeight);
  }

  fit(viewportWidth, viewportHeight, mode = 'contain') {
    const scale =
      mode === 'fill'
        ? this.fillScale(viewportWidth, viewportHeight)
        : this.containScale(viewportWidth, viewportHeight);
    const scaledWidth = this.width * scale;
    const scaledHeight = this.height * scale;
    return {
      scale,
      scaledWidth,
      scaledHeight,
      x: (viewportWidth - scaledWidth) / 2,
      y: (viewportHeight - scaledHeight) / 2,
      overlayOpacity: 0.88,
    };
  }

  zoom(currentScale, factor, viewportWidth, viewportHeight) {
    return Math.min(
      8,
      Math.max(
        this.minimumScale(viewportWidth, viewportHeight),
        currentScale * factor,
      ),
    );
  }

  clamp(offset, contentSize, viewportSize, margin = 0) {
    if (contentSize <= viewportSize) {
      return (viewportSize - contentSize) / 2;
    }
    return Math.min(
      margin,
      Math.max(viewportSize - contentSize - margin, offset),
    );
  }
}

const MapMarkerIcons = {
  forCategory(category, fallback = '') {
    if (category !== 'acceso') return fallback;
    return `<svg viewBox="0 0 28 28" role="img" aria-label="Acceso" focusable="false">
      <path d="M4.5 23.5V5.5c0-1.1.9-2 2-2h10.8c1.1 0 2 .9 2 2v4" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"/>
      <path d="M8.5 23.5h10.8v-5" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"/>
      <path d="M11 14h12m-4-4 4 4-4 4" fill="none" stroke="currentColor" stroke-width="2.8" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>`;
  },
};

class LocationStatusModel {
  view(state) {
    const states = {
      searching: {
        label: 'Buscando ubicación…',
        active: true,
        markerVisible: false,
      },
      located: {
        label: 'Estás aquí',
        active: true,
        markerVisible: true,
      },
      denied: {
        label: 'Activa tu ubicación',
        active: false,
        markerVisible: false,
      },
      outside: {
        label: 'Fuera del recinto',
        active: false,
        markerVisible: false,
      },
      error: {
        label: 'Ubicación no disponible',
        active: false,
        markerVisible: false,
      },
    };
    return states[state] || states.searching;
  }
}

class MapProgrammingModel {
  constructor(storage = null) {
    this.days = [];
    this.selectedIndex = 0;
    this.storageKey = 'mr_fair_programming_v1';
    this.storage = storage;
    if (!this.storage) {
      try {
        this.storage = globalThis.localStorage || null;
      } catch (_) {
        this.storage = null;
      }
    }
  }

  setDays(days) {
    const incoming = this.#cloneDays(days);
    const stored = this.#readStoredDays();
    this.days = stored || incoming;
    this.selectedIndex = Math.min(
      this.selectedIndex,
      Math.max(0, this.days.length - 1),
    );
    return Boolean(stored);
  }

  selectDay(index) {
    const parsed = Number(index);
    if (!Number.isInteger(parsed) || parsed < 0 || parsed >= this.days.length) {
      return false;
    }
    this.selectedIndex = parsed;
    return true;
  }

  get selectedDay() {
    return this.days[this.selectedIndex] || null;
  }

  scheduleForVenue(venue) {
    const day = this.selectedDay;
    if (!day || !['sol', 'luna', 'mega'].includes(venue)) return [];
    const entries = day[venue];
    return Array.isArray(entries)
      ? JSON.parse(JSON.stringify(entries))
      : [];
  }

  updateEntry(venue, dayIndex, entryIndex, patch) {
    if (!['sol', 'luna', 'mega'].includes(venue)) return false;
    const day = this.days[Number(dayIndex)];
    const entries = day && day[venue];
    const entry = Array.isArray(entries) ? entries[Number(entryIndex)] : null;
    if (!entry) return false;
    const title = String(patch?.title ?? entry.title).trim();
    const time = String(patch?.time ?? entry.time).trim();
    if (!title || !/^([01]\d|2[0-3]):[0-5]\d$/.test(time)) return false;
    entries[Number(entryIndex)] = { time, title };
    this.#persist();
    return true;
  }

  exportDays() {
    return this.#cloneDays(this.days);
  }

  #cloneDays(days) {
    return Array.isArray(days) ? JSON.parse(JSON.stringify(days)) : [];
  }

  #readStoredDays() {
    if (!this.storage) return null;
    try {
      const decoded = JSON.parse(this.storage.getItem(this.storageKey));
      return Array.isArray(decoded) && decoded.length
        ? this.#cloneDays(decoded)
        : null;
    } catch (_) {
      return null;
    }
  }

  #persist() {
    if (!this.storage) return;
    this.storage.setItem(this.storageKey, JSON.stringify(this.days));
  }
}

globalThis.MapFilterModel = MapFilterModel;
globalThis.MapViewModel = MapViewModel;
globalThis.MapMarkerIcons = MapMarkerIcons;
globalThis.LocationStatusModel = LocationStatusModel;
globalThis.MapProgrammingModel = MapProgrammingModel;
