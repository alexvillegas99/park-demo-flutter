import 'package:flutter_test/flutter_test.dart';
import 'package:park_demo/map/map_geo.dart';

void main() {
  const controls = <({double x, double y, double lat, double lng})>[
    (x: 690, y: 120, lat: -1.3684769962114673, lng: -78.65151912830171),
    (x: 160, y: 1060, lat: -1.3721312850255056, lng: -78.6506831995043),
    (x: 1300, y: 525, lat: -1.3657756022784497, lng: -78.64414004716147),
    (x: 1415, y: 305, lat: -1.365766258405764, lng: -78.64403182422295),
  ];

  test('la proyección heredada conserva los cuatro controles geográficos', () {
    for (final control in controls) {
      final projected = LegacyMapProjection.toGeo(control.x, control.y);
      final error = MapGeo.distanceMeters(
        projected,
        GeoPoint(latitude: control.lat, longitude: control.lng),
      );
      expect(
        error,
        lessThan(0.75),
        reason: 'error para ${control.x},${control.y}',
      );
    }
  });

  test('la distancia Haversine es simétrica y cero en el mismo punto', () {
    final a = GeoPoint(latitude: -1.369, longitude: -78.648);
    final b = GeoPoint(latitude: -1.368, longitude: -78.647);
    expect(MapGeo.distanceMeters(a, a), closeTo(0, 0.001));
    expect(
      MapGeo.distanceMeters(a, b),
      closeTo(MapGeo.distanceMeters(b, a), 0.001),
    );
  });

  test('rechaza coordenadas geográficas imposibles', () {
    expect(() => GeoPoint(latitude: 91, longitude: 0), throwsArgumentError);
    expect(() => GeoPoint(latitude: 0, longitude: -181), throwsArgumentError);
    expect(
      () => GeoPoint(latitude: double.nan, longitude: 0),
      throwsArgumentError,
    );
  });
}
