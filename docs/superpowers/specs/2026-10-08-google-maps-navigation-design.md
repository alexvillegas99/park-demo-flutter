# Mapa geográfico y navegación peatonal de Mushuc Runa

**Fecha:** 2026-10-08
**Estado:** diseño aprobado en conversación; pendiente de revisión del documento
**Proyecto:** `park-demo-flutter`
**Reemplaza:** el uso del PDF `mapa vectorizado final ACCESOS.pdf` y de
`mushuc_runa_validated.svg` como fondo visible del mapa de visitantes.

## 1. Objetivo

La pantalla Mapa debe comportarse como un mapa geográfico real del Complejo
Mushuc Runa, comparable en interacción a Google Maps: vista híbrida con imagen
satelital y referencias, desplazamiento libre en ambos ejes, zoom fluido,
ubicación actual, puntos de interés, rutas internas y distancias en metros.

El PDF validado se utilizará solamente como fuente de referencia para trasladar
accesos, baños, escenarios y demás lugares a coordenadas geográficas. No se
mostrará como imagen, capa ni superposición en la aplicación para visitantes.

## 2. Criterios de éxito

1. El fondo visible es Google Maps en modo híbrido, no una imagen estática.
2. El mapa admite arrastre vertical y horizontal, pellizco, doble toque y
   controles de zoom sin deformar ni separar los marcadores.
3. La ubicación se actualiza mientras la pantalla está activa y muestra la
   precisión real informada por el dispositivo.
4. Al seleccionar un destino se muestran distancia restante, progreso y ruta
   interna; al desviarse, la ruta se recalcula.
5. El recorrido diario se acumula con muestras GPS válidas y se conserva al
   cambiar de pestaña durante la sesión.
6. Plaza del Sol, Plaza de la Luna y Megaescenario se reconocen de inmediato,
   sin que los demás puntos saturen la vista inicial.
7. Al tocar uno de los tres escenarios se muestra su programación vigente.
8. Solo una sesión con rol administrador puede crear, mover, editar, ocultar o
   eliminar lógicamente puntos y modificar horarios.
9. iOS y Android usan el mismo documento geográfico y producen distancias
   equivalentes para las mismas coordenadas.
10. La ausencia de clave, conexión o permiso de ubicación genera un estado claro
    y recuperable, no una pantalla vacía o bloqueada.

## 3. Alcance

### Incluido

- Sustitución del visor WebView del visitante por `google_maps_flutter`.
- Vista híbrida de Google Maps en iOS y Android.
- Controles visuales, marcadores, rutas, círculo de precisión y tarjetas en
  Flutter.
- Migración determinista del documento actual de puntos desde `x/y` a
  `latitude/longitude`.
- Conservación de la agenda, filtros, búsqueda, Runi y permisos de administrador.
- Editor administrativo sobre el mismo mapa geográfico.
- Persistencia local del documento administrativo mientras no exista backend.
- Pruebas unitarias, de widgets, compilación y simulación GPS.

### No incluido

- Backend, sincronización entre dispositivos o autenticación real.
- Navegación giro a giro generada por Google dentro del recinto.
- Garantía de imágenes satelitales sin conexión.
- Precisión fija de un metro: la app mostrará la precisión que realmente entregue
  el teléfono y filtrará muestras de baja calidad.
- Publicación en App Store o Google Play.

## 4. Tesis visual

El mapa ocupa el espacio principal de la pantalla. La interfaz conserva los
colores corporativos vino, dorado, blanco y verde, pero evita cubrir el terreno
con tarjetas grandes.

- **Encabezado:** búsqueda compacta y botón para desplegar filtros.
- **Marcadores principales:** Plaza del Sol, Plaza de la Luna y Megaescenario
  son más grandes, usan nombre visible y permanecen reconocibles.
- **Marcadores secundarios:** aparecen de acuerdo con filtro, búsqueda o nivel
  de zoom. No se muestran simultáneamente todas las zonas al abrir el mapa.
- **Ubicación:** punto de alto contraste con círculo translúcido de precisión.
- **Navegación:** ruta restante en vino y tramo recorrido en dorado.
- **Tarjeta inferior:** destino, distancia restante, porcentaje, recorrido del
  día y acciones para iniciar o finalizar la ruta.
