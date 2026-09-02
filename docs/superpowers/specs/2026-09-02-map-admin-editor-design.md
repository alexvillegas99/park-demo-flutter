# Diseño: mapa híbrido y editor administrativo

Fecha: 2026-09-02
Estado: aprobado en diseño visual y arquitectura por Alex
Alcance: frontend local; sin backend, despliegue, commit ni push

## Objetivo

Convertir la pantalla Mapa de la app existente en una experiencia confiable para
visitantes y administradores. El visitante debe ver su ubicación, lugares y
eventos del complejo. El administrador debe poder crear, editar, arrastrar,
ocultar y ordenar puntos, y administrar los eventos asociados a cada lugar.

La app debe conservar una experiencia útil sin datos móviles. Cuando el mapa
satelital online no esté disponible, mostrará automáticamente un plano base
limpio incluido en la aplicación, manteniendo visibles los puntos, eventos y la
ubicación GPS.

## Decisiones aprobadas

- Se modifica la misma app Flutter; no se crea otro proyecto ni otra copia.
- La interfaz administrativa usa la distribución `Lista + mapa`.
- Se retira la ilustración superpuesta del mapa para visitantes.
- La vista online será satelital y usará coordenadas geográficas reales.
- Cada lugar puede contener cero, uno o varios eventos.
- El trabajo actual es solo frontend y utiliza persistencia local.
- El administrador puede importar y exportar un documento JSON versionado.
- El acceso administrador de esta fase es una demostración local y no se
  presenta como seguridad real.

## Arquitectura elegida

### Capas

1. `MapScreen`: experiencia de visitante, filtros, búsqueda, geolocalización y
   detalle de lugares/eventos.
2. `MapAdminScreen`: lista de puntos, mapa editable e inspector del elemento
   seleccionado.
3. `MapRepository`: contrato único para leer, guardar, importar y exportar el
   contenido del mapa.
4. `LocalMapRepository`: implementación inicial en el dispositivo. Persiste el
   documento completo y mantiene una copia de la última versión válida.
5. `MapCanvas`: abstracción que presenta el proveedor satelital online o el
   respaldo offline sin cambiar la lógica de marcadores.

Esta separación permite sustituir `LocalMapRepository` por una implementación
de backend más adelante sin rediseñar las pantallas.

## Modelo de datos

### Lugar

- `id`: identificador estable.
- `name`: nombre visible.
- `category`: evento, acceso, salida, baños, atracción, comida, servicio u otra
  categoría permitida.
- `latitude` y `longitude`: posición geográfica real.
- `offlineX` y `offlineY`: posición normalizada entre 0 y 1 sobre el plano de
  respaldo.
- `iconKey`: icono del catálogo visual de la app.
- `isVisible`: permite ocultar sin eliminar.
- `isFeatured`: resalta Mega Escenario, Plaza de la Luna y Plaza del Sol.
- `events`: lista de eventos asociados.

### Evento

- `id`, `placeId`, `title`, `description`.
- fecha, hora inicial y hora final.
- `status`: borrador, publicado o cancelado.
- imagen local o URL opcional.
- información complementaria opcional: artista, capacidad o recomendaciones.

Solo los lugares visibles y los eventos publicados aparecen en el mapa del
visitante. Los borradores permanecen disponibles en el editor.

### Documento local

El repositorio guarda un documento versionado con:

- versión del esquema;
- fecha de modificación;
- lista de lugares y eventos;
- última selección de filtros relevante;
- indicador de contenido válido.

La importación valida todo el documento antes de reemplazar el contenido. Si
falla, conserva intacta la última copia válida.

## Experiencia del visitante

- El mapa ocupa el área principal y aparece sin la ilustración superpuesta.
- Los filtros mantienen `Todos` y las categorías existentes.
- Mega Escenario, Plaza de la Luna y Plaza del Sol usan marcadores más grandes y
  conservan prioridad visual.
- Al seleccionar un lugar se muestran sus datos y su programación publicada.
- El indicador `Estás aquí` permanece visible cuando existe permiso y lectura
  GPS válida.
- La precisión configurada se mantiene en navegación y actualización aproximada
  de un metro, entendiendo que la precisión real depende del dispositivo, señal
  y entorno.

## Experiencia administrativa

- El acceso aparece en un punto separado del flujo normal de visitantes.
- La sesión local de demostración puede cerrarse y no concede seguridad real.
- La columna de lista incluye búsqueda, categorías y estado visible/oculto.
- Seleccionar un lugar centra el mapa y abre su inspector.
- El marcador seleccionado puede arrastrarse; durante el movimiento se muestran
  latitud y longitud.
- Cada movimiento dispone de `Deshacer` antes de guardar.
- `Nuevo punto` crea un borrador y exige nombre, categoría y posición.
- El inspector permite editar datos del lugar y crear, editar, publicar,
  cancelar u ocultar sus eventos.
