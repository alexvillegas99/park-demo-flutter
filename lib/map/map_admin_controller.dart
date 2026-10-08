import '../account/account_session.dart';
import 'map_document_controller.dart';
import 'map_geo.dart';

class MapAdminController {
  MapAdminController({
    required this.session,
    required this.document,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AccessSession session;
  final MapDocumentController document;
  final DateTime Function() _now;
  int _created = 0;

  Future<String> createPlace({
    required String name,
    required String category,
    required GeoPoint point,
  }) async {
    _guard();
    final cleanedName = name.trim();
    if (cleanedName.isEmpty) throw const FormatException('Nombre requerido');
    final id = 'admin-${_now().toUtc().millisecondsSinceEpoch}-${_created++}';
    final next = <MapPlace>[
      ..._places,
      MapPlace(
        id: id,
        category: category,
        name: cleanedName,
        latitude: point.latitude,
        longitude: point.longitude,
        isVisible: true,
        isFeatured: false,
        needsReview: false,
        events: const <Map<String, Object?>>[],
      ),
    ];
    await _save(next);
    return id;
  }

  Future<void> movePlace(String id, GeoPoint point) {
    _guard();
    return _transform(
      id,
      (place) => place.copyWith(
        latitude: point.latitude,
        longitude: point.longitude,
        needsReview: false,
      ),
    );
  }

  Future<void> updatePlace(
    String id, {
    String? name,
    String? category,
    bool? isVisible,
    bool? isFeatured,
  }) {
    _guard();
    if (name != null && name.trim().isEmpty) {
      throw const FormatException('Nombre requerido');
    }
    return _transform(
      id,
      (place) => place.copyWith(
        name: name?.trim(),
        category: category,
        isVisible: isVisible,
        isFeatured: isFeatured,
      ),
    );
  }

  Future<void> hidePlace(String id) => updatePlace(id, isVisible: false);

  Future<void> updateEvents(String id, List<Map<String, Object?>> events) {
    _guard();
    for (final event in events) {
      final time = '${event['time'] ?? ''}';
      final title = '${event['title'] ?? ''}'.trim();
      if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(time) ||
          title.isEmpty) {
        throw const FormatException('Evento inválido');
      }
    }
    return _transform(id, (place) => place.copyWith(events: events));
  }

  Future<bool> restoreBackup() {
    _guard();
    return document.restoreBackup();
  }

  List<MapPlace> get _places {
    final snapshot = document.snapshot;
    if (snapshot == null) throw StateError('El mapa no está inicializado');
    return snapshot.places;
  }

  Future<void> _transform(
    String id,
    MapPlace Function(MapPlace place) transform,
  ) async {
    var found = false;
    final next = _places
        .map((place) {
          if (place.id != id) return place;
          found = true;
          return transform(place);
        })
        .toList(growable: false);
    if (!found) throw StateError('No existe el punto $id');
    await _save(next);
  }

  Future<void> _save(List<MapPlace> places) async {
    final current = document.snapshot!;
    var updatedAt = _now().toUtc();
    if (!updatedAt.isAfter(current.updatedAt)) {
      updatedAt = current.updatedAt.add(const Duration(microseconds: 1));
    }
    final candidate = MapDocumentSnapshot(
      updatedAt: updatedAt,
      places: List<MapPlace>.unmodifiable(places),
    );
    MapDocumentSnapshot.fromJson(candidate.toJson());
    await document.replace(candidate, persist: true);
  }

  void _guard() {
    if (!session.isAdmin) {
      throw StateError('Solo un administrador puede editar el mapa');
    }
  }
}
