import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'map_geo.dart';
import 'map_document_store.dart';

const int mapDocumentSchemaVersion = 4;

const Set<String> _allowedMapCategories = <String>{
  'evento',
  'bano',
  'acceso',
  'salida',
  'show',
  'comida',
  'servicio',
  'parqueo',
  'zona',
};

@immutable
class MapMarkerPresentation {
  const MapMarkerPresentation({
    required this.iconKey,
    required this.isLarge,
    required this.showsLabel,
  });

  final String iconKey;
  final bool isLarge;
  final bool showsLabel;
}

@immutable
class MapPlace {
  const MapPlace({
    required this.id,
    required this.category,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.isVisible,
    required this.isFeatured,
    required this.needsReview,
    required this.events,
    this.recommendationId,
    this.icon,
    this.venue,
  });

  factory MapPlace.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Lugar inválido');
    final map = Map<String, Object?>.from(value);
    final id = '${map['id'] ?? ''}'.trim();
    final category = '${map['cat'] ?? ''}'.trim();
    final name = '${map['name'] ?? ''}'.trim();
    final latitude = _coordinate(map['latitude'], -90, 90, 'latitud');
    final longitude = _coordinate(map['longitude'], -180, 180, 'longitud');
    if (id.isEmpty ||
        name.isEmpty ||
        !_allowedMapCategories.contains(category)) {
      throw const FormatException('Lugar inválido');
    }
    final rawEvents = map['events'] ?? const <Object?>[];
    if (rawEvents is! List) throw const FormatException('Eventos inválidos');
    final events = rawEvents
        .map((event) {
          if (event is! Map) throw const FormatException('Evento inválido');
          return Map<String, Object?>.unmodifiable(
            Map<String, Object?>.from(event),
          );
        })
        .toList(growable: false);
    final recommendationId = _optionalText(map['recommendationId']);
    return MapPlace(
      id: id,
      category: category,
      name: name,
      latitude: latitude,
      longitude: longitude,
      isVisible: map['isVisible'] != false,
      isFeatured:
          map['isFeatured'] == true || _optionalText(map['venue']) != null,
      needsReview: map['needsReview'] == true,
      recommendationId: recommendationId,
      icon: _optionalText(map['icon']),
      venue: _optionalText(map['venue']),
      events: List<Map<String, Object?>>.unmodifiable(events),
    );
  }

  final String id;
  final String category;
  final String name;
  final double latitude;
  final double longitude;
  final bool isVisible;
  final bool isFeatured;
  final bool needsReview;
  final String? recommendationId;
  final String? icon;
  final String? venue;
  final List<Map<String, Object?>> events;

  GeoPoint get point => GeoPoint(latitude: latitude, longitude: longitude);

  MapMarkerPresentation get markerPresentation {
    final normalizedName = _normalize(name);
    final normalizedIcon = _normalize(icon ?? '');
    final iconKey = switch (normalizedIcon) {
      'dinosaur' || 'dinosaurio' => 'dinosaur',
      'farm' || 'granja' => 'farm',
      'slide' || 'resbaladera' => 'slide',
      'park' || 'mushuc-park' => 'park',
      'rides' || 'juegos' => 'rides',
      'stage' || 'microphone' || '🎤' => 'stage',
      'moon' || '🌙' => 'moon',
      'sun' || '☀️' || '☀' => 'sun',
      'comedy' => 'comedy',
      'bull' => 'bull',
      'military' => 'military',
      _ => _iconForNameOrCategory(normalizedName, category),
    };
    final large = isFeatured || category == 'evento';
    return MapMarkerPresentation(
      iconKey: iconKey,
      isLarge: large,
      showsLabel: large,
    );
  }

  MapPlace copyWith({
    String? category,
    String? name,
    double? latitude,
    double? longitude,
    bool? isVisible,
    bool? isFeatured,
    bool? needsReview,
    String? recommendationId,
    String? icon,
    String? venue,
    List<Map<String, Object?>>? events,
  }) {
    return MapPlace(
      id: id,
      category: category ?? this.category,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVisible: isVisible ?? this.isVisible,
      isFeatured: isFeatured ?? this.isFeatured,
      needsReview: needsReview ?? this.needsReview,
      recommendationId: recommendationId ?? this.recommendationId,
      icon: icon ?? this.icon,
      venue: venue ?? this.venue,
      events: List<Map<String, Object?>>.unmodifiable(events ?? this.events),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'cat': category,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'isVisible': isVisible,
    'isFeatured': isFeatured,
    'needsReview': needsReview,
    if (recommendationId != null) 'recommendationId': recommendationId,
    if (icon != null) 'icon': icon,
    if (venue != null) 'venue': venue,
    'events': events,
  };

  static double _coordinate(
    Object? value,
    double minimum,
    double maximum,
    String label,
  ) {
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    if (number == null ||
        !number.isFinite ||
        number < minimum ||
        number > maximum) {
      throw FormatException('Coordenada $label inválida');
    }
    return number;
  }

  static String? _optionalText(Object? value) {
    final text = '${value ?? ''}'.trim();
    return text.isEmpty ? null : text;
  }

  static String _iconForNameOrCategory(String name, String category) {
    if (name.contains('dinosaur')) return 'dinosaur';
    if (name.contains('granja')) return 'farm';
    if (name.contains('resbaladera')) return 'slide';
    if (name.contains('mushuc park')) return 'park';
    if (name.contains('juegos mecanicos')) return 'rides';
    if (name.contains('mega escenario')) return 'stage';
    if (name.contains('plaza de la luna')) return 'moon';
    if (name.contains('plaza del sol')) return 'sun';
    if (name.contains('comic')) return 'comedy';
    if (name.contains('toros')) return 'bull';
    if (name.contains('militar')) return 'military';
    if (name.contains('boleteria')) return 'ticket';
    if (name.contains('dispensario')) return 'medical';
    if (name.contains('hidratacion')) return 'water';
    if (name.contains('escaner')) return 'scanner';
    return switch (category) {
      'bano' => 'restroom',
      'acceso' => 'entrance',
      'salida' => 'exit',
      'show' => 'attraction',
      'comida' => 'food',
      'parqueo' => 'parking',
      'zona' => 'zone',
      'evento' => 'stage',
      _ => 'service',
    };
  }

  static String _normalize(String value) {
    const replacements = <String, String>{
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    var normalized = value.toLowerCase().trim();
    replacements.forEach(
      (from, to) => normalized = normalized.replaceAll(from, to),
    );
    return normalized;
  }
}

class MapDocumentMigration {
  const MapDocumentMigration._();

  static Map<String, Object?> migrateV3(Map<String, Object?> source) {
    if (source['schemaVersion'] != 3) {
      throw const FormatException('Solo se pueden migrar documentos v3');
    }
    final rawPlaces = source['places'];
    if (rawPlaces is! List || rawPlaces.isEmpty) {
      throw const FormatException('El documento no contiene lugares');
    }
    final migrated = rawPlaces
        .map((rawPlace) {
          if (rawPlace is! Map) throw const FormatException('Lugar inválido');
          final place = Map<String, Object?>.from(rawPlace);
          final x = _number(place.remove('x'), 'X');
          final y = _number(place.remove('y'), 'Y');
          final point = LegacyMapProjection.toGeo(x, y);
          return <String, Object?>{
            ...place,
            'latitude': point.latitude,
            'longitude': point.longitude,
          };
        })
        .toList(growable: false);
    return <String, Object?>{
      ...source,
      'schemaVersion': mapDocumentSchemaVersion,
      'places': migrated,
    };
  }

  static double _number(Object? value, String label) {
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    if (number == null || !number.isFinite) {
      throw FormatException('Coordenada $label inválida');
    }
    return number;
  }
}

@immutable
class MapDocumentSnapshot {
  const MapDocumentSnapshot({required this.updatedAt, required this.places});

  factory MapDocumentSnapshot.fromJson(Object? value) {
    if (value is! Map) throw const FormatException('Documento inválido');
    final map = Map<String, Object?>.from(value);
    if (map['schemaVersion'] != mapDocumentSchemaVersion) {
      throw const FormatException('Versión incompatible');
    }
    final updatedAt = DateTime.parse('${map['updatedAt']}').toUtc();
    final rawPlaces = map['places'];
    if (rawPlaces is! List || rawPlaces.isEmpty) {
      throw const FormatException('El documento no contiene lugares');
    }
    final places = rawPlaces.map(MapPlace.fromJson).toList(growable: false);
    final ids = places.map((place) => place.id).toSet();
    if (ids.length != places.length) {
      throw const FormatException('Hay lugares repetidos');
    }
    return MapDocumentSnapshot(
      updatedAt: updatedAt,
      places: List<MapPlace>.unmodifiable(places),
    );
  }

  final DateTime updatedAt;
  final List<MapPlace> places;

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': mapDocumentSchemaVersion,
    'updatedAt': updatedAt.toIso8601String(),
    'places': places.map((place) => place.toJson()).toList(growable: false),
  };
}

