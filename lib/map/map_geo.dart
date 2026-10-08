import 'dart:math' as math;

class GeoPoint {
  GeoPoint({required this.latitude, required this.longitude}) {
    if (!latitude.isFinite || latitude < -90 || latitude > 90) {
      throw ArgumentError.value(latitude, 'latitude', 'Latitud inválida');
    }
    if (!longitude.isFinite || longitude < -180 || longitude > 180) {
      throw ArgumentError.value(longitude, 'longitude', 'Longitud inválida');
    }
  }

  final double latitude;
  final double longitude;

  Map<String, double> toJson() => <String, double>{
    'latitude': latitude,
    'longitude': longitude,
  };
}

class MapGeo {
  const MapGeo._();

  static const double earthRadiusMeters = 6371008.8;

  static double distanceMeters(GeoPoint first, GeoPoint second) {
    final lat1 = _radians(first.latitude);
    final lat2 = _radians(second.latitude);
    final deltaLat = lat2 - lat1;
    final deltaLng = _radians(second.longitude - first.longitude);
    final haversine =
        math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(deltaLng / 2), 2);
    return 2 * earthRadiusMeters * math.asin(math.sqrt(haversine));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}

class LegacyMapProjection {
  const LegacyMapProjection._();

  static const double width = 1600;
  static const double height = 1327;
  static const double _originLatitude = -1.369;
  static const double _originLongitude = -78.648;
  static const double _metersPerLatitudeDegree = 111132;
  static final double _metersPerLongitudeDegree =
      111320 * math.cos(_originLatitude * math.pi / 180);

  static final List<_Control> _controls = <_Control>[
    const _Control(690, 120, -1.3684769962114673, -78.65151912830171),
    const _Control(160, 1060, -1.3721312850255056, -78.6506831995043),
    const _Control(1300, 525, -1.3657756022784497, -78.64414004716147),
    const _Control(1415, 305, -1.365766258405764, -78.64403182422295),
  ];

  static final List<double> _xCoefficients = _leastSquares((c) => c.x);
  static final List<double> _yCoefficients = _leastSquares((c) => c.y);

  static GeoPoint toGeo(double x, double y) {
    if (!x.isFinite || !y.isFinite) {
      throw ArgumentError('Las coordenadas del mapa deben ser finitas');
    }
    for (final control in _controls) {
      if ((control.x - x).abs() < 0.000001 &&
          (control.y - y).abs() < 0.000001) {
        return GeoPoint(
          latitude: control.latitude,
          longitude: control.longitude,
        );
      }
    }
    final translatedX = x - _xCoefficients[2];
    final translatedY = y - _yCoefficients[2];
    final determinant =
        _xCoefficients[0] * _yCoefficients[1] -
        _xCoefficients[1] * _yCoefficients[0];
    final metersX =
        (translatedX * _yCoefficients[1] - _xCoefficients[1] * translatedY) /
        determinant;
    final metersY =
        (_xCoefficients[0] * translatedY - translatedX * _yCoefficients[0]) /
        determinant;
    return GeoPoint(
      latitude: _originLatitude + metersY / _metersPerLatitudeDegree,
      longitude: _originLongitude + metersX / _metersPerLongitudeDegree,
    );
  }

  static ({double x, double y}) legacyToCurrent(double x, double y) {
    const scale = 1900 / 2830;
    final ex = x / scale;
    final ey = y / scale;
    final projectedX =
        -408.432125697813 + 0.44185994261082073 * ex + 0.03809624037398862 * ey;
    final projectedY =
        271.33543876584343 +
        0.03809624037398862 * ex -
        0.44185994261082073 * ey;
    final latitude = projectedY / 111132 - 1.369;
    final longitude = projectedX / 111288.229743186 - 78.65;
    return toMap(GeoPoint(latitude: latitude, longitude: longitude));
  }

  static ({double x, double y}) toMap(GeoPoint point) {
    final metersX =
        (point.longitude - _originLongitude) * _metersPerLongitudeDegree;
    final metersY =
        (point.latitude - _originLatitude) * _metersPerLatitudeDegree;
    return (
      x:
          _xCoefficients[0] * metersX +
          _xCoefficients[1] * metersY +
          _xCoefficients[2],
      y:
          _yCoefficients[0] * metersX +
          _yCoefficients[1] * metersY +
          _yCoefficients[2],
    );
  }

  static List<double> _leastSquares(double Function(_Control) target) {
    final rows = _controls
        .map((control) {
          final metersX =
              (control.longitude - _originLongitude) *
              _metersPerLongitudeDegree;
          final metersY =
              (control.latitude - _originLatitude) * _metersPerLatitudeDegree;
          return <double>[metersX, metersY, 1];
        })
        .toList(growable: false);
    final normal = List<List<double>>.generate(
      3,
      (row) => List<double>.generate(
        3,
        (column) => rows.fold<double>(
          0,
          (sum, values) => sum + values[row] * values[column],
        ),
      ),
    );
    final projected = List<double>.generate(
      3,
      (row) => List<int>.generate(rows.length, (index) => index).fold<double>(
        0,
        (sum, index) => sum + rows[index][row] * target(_controls[index]),
      ),
    );
    return _solve3(normal, projected);
  }

  static List<double> _solve3(List<List<double>> matrix, List<double> values) {
    final augmented = List<List<double>>.generate(
      3,
      (index) => <double>[...matrix[index], values[index]],
    );
    for (var column = 0; column < 3; column += 1) {
      var pivot = column;
      for (var row = column + 1; row < 3; row += 1) {
        if (augmented[row][column].abs() > augmented[pivot][column].abs()) {
          pivot = row;
        }
      }
      final temporary = augmented[column];
      augmented[column] = augmented[pivot];
      augmented[pivot] = temporary;
      final divisor = augmented[column][column];
      if (divisor.abs() < 1e-12) {
        throw StateError('Los controles geográficos no son independientes');
      }
      for (var index = column; index < 4; index += 1) {
        augmented[column][index] /= divisor;
      }
      for (var row = 0; row < 3; row += 1) {
        if (row == column) continue;
        final factor = augmented[row][column];
        for (var index = column; index < 4; index += 1) {
          augmented[row][index] -= factor * augmented[column][index];
        }
      }
    }
    return augmented.map((row) => row[3]).toList(growable: false);
  }
}

class _Control {
  const _Control(this.x, this.y, this.latitude, this.longitude);

  final double x;
  final double y;
  final double latitude;
  final double longitude;
}