- No se elimina contenido de forma irreversible: un lugar se oculta o archiva.
- `Guardar borrador` persiste localmente; `Publicar localmente` actualiza lo que
  verá el modo visitante de ese dispositivo.
- `Exportar JSON` genera un archivo para respaldo o entrega al futuro backend.
- `Importar JSON` muestra un resumen y requiere confirmación antes de aplicar.

## Funcionamiento online y offline

### Con internet

- Se usa `google_maps_flutter` con tipo satelital.
- La clave de Google Maps se configura fuera del código y se restringe por
  identificadores de iOS y Android. No se guarda una clave real en el repositorio.
- Los marcadores, filtros y eventos provienen siempre del repositorio local; no
  dependen de la descarga de los mosaicos del mapa.

### Sin internet o con error de mosaicos

- No se confía en la caché temporal de Google Maps.
- Se presenta el mapa base limpio ya incluido en la aplicación.
- Los marcadores se proyectan mediante `offlineX/offlineY`.
- Los puntos, eventos, filtros y búsquedas siguen disponibles.
- El GPS puede continuar actualizando `Estás aquí`; la conversión al plano
  offline utiliza límites geográficos calibrados para el recinto.
- La navegación externa y datos de calles se marcan como no disponibles si
  requieren internet.

El mapa base actual puede utilizarse en la demostración. Antes de distribuir la
app públicamente debe confirmarse que la imagen aérea incluida cuenta con
licencia de uso; no se empaquetarán capturas descargadas de Google Maps o Google
Earth.

## Cambio automático de proveedor

El estado del mapa puede ser `loading`, `online`, `offline` o `error`.

1. La pantalla presenta de inmediato el respaldo offline y sus marcadores.
2. Si existe configuración de Google Maps, inicializa el mapa online en paralelo.
3. Al recibir la primera representación válida, sustituye suavemente el respaldo
   por el mapa satelital.
4. Si el proveedor falla o supera el tiempo de espera, mantiene el respaldo sin
   bloquear la pantalla.
5. Un mensaje breve informa `Mapa sin conexión`; no interrumpe las demás
   funciones.

Esto elimina la demora con un área vacía al abrir Mapa.

## Calibración de puntos

Cada lugar conserva coordenadas geográficas y coordenadas normalizadas de
respaldo. Al arrastrar en el mapa online se actualiza la posición geográfica y se
recalcula la posición offline. Al arrastrar sobre el mapa offline se realiza la
operación inversa usando los límites calibrados del recinto.

La migración inicial convierte los puntos actuales basados en píxeles a
coordenadas normalizadas. Después, el administrador corrige visualmente los
puntos importantes sobre el mapa satelital.

## Manejo de errores

- Permiso GPS denegado: explica cómo habilitarlo y permite usar todo el mapa.
- GPS temporalmente no disponible: conserva la última posición con una etiqueta
  de antigüedad; nunca inventa una posición.
- Mapa online no disponible: respaldo offline automático.
- Documento local corrupto: restaura la última copia válida o el contenido
  inicial empaquetado.
- Importación inválida: muestra los campos rechazados y no cambia datos.
- Guardado incompleto: conserva el borrador en memoria y permite reintentar.
- Evento con horario inválido: impide publicar, pero permite guardarlo como
  borrador.

## Pruebas de aceptación

1. La pantalla muestra contenido útil de inmediato, incluso sin red.
2. Activar y desactivar internet no elimina puntos ni eventos.
3. La ubicación del usuario se actualiza en online y offline cuando hay GPS.
4. Los tres escenarios principales mantienen marcadores destacados.
5. Cada filtro muestra únicamente la categoría correspondiente y `Todos`
   restablece el conjunto completo.
6. Un administrador puede crear un punto, arrastrarlo, deshacer y guardarlo.
7. Puede crear dos eventos en un mismo lugar y publicar solo uno.
8. El visitante ve únicamente lugares visibles y eventos publicados.
9. Cerrar y abrir la app conserva los cambios locales.
10. Exportar e importar el mismo JSON reproduce el contenido.
11. Un JSON inválido no modifica la última versión válida.
12. La ausencia de clave de Google Maps activa el respaldo offline sin fallar.
13. Las pruebas se ejecutan en iOS y Android, incluyendo modo avión.

## Fuera de alcance en esta fase

- Autenticación administrativa segura.
- Sincronización entre teléfonos o publicación remota inmediata.
- Backend, base de datos remota y panel web independiente.
- Descarga masiva de mosaicos de Google para uso offline.
- Rutas peatonales precisas dentro del recinto; requieren una fase posterior de
  trazado y validación en campo.

## Resultado esperado

La app abre siempre con un mapa utilizable, conserva la geolocalización y los
datos esenciales sin conexión, y brinda al administrador un editor claro para
mantener lugares y eventos. La estructura queda preparada para que otro equipo
conecte autenticación y backend sin rehacer la interfaz.