class MapDocumentController extends ChangeNotifier {
  MapDocumentSnapshot? _snapshot;
  MapDocumentStore? _store;
  bool _initialized = false;

  MapDocumentSnapshot? get snapshot => _snapshot;
  bool get initialized => _initialized;

  List<MapPlace> get visiblePlaces => List<MapPlace>.unmodifiable(
    _snapshot?.places.where((place) => place.isVisible) ?? const <MapPlace>[],
  );

  List<MapPlace> get visibleRecommendationPlaces => List<MapPlace>.unmodifiable(
    visiblePlaces.where((place) => place.recommendationId != null),
  );

  List<MapPlace> get recommendationPlaces => List<MapPlace>.unmodifiable(
    _snapshot?.places.where((place) => place.recommendationId != null) ??
        const <MapPlace>[],
  );

  bool acceptJson(String rawJson) {
    try {
      final candidate = MapDocumentSnapshot.fromJson(jsonDecode(rawJson));
      if (_snapshot != null &&
          !candidate.updatedAt.isAfter(_snapshot!.updatedAt)) {
        return false;
      }
      _snapshot = candidate;
      notifyListeners();
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> initialize(
    Future<String> Function() seedLoader,
    MapDocumentStore store,
  ) async {
    _store = store;
    final seed = MapDocumentSnapshot.fromJson(jsonDecode(await seedLoader()));
    MapDocumentSnapshot? local;
    try {
      final rawLocal = await store.readCurrent();
      if (rawLocal != null) {
        local = MapDocumentSnapshot.fromJson(jsonDecode(rawLocal));
      }
    } on Object {
      local = null;
    }
    final selected = local != null && local.updatedAt.isAfter(seed.updatedAt)
        ? local
        : seed;
    _snapshot = selected;
    _initialized = true;
    notifyListeners();
  }

  Future<void> replace(
    MapDocumentSnapshot next, {
    required bool persist,
  }) async {
    final previousJson = toJson();
    if (persist) {
      final store = _store;
      if (store == null) {
        throw StateError('El mapa todavía no fue inicializado');
      }
      final nextJson = jsonEncode(next.toJson());
      await store.writeValidated(nextJson, previousJson);
    }
    _snapshot = next;
    _initialized = true;
    notifyListeners();
  }

  Future<bool> restoreBackup() async {
    final store = _store;
    if (store == null) return false;
    try {
      final rawBackup = await store.restoreBackup();
      if (rawBackup == null) return false;
      final backup = MapDocumentSnapshot.fromJson(jsonDecode(rawBackup));
      _snapshot = backup;
      notifyListeners();
      return true;
    } on Object {
      return false;
    }
  }

  String? toJson() {
    final current = _snapshot;
    return current == null ? null : jsonEncode(current.toJson());
  }
}