- **Controles laterales:** mi ubicación, ver todo y zoom; no se duplican los
  controles nativos innecesariamente.

## 5. Tesis de interacción

- Un dedo desplaza el mapa en cualquier dirección.
- Dos dedos controlan zoom y orientación; la vista inicial conserva norte arriba.
- Un toque en un marcador abre su tarjeta.
- Un toque en un escenario incluye la programación del día seleccionado.
- `Iniciar ruta` calcula la ruta peatonal propia desde la ubicación actual.
- `Mi ubicación` recentra sin impedir que el usuario vuelva a explorar.
- `Ver todo` encuadra el recinto completo.
- El mapa no vuelve automáticamente al usuario mientras está explorando; solo
  sigue la ubicación durante una ruta activa o cuando se solicita recentrar.
- En modo administrador, mantener pulsado o elegir `Mover` habilita el arrastre
  del punto seleccionado; el resto del mapa continúa navegable.

## 6. Arquitectura

### 6.1 Pantalla nativa

`MapScreen` dejará de renderizar `assets/map/index.html` para visitantes. Su
estructura será una pila de Flutter:

1. `GoogleMap` como capa inferior.
2. Marcadores, polilíneas y círculos administrados por controladores puros.
3. Encabezado, filtros, métricas y tarjetas como widgets Flutter.
4. Herramientas administrativas visibles solo para el rol autorizado.

El WebView podrá mantenerse temporalmente como herramienta de migración y
comparación durante el desarrollo, pero no formará parte de la experiencia final
del visitante ni será accesible desde la navegación principal.

### 6.2 Componentes

- **`MapDocumentController`:** fuente única de puntos visibles, agenda asociada
  y cambios administrativos.
- **`MapProjection`:** convierte una sola vez los puntos `x/y` heredados a
  latitud y longitud usando los controles ya validados; también calcula
  distancias geodésicas.
- **`MapMarkerController`:** aplica búsqueda, filtros, prioridad, selección y
  visibilidad por zoom.
- **`WalkingRouteGraph`:** red interna en coordenadas geográficas y búsqueda A*.
- **`WalkingNavigationController`:** inicia, actualiza, recalcula y finaliza una
  ruta; expone distancia y progreso.
- **`DailyWalkingTracker`:** acumula recorrido válido por fecha local.
- **`MapLocationController`:** conserva permisos, ciclo de vida y flujo GPS.
- **`MapAdminController`:** autoriza y aplica altas, movimientos, cambios de
  visibilidad y edición de eventos.
- **`MapDocumentStore`:** persistencia local versionada hasta que exista backend.

Cada controlador expone modelos inmutables y no depende de widgets ni del SDK de
Google, para que sus reglas puedan probarse sin abrir un mapa real.

## 7. Modelo de datos

El documento evoluciona a esquema `4`:

```json
{
  "schemaVersion": 4,
  "updatedAt": "2026-10-08T13:00:00Z",
  "places": [
    {
      "id": "plaza-sol",
      "category": "evento",
      "name": "Plaza del Sol",
      "latitude": -1.000000,
      "longitude": -78.000000,
      "isVisible": true,
      "isFeatured": true,
      "venue": "sol",
      "events": []
    }
  ]
}
```

Las coordenadas del ejemplo son ilustrativas y no se utilizarán en producción.
La migración usará exclusivamente los valores reales calculados desde el
documento vigente.

Reglas:

- Latitud entre `-90` y `90`; longitud entre `-180` y `180`.
- Identificadores únicos y estables.
- La eliminación administrativa será lógica (`isVisible=false`) para evitar
  pérdidas accidentales.
- Los escenarios conservan `venue` para vincular programación y Runi.
- El documento conserva `updatedAt` y rechaza versiones anteriores.
- Al migrar, el esquema 3 se conserva como respaldo local recuperable y el
  esquema 4 se valida antes de sustituirlo.

## 8. Flujo de ubicación y distancias

1. La pantalla solicita permiso solo al activarse.
2. `Geolocator` usa `bestForNavigation` y `distanceFilter: 1`.
3. Se rechazan muestras obsoletas, saltos físicamente imposibles y muestras cuya
   precisión no sirve para actualizar ruta o recorrido.
