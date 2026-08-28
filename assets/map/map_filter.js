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

  minimumScale(viewportWidth, viewportHeight) {
    return Math.max(
      viewportWidth / this.width,
      viewportHeight / this.height,
    );
  }

  fit(viewportWidth, viewportHeight) {
    const scale = this.minimumScale(viewportWidth, viewportHeight);
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

  clamp(offset, contentSize, viewportSize) {
    if (contentSize <= viewportSize) {
      return (viewportSize - contentSize) / 2;
    }
    return Math.min(0, Math.max(viewportSize - contentSize, offset));
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

globalThis.MapFilterModel = MapFilterModel;
globalThis.MapViewModel = MapViewModel;
globalThis.MapMarkerIcons = MapMarkerIcons;
globalThis.LocationStatusModel = LocationStatusModel;
