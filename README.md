# Mushuc Runa · app móvil

Prototipo Flutter de la experiencia para visitantes del Complejo Mushuc Runa.
Incluye inicio de sesión local, perfil de visita, recomendaciones de Runi,
programación, Google Maps híbrido, ubicación en tiempo real, navegación peatonal
dentro del recinto y edición administrativa local.

## Ejecutar el proyecto

```bash
flutter pub get
flutter run
```

Sin una clave local, la app compila y muestra un estado recuperable en la pestaña
Mapa. Los puntos guardados, la programación y el resto de la app continúan
disponibles.

## Configurar Google Maps localmente

Esta configuración la realiza una sola vez el equipo de desarrollo por cada
entorno de compilación. Los visitantes no instalan claves ni ven esta pantalla:
la app distribuida ya lleva la configuración necesaria dentro del binario.

Las claves deben crearse en Google Cloud; no son contraseñas personales. Una
clave API de Google válida normalmente empieza por `AIza`. Las claves reales
nunca se guardan en Git.

### Android

1. Copia `android/secrets.properties.example` como
   `android/secrets.properties`.
2. Completa `GOOGLE_MAPS_API_KEY` con una clave restringida al identificador de
   Android `com.parkdemo.park_demo`, su certificado de firma y la API Maps SDK
   for Android.

### iOS

1. Copia `ios/Flutter/GoogleMapsSecrets.xcconfig.example` como
   `ios/Flutter/GoogleMapsSecrets.xcconfig`.
2. Completa `GOOGLE_MAPS_API_KEY` con una clave restringida al bundle de iOS y a
   la API Maps SDK for iOS. El bundle actual es
   `com.parkdemo.parkDemo`.

Ejecuta la app indicando que la configuración ya existe:

```bash
flutter run --dart-define=GOOGLE_MAPS_CONFIGURED=true
```

## Comportamiento del mapa

- La capa visual es Google Maps en modo híbrido; el PDF y el plano vectorizado
  solo se conservan como referencias de validación y no se muestran ni se
  empaquetan en la app.
- La precisión visible corresponde a la exactitud reportada por el dispositivo.
  El filtro acepta muestras de hasta 5 metros cuando el hardware y el entorno lo
  permiten; no promete una precisión física de 1 metro.
- La ruta dentro del complejo usa una red peatonal local, recalcula al desviarse,
  muestra metros restantes y acumula el recorrido diario.
- Sin conexión permanecen disponibles los puntos y rutas precargados. Las
  imágenes satelitales dependen de la caché disponible del SDK de Google.
- Los cambios del administrador se validan, guardan localmente y conservan un
  respaldo recuperable.

## Acceso administrativo de demostración

El correo local `admin@mushucruna.demo` habilita el editor del prototipo. Este
rol es únicamente de frontend y no reemplaza autenticación ni autorización de
backend para producción.

## Verificación

```bash
flutter analyze --no-pub
flutter test
node test/map_geometry_test.mjs
node test/walking_navigation_test.mjs
node test/location_tracker_test.mjs
node test/map_admin_editor_test.mjs
```
