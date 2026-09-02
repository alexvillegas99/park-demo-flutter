(function (root) {
  'use strict';

  const MAP_DOCUMENT_SCHEMA_VERSION = 2;
  const MAP_DOCUMENT_STORAGE_KEY = 'mr_map_document_v2';
  const MAP_DOCUMENT_BACKUP_KEY = 'mr_map_document_v2_backup';
  const MAP_WIDTH = 1900;
  const MAP_HEIGHT = 1018;
  const VALID_CATEGORIES = new Set([
    'evento',
    'bano',
    'acceso',
    'salida',
    'show',
    'comida',
    'servicio',
    'parqueo',
    'trans',
    'zona',
  ]);
  const VALID_EVENT_STATUS = new Set(['borrador', 'publicado', 'cancelado']);

  function clone(value) {
    return JSON.parse(JSON.stringify(value));
  }

  function requiredText(value, label) {
    const text = String(value == null ? '' : value).trim();
    if (!text) throw new Error(`${label} es obligatorio`);
    return text;
  }

  function finiteCoordinate(value, max, label) {
    const number = Number(value);
    if (!Number.isFinite(number) || number < 0 || number > max) {
      throw new Error(`${label} debe estar entre 0 y ${max}`);
    }
    return Math.round(number * 10) / 10;
  }

  function nextId(prefix) {
    nextId.sequence = (nextId.sequence || 0) + 1;
    return `${prefix}-${Date.now()}-${nextId.sequence}`;
  }

  const MapAdminAuth = Object.freeze({
    email: 'admin@mushucruna.demo',
    password: 'Mushuc2026!',
    accepts(email, password) {
      return (
        String(email || '').trim().toLowerCase() === this.email &&
        String(password || '') === this.password
      );
    },
  });

  class MapAdminSession {
    constructor(auth) {
      this.auth = auth || MapAdminAuth;
      this.canEdit = false;
    }

    login(email, password) {
      this.canEdit = this.auth.accepts(email, password);
      return this.canEdit;
    }

    logout() {
      this.canEdit = false;
    }

    requireCanEdit() {
      if (!this.canEdit) {
        throw new Error('Se requiere una sesión de administrador');
      }
    }
  }

  class MapAdminDocument {
    constructor(seed, storage) {
      this.seed = clone(Array.isArray(seed) ? seed : []);
      this.storage = storage || root.localStorage;
      this.places = [];
      this.undoStack = [];
    }

    load() {
      const current = this._read(MAP_DOCUMENT_STORAGE_KEY);
      const backup = this._read(MAP_DOCUMENT_BACKUP_KEY);
      let document = null;

      for (const candidate of [current, backup]) {
        if (!candidate) continue;
        try {
          document = this._validateDocument(candidate);
          break;
        } catch (_) {
          document = null;
        }
      }

      if (!document) {
        const migratedSeed = clone(this.seed);
        const legacyPositions = this._read('mr_pois');
        if (legacyPositions && !Array.isArray(legacyPositions)) {
          for (const point of migratedSeed) {
            const position = legacyPositions[point.id];
            if (Array.isArray(position) && position.length >= 2) {
              point.x = position[0];
              point.y = position[1];
            }
          }
        }
        document = this._validateDocument({
          schemaVersion: MAP_DOCUMENT_SCHEMA_VERSION,
          updatedAt: new Date().toISOString(),
          places: migratedSeed,
        });
      }

      this.places = clone(document.places);
      this.undoStack = [];
      this._writeCurrent();
      return this.places;
    }

    findPoint(id) {
      return this.places.find((point) => String(point.id) === String(id)) || null;
    }

    createPoint(input) {
      const point = this._validatePoint({
        id: nextId('custom'),
        cat: input && input.cat,
        name: input && input.name,
        x: input && input.x,
        y: input && input.y,
        isVisible: true,
        isFeatured: false,
        events: [],
      });
      this._commit([...this.places, point]);
      return this.findPoint(point.id);
    }

    updatePoint(id, patch) {
      const index = this._pointIndex(id);
      const allowed = new Set([
        'name',
        'cat',
        'icon',
        'venue',
        'isVisible',
        'isFeatured',
      ]);
      const next = clone(this.places);
      const changes = {};
      for (const [key, value] of Object.entries(patch || {})) {
        if (allowed.has(key)) changes[key] = value;
      }
      next[index] = this._validatePoint({...next[index], ...changes});
      this._commit(next);
      return this.findPoint(id);
    }

    movePoint(id, x, y) {
      const index = this._pointIndex(id);
      const previous = this.places[index];
      const next = clone(this.places);
      next[index] = this._validatePoint({...next[index], x, y});
      this.undoStack.push({id: previous.id, x: previous.x, y: previous.y});
      this._commit(next);
      return this.findPoint(id);
    }

    undoMove() {
      const previous = this.undoStack.pop();
      if (!previous) return false;
      const index = this._pointIndex(previous.id);
      const next = clone(this.places);
      next[index] = this._validatePoint({
        ...next[index],
        x: previous.x,
        y: previous.y,
      });
      this._commit(next);
      return true;
    }

    addEvent(placeId, input) {
      const index = this._pointIndex(placeId);
      const event = this._validateEvent({
        id: nextId('event'),
        title: input && input.title,
        time: input && input.time,
        status: (input && input.status) || 'borrador',
        description: (input && input.description) || '',
      });
      const next = clone(this.places);
      next[index].events.push(event);
      this._commit(next);
      return clone(event);
    }

    updateEvent(placeId, eventId, patch) {
      const pointIndex = this._pointIndex(placeId);
      const eventIndex = this.places[pointIndex].events.findIndex(
        (event) => String(event.id) === String(eventId),
      );
      if (eventIndex < 0) throw new Error('Evento no encontrado');
      const allowed = new Set(['title', 'time', 'status', 'description']);
      const changes = {};
      for (const [key, value] of Object.entries(patch || {})) {
        if (allowed.has(key)) changes[key] = value;
      }
      const next = clone(this.places);
      next[pointIndex].events[eventIndex] = this._validateEvent({
        ...next[pointIndex].events[eventIndex],
        ...changes,
      });
      this._commit(next);
      return clone(next[pointIndex].events[eventIndex]);
    }

    publishedEventsFor(placeId) {
      const point = this.findPoint(placeId);
      if (!point || !point.isVisible) return [];
      return clone(point.events.filter((event) => event.status === 'publicado'));
    }

    exportObject() {
      return {
        schemaVersion: MAP_DOCUMENT_SCHEMA_VERSION,
        updatedAt: new Date().toISOString(),
        places: clone(this.places),
      };
    }

    exportJson() {
      return JSON.stringify(this.exportObject(), null, 2);
    }

    importJson(text) {
      let parsed;
      try {
        parsed = JSON.parse(String(text || ''));
      } catch (_) {
        throw new Error('El JSON no tiene un formato válido');
      }
      const document = this._validateDocument(parsed, {requirePlaces: true});
      const previous = this.storage.getItem(MAP_DOCUMENT_STORAGE_KEY);
      if (previous) this.storage.setItem(MAP_DOCUMENT_BACKUP_KEY, previous);
      this.places = clone(document.places);
      this.undoStack = [];
      this._writeCurrent();
      return this.places;
    }

    restoreBackup() {
      const backup = this._read(MAP_DOCUMENT_BACKUP_KEY);
      if (!backup) throw new Error('No existe un respaldo local');
      const document = this._validateDocument(backup, {requirePlaces: true});
      this.places = clone(document.places);
      this.undoStack = [];
      this._writeCurrent();
      return this.places;
    }

    _pointIndex(id) {
      const index = this.places.findIndex(
        (point) => String(point.id) === String(id),
      );
      if (index < 0) throw new Error('Lugar no encontrado');
      return index;
    }

    _commit(nextPlaces) {
      const document = this._validateDocument({
        schemaVersion: MAP_DOCUMENT_SCHEMA_VERSION,
        updatedAt: new Date().toISOString(),
        places: nextPlaces,
      });
      const previous = this.storage.getItem(MAP_DOCUMENT_STORAGE_KEY);
      if (previous) this.storage.setItem(MAP_DOCUMENT_BACKUP_KEY, previous);
      this.places = clone(document.places);
      this._writeCurrent();
    }

    _writeCurrent() {
      this.storage.setItem(MAP_DOCUMENT_STORAGE_KEY, this.exportJson());
    }

    _read(key) {
      const raw = this.storage.getItem(key);
      if (!raw) return null;
      try {
        return JSON.parse(raw);
      } catch (_) {
        return null;
      }
    }

    _validateDocument(value, options) {
      if (!value || Number(value.schemaVersion) !== MAP_DOCUMENT_SCHEMA_VERSION) {
        throw new Error('Versión de documento no compatible');
      }
      if (!Array.isArray(value.places)) {
        throw new Error('La lista de lugares no es válida');
      }
      if (options && options.requirePlaces && value.places.length === 0) {
        throw new Error('El documento debe contener al menos un lugar');
      }
      const places = value.places.map((point) => this._validatePoint(point));
      const ids = new Set();
      for (const point of places) {
        const id = String(point.id);
        if (ids.has(id)) throw new Error(`El lugar ${id} está repetido`);
        ids.add(id);
      }
      return {
        schemaVersion: MAP_DOCUMENT_SCHEMA_VERSION,
        updatedAt: value.updatedAt || new Date().toISOString(),
        places,
      };
    }

    _validatePoint(value) {
      if (!value || value.id == null || String(value.id).trim() === '') {
        throw new Error('El identificador del lugar es obligatorio');
      }
      const cat = requiredText(value.cat, 'La categoría');
      if (!VALID_CATEGORIES.has(cat)) {
        throw new Error(`La categoría ${cat} no está permitida`);
      }
      const events = Array.isArray(value.events) ? value.events : [];
      return {
        ...clone(value),
        id: value.id,
        cat,
        name: requiredText(value.name, 'El nombre del lugar'),
        x: finiteCoordinate(value.x, MAP_WIDTH, 'La coordenada X'),
        y: finiteCoordinate(value.y, MAP_HEIGHT, 'La coordenada Y'),
        isVisible: value.isVisible !== false,
        isFeatured: value.isFeatured === true || Boolean(value.venue),
        events: events.map((event) => this._validateEvent(event)),
      };
    }

    _validateEvent(value) {
      const rawStatus = String((value && value.status) || 'borrador').toLowerCase();
      const status = VALID_EVENT_STATUS.has(rawStatus) ? rawStatus : 'publicado';
      return {
        ...clone(value || {}),
        id: value && value.id ? String(value.id) : nextId('event'),
        title: requiredText(value && value.title, 'El título del evento'),
        time: requiredText(value && value.time, 'La hora del evento'),
        status,
        description: String((value && value.description) || '').trim(),
      };
    }
  }

  Object.assign(root, {
    MapAdminDocument,
    MapAdminAuth,
    MapAdminSession,
    MAP_DOCUMENT_SCHEMA_VERSION,
    MAP_DOCUMENT_STORAGE_KEY,
    MAP_DOCUMENT_BACKUP_KEY,
  });
})(typeof globalThis !== 'undefined' ? globalThis : window);
