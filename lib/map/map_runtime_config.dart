class MapRuntimeConfig {
  const MapRuntimeConfig._();

  static const bool mapsConfigured = bool.fromEnvironment(
    'GOOGLE_MAPS_CONFIGURED',
    defaultValue: false,
  );

  static const String missingKeyMessage =
      'Falta configurar el mapa en este dispositivo.';
}
