import 'package:geolocator/geolocator.dart';

class MapExperienceConfig {
  const MapExperienceConfig._();

  static const bool bundledMapFirst = true;
  static const bool remoteFontsEnabled = false;
  static const String demoAdminEmail = 'admin@mushucruna.demo';
}

class FairLocation {
  const FairLocation._();

  // Centro calculado con la misma georreferencia usada por el plano 1900×1018.
  static const double latitude = -1.3690877425784418;
  static const double longitude = -78.647792380582;
  static const double radiusMeters = 900;
  static const LocationSettings initialLocationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
  );
  static const LocationSettings trackingLocationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 1,
  );
}