4. El mapa muestra siempre el valor real `± n m`; no afirma precisión de un metro.
5. La distancia directa se calcula geodésicamente.
6. La distancia de navegación se calcula sobre la red peatonal propia.
7. El recorrido diario suma solamente segmentos aceptados y evita doble conteo
   al pausar o reanudar la pantalla.
8. La llegada utiliza un radio dinámico basado en la precisión, con un mínimo
   conservador para no declarar llegada por ruido GPS.

## 9. Rutas internas y externas

### Dentro del complejo

La app utilizará la red peatonal validada. Los nodos y aristas se migrarán a
latitud/longitud; A* continuará calculando la ruta más corta. Las polilíneas se
dibujarán directamente sobre Google Maps.

Si dos muestras consecutivas sitúan al usuario fuera de la ruta más allá del
umbral permitido, se recalcula desde la nueva posición. Un punto sin conexión a
la red muestra una explicación y no inventa una línea recta atravesando edificios.

### Fuera del complejo

La app identifica el acceso visible más cercano y ofrece `Cómo llegar`. La
dirección externa usa Google Maps mediante una URL segura de caminata; al entrar
al perímetro se habilita la ruta interna.

## 10. Programación y Runi

- Los escenarios consultan `ProgrammingController` por su identificador
  `venue`.
- La tarjeta del marcador presenta fecha, hora, artista o actividad y estado.
- Los cambios realizados por administrador se reflejan de inmediato en el mapa
  y en la pestaña Programación.
- Runi solo recomienda lugares visibles y eventos existentes. No recomendará
  Paseo en Tren, Trasbordo ni actividades retiradas.
- Una recomendación puede iniciar la misma selección y ruta que un toque manual
  en el marcador.

## 11. Administración

El editor se integra en la misma pantalla nativa y utiliza el documento
geográfico compartido.

- El modo se habilita únicamente cuando la sesión expone rol `admin`.
- Crear punto toma la coordenada central o la pulsación larga confirmada.
- Mover punto usa un marcador arrastrable y muestra latitud/longitud.
- Editar permite nombre, categoría, icono, visibilidad, relevancia y eventos.
- Ocultar reemplaza el borrado irreversible.
- Antes de guardar se valida el documento completo.
- Cada operación guarda una copia local anterior para restauración.
- En esta fase los cambios son locales al dispositivo; la sincronización
  multiusuario queda para el backend futuro.

## 12. Configuración de Google Maps

La clave no se guardará en Dart, Git, documentación ni logs.

- Android la leerá desde un archivo local ignorado y la inyectará como
  `manifestPlaceholder`.
- iOS la leerá desde un archivo `.xcconfig` local ignorado y la entregará al SDK
  al iniciar.
- Se proporcionarán archivos de ejemplo sin valores.
- Las claves de iOS y Android deben ser distintas y restringirse por bundle ID o
  package name y firma correspondientes.
- Si la clave falta, la app mostrará `Falta configurar el mapa` y no intentará
  presentar una pantalla blanca como si hubiera cargado.

La inspección realizada el 2026-10-08 no encontró una clave de Google Maps en el
repositorio ni una variable de entorno compatible.

## 13. Conectividad y funcionamiento local

Los puntos, agenda, rutas, cálculos, permisos y recorrido diario son locales. El
fondo satelital depende del servicio de Google y de la conectividad. El caché del
SDK puede conservar imágenes vistas recientemente, pero no se considerará una
garantía offline.

Cuando el fondo no esté disponible:

- se mantiene el seguimiento GPS y el cálculo de rutas;
- se presenta un aviso no bloqueante;
- se ofrece una lista de lugares cercanos con metros y acciones;
- no se vuelve a mostrar el PDF como sustituto.

Un mapa satelital garantizado sin conexión requerirá otra fase con un proveedor
que autorice paquetes offline o con cartografía propia licenciada.

## 14. Manejo de errores

- **Permiso denegado:** explicar cómo activarlo; permitir explorar el mapa.
- **GPS apagado:** conservar selección y mostrar acceso a Ajustes.
- **Muestra imprecisa:** mantener el último punto aceptado y mostrar la precisión.
- **Clave ausente o rechazada:** estado de configuración visible; nunca registrar
  el valor.
