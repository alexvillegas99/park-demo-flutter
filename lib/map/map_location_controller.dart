import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import 'map_geo.dart';

enum MapLocationPermission { granted, denied, deniedForever, serviceDisabled }

enum MapLocationFailureCode { permissionDenied, serviceDisabled, streamError }

class MapLocationFailure {
  const MapLocationFailure(this.code, this.message);

  final MapLocationFailureCode code;
  final String message;
}

class MapPositionFix {
  const MapPositionFix({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
}

class MapLocationSample {
  const MapLocationSample({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    required this.inside,
  });

  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;
  final bool inside;

  GeoPoint get point => GeoPoint(latitude: latitude, longitude: longitude);

  Map<String, Object> toJson() => <String, Object>{
    'lat': latitude,
    'lng': longitude,
    'accuracy': accuracy,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'inside': inside,
  };
}

class MapLocationBoundary {
  const MapLocationBoundary({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final double latitude;
  final double longitude;
  final double radiusMeters;

  bool contains(double candidateLatitude, double candidateLongitude) {
    const latitudeMeters = 111132.0;
    final meanLatitude = ((latitude + candidateLatitude) / 2) * math.pi / 180;
    final north = (candidateLatitude - latitude) * latitudeMeters;
    final east =
        (candidateLongitude - longitude) * 111320 * math.cos(meanLatitude);
    return math.sqrt(north * north + east * east) <= radiusMeters;
  }
}

abstract interface class MapPositionSource {
  Future<MapLocationPermission> ensurePermission();

  Stream<MapPositionFix> watch();

  Future<void> stop();
}

class GeolocatorMapPositionSource implements MapPositionSource {
  const GeolocatorMapPositionSource();

  static const LocationSettings trackingSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 1,
  );

  @override
  Future<MapLocationPermission> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return MapLocationPermission.serviceDisabled;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => MapLocationPermission.granted,
      LocationPermission.deniedForever => MapLocationPermission.deniedForever,
      _ => MapLocationPermission.denied,
    };
  }

  @override
  Stream<MapPositionFix> watch() =>
      Geolocator.getPositionStream(locationSettings: trackingSettings).map(
        (position) => MapPositionFix(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          timestamp: position.timestamp,
        ),
      );

  @override
  Future<void> stop() async {}
}

class MapLocationController {
  MapLocationController({
    required MapPositionSource source,
    required MapLocationBoundary boundary,
  }) : _source = source,
       _boundary = boundary;

  final MapPositionSource _source;
  final MapLocationBoundary _boundary;
  final StreamController<MapLocationSample> _updates =
      StreamController<MapLocationSample>.broadcast();
  final StreamController<MapLocationFailure> _errors =
      StreamController<MapLocationFailure>.broadcast();
  StreamSubscription<MapPositionFix>? _subscription;
  bool _active = false;
  bool _starting = false;
  bool _disposed = false;
  int _generation = 0;

  Stream<MapLocationSample> get updates => _updates.stream;
  Stream<MapLocationFailure> get errors => _errors.stream;
  bool get active => _active;

  Future<void> setActive(bool value) async {
    if (_disposed) return;
    if (value == _active && (_subscription != null || _starting || !value)) {
      return;
    }
    _active = value;
    final generation = ++_generation;
    if (!value) {
      await _stopSource();
      return;
    }

    _starting = true;
    final permission = await _source.ensurePermission();
    if (_disposed || !_active || generation != _generation) {
      _starting = false;
      return;
    }
    if (permission != MapLocationPermission.granted) {
      _starting = false;
      _emitPermissionFailure(permission);
      return;
    }
    _subscription = _source.watch().listen(
      (fix) {
        if (!_active || _disposed) return;
        _updates.add(
          MapLocationSample(
            latitude: fix.latitude,
            longitude: fix.longitude,
            accuracy: fix.accuracy,
            timestamp: fix.timestamp,
            inside: _boundary.contains(fix.latitude, fix.longitude),
          ),
        );
      },
      onError: (Object error) {
        if (_disposed) return;
        _errors.add(
          MapLocationFailure(
            MapLocationFailureCode.streamError,
            'No se pudo actualizar tu ubicación',
          ),
        );
      },
    );
    _starting = false;
  }

  void _emitPermissionFailure(MapLocationPermission permission) {
    final failure = switch (permission) {
      MapLocationPermission.serviceDisabled => const MapLocationFailure(
        MapLocationFailureCode.serviceDisabled,
        'Activa la ubicación en Ajustes',
      ),
      _ => const MapLocationFailure(
        MapLocationFailureCode.permissionDenied,
        'Permite la ubicación para mostrar dónde estás',
      ),
    };
    _errors.add(failure);
  }

  Future<void> _stopSource() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
    await _source.stop();
    _starting = false;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _active = false;
    _generation += 1;
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(_source.stop());
    unawaited(_updates.close());
    unawaited(_errors.close());
  }
}