- **Sin conexión:** mantener funciones locales y lista por distancia.
- **Destino no conectado:** impedir la ruta y explicar que el administrador debe
  conectarlo a la red peatonal.
- **Documento inválido:** conservar la última versión válida y ofrecer restaurar
  respaldo.
- **Evento inválido:** rechazar solamente la edición, sin reemplazar la agenda.

## 15. Seguridad y privacidad

- La ubicación se procesa en el dispositivo y no se transmite a un backend en
  esta fase.
- El seguimiento se detiene cuando la pantalla deja de estar activa.
- No se registran coordenadas personales en consola, archivos o analítica.
- La cuenta administrativa mock no se presenta como seguridad de producción.
- La autorización real de cambios deberá validarse en backend antes del
  lanzamiento público.
- Las claves de Maps se restringen por plataforma; no se usa una clave abierta
  compartida.

## 16. Estrategia de pruebas

### Unitarias

- Migración exacta y repetible de esquema 3 a 4.
- Validación de coordenadas y documentos.
- Distancia geodésica y equivalencia iOS/Android.
- A*, ajuste a la red, recálculo, llegada y destino desconectado.
- Filtro de GPS y acumulación diaria sin saltos falsos.
- Visibilidad por categoría, búsqueda, zoom y prioridad.
- Permisos administrativos y respaldo/restauración.
- Vinculación entre lugares, programación y Runi.

### Widgets

- Encabezado compacto y tarjeta inferior.
- Estado sin permiso, sin GPS, sin clave y sin conexión.
- Selección de escenario y apertura de programación.
- Controles administrativos ocultos para visitantes.
- Marcadores principales accesibles y con etiquetas semánticas.

### Integración

- Compilación iOS y Android con configuración de ejemplo.
- Carga real del mapa con claves locales restringidas.
- Simulación de ubicación en Plaza de la Luna y ruta al Megaescenario.
- Simulación de desviación y recálculo.
- Arrastre administrativo, reinicio y recuperación del punto guardado.
- Inspección visual en iPhone y Android de tamaños equivalentes.

## 17. Migración y retiro del mapa anterior

1. Congelar el esquema 3 actual como entrada de migración.
2. Implementar y probar `MapProjection` y el esquema 4.
3. Migrar puntos y red peatonal a coordenadas reales.
4. Incorporar el SDK y la configuración segura de claves.
5. Construir la pantalla nativa y sus estados de error.
6. Integrar programación, Runi y modo administrador.
7. Verificar GPS y rutas en simuladores.
8. Retirar `mushuc_runa_validated.svg` del `pubspec` y del flujo visible.
9. Conservar el PDF fuera del flujo de ejecución solo como referencia del
   proyecto, sin duplicar la aplicación.
10. No eliminar el visor anterior hasta que la pantalla nueva supere todas las
    pruebas y la revisión visual.

## 18. Condiciones de aceptación visual y funcional

- Al abrir Mapa, el terreno real ocupa el área disponible en menos de tres
  segundos con conexión normal.
- No aparece ninguna parte del PDF ni un fondo blanco amplio.
- Los gestos funcionan sobre toda el área del mapa que no está cubierta por un
  control.
- Los tres escenarios principales se distinguen sin superponerse en la vista
  inicial.
- Los marcadores permanecen anclados a su coordenada durante zoom y movimiento.
- Una ruta iniciada muestra distancia total y restante en metros, además del
  recorrido diario acumulado.
- El usuario puede explorar libremente y regresar a su ubicación con una acción.
- Los cambios administrativos sobreviven al reinicio local y se reflejan en
  programación y recomendaciones.
- Visitantes nunca pueden habilitar controles de edición desde la interfaz.
- No se imprime, versiona ni muestra una clave real de Google Maps.

## 19. Decisiones confirmadas

- Se utilizará Google Maps híbrido como mapa definitivo.
- La implementación se hará sobre la aplicación existente, sin crear otra copia.
- El PDF es referencia de ubicación y no una capa de la interfaz.
- Se mantiene el alcance exclusivamente frontend por ahora.
- El backend y la seguridad administrativa real pertenecen a una fase posterior.
