# Mapa híbrido y navegación peatonal Mushuc Runa

Fecha: 2026-10-08
Estado: aprobado por Alex para planificación el 2026-10-08
Alcance: frontend local para iOS y Android, sin backend

## 1. Objetivo

Convertir la pantalla `Mapa` en un navegador del recinto que use como fuente
visual y operativa el PDF validado `mapa vectorizado final ACCESOS.pdf`. La
persona debe poder explorar el plano completo, ver su ubicación, seleccionar un
destino, conocer la distancia restante, seguir una ruta peatonal interna y
consultar los metros recorridos durante el día.

Los lugares administrados seguirán siendo la fuente de verdad de los
marcadores. Mover, crear, ocultar o editar un punto debe reflejarse de inmediato
en la vista visitante, el cálculo de rutas y las recomendaciones de Runi dentro
de la misma instalación.

## 2. Límites de esta versión

- El seguimiento funciona mientras `Mapa` está visible. No se solicita
  ubicación permanente ni ejecución en segundo plano.
- La navegación interior debe funcionar sin internet después de instalar la
  aplicación.
- La navegación exterior depende de conexión. Sin conexión se mostrará
  orientación aproximada hacia el acceso recomendado, no una ruta vial falsa.
- La persistencia continúa siendo local a cada instalación. Sin backend, los
  cambios administrativos no se distribuyen a otros teléfonos.
- La precisión de un metro es un filtro solicitado al sistema operativo, no una
  garantía física. La interfaz debe mostrar la precisión reportada y usar
  lenguaje aproximado cuando corresponda.
- No se reemplaza el mapa por una copia del proyecto ni se altera el PDF fuente.

## 3. Fuente cartográfica y calibración

### 3.1 Plano oficial

El PDF vectorial validado contiene seis accesos, baños, estacionamientos,
zonas, plazas, entretenimiento, patios de comida y recorridos internos. Aunque
el arte recibido dibuja estaciones de trasbordo, Alex confirmó que ese servicio
no existe en el recinto: sus puntos y filtro se excluyen de la app. Se exportará
una versión SVG optimizada, conservando el PDF original intacto.

La experiencia principal utilizará el área útil del recinto. La leyenda completa
seguirá disponible mediante un control `Leyenda`, evitando reducir el mapa para
mostrar permanentemente márgenes editoriales.

### 3.2 Sistema de coordenadas

La aplicación mantendrá un sistema de coordenadas lógico independiente del
tamaño de pantalla. Se calibrarán al menos cuatro puntos de control compartidos
entre el mapa vigente y el plano validado: Acceso 1, Acceso 3, Acceso 5 y Acceso
6. Con ellos se ajustará por mínimos cuadrados una transformación afín para
migrar marcadores, georreferencia y red peatonal sin reposicionar manualmente
cada punto. Tres puntos no colineales resuelven la transformación y el cuarto
permite medir el error residual; si el error supera la tolerancia visual, se
debe corregir la calibración antes de publicar el plano.

La transformación debe ser reversible:

- latitud/longitud a coordenada del plano;
- coordenada del plano a latitud/longitud;
- coordenadas antiguas a coordenadas del nuevo plano.

Las pruebas deben incluir los cuatro accesos de control y un punto interior.

La revisión técnica del plano confirmó que el ajuste afín deja un error grande
en algunos accesos del documento legado. Por eso la migración no aplicará una
transformación ciega: los puntos estándar que no fueron movidos adoptarán la
coordenada oficial del nuevo plano; los puntos personalizados o desplazados se
proyectarán como aproximación y quedarán marcados `Revisar ubicación` en el
panel administrativo hasta que se validen. Sus nombres, eventos, visibilidad y
demás datos se conservarán.

## 4. Experiencia visual

### 4.1 Tesis visual

Un plano institucional nítido y vivo, tratado como una superficie de navegación
profesional: marfil para el espacio, vino para el recorrido, dorado para el
progreso y verde para ubicación y estados positivos.

### 4.2 Composición

- El mapa ocupa toda la pantalla disponible detrás de la navegación inferior.
- El encabezado conserva búsqueda y filtros, pero se vuelve más compacto al
  iniciar una ruta.
- La ubicación, precisión y recorrido del día aparecen en una banda discreta.
- La ficha del destino es una hoja inferior compacta con nombre, distancia,
  tiempo estimado y acción `Iniciar ruta`.
- Durante la navegación, la hoja muestra `Restan N m`, avance, precisión y
  acciones `Recentrar` y `Finalizar`.
- La leyenda del PDF se abre bajo demanda; no compite con la superficie del
  mapa.

### 4.3 Interacción

- Arrastre libre horizontal y vertical, sin el bloqueo actual de cobertura.
- Zoom por pinza y botones, con límites que permiten ver el plano completo y
  acercarse a un acceso o servicio.
- Recentrado animado sobre la persona, el destino o la ruta completa.
- La ruta usa línea vino con borde claro; el tramo ya recorrido cambia a dorado.
- Los cambios de destino y recalculado usan transiciones breves, sin animación
  ornamental.

## 5. Componentes y responsabilidades

### 5.1 `MapDocumentController` en Flutter

Mantiene durante la sesión una copia validada del documento administrativo de
lugares. Recibe el documento desde el WebView por un canal
`FlutterMapDocument`, notifica cambios a Runi y puede reinjectarlo cuando el
WebView termine de cargar.

No reemplaza la persistencia local del editor en esta fase; la coordina con el
resto de la aplicación.

### 5.2 `MapAdminDocument` en JavaScript

Continúa validando y guardando puntos y eventos. Después de cada mutación válida
debe emitir el documento completo y su marca de tiempo. Esto incluye:

- mover y deshacer un marcador;
- crear un lugar;
- editar nombre, categoría, visibilidad o destacado;
- importar o restaurar un documento;
- crear o editar eventos.

La interfaz administrativa mostrará `Cambios aplicados en la app` cuando el
documento se haya guardado y emitido.

### 5.3 `MapViewportModel`

Sustituye el ajuste de cobertura que bloquea el movimiento vertical. El estado
incluye escala, desplazamiento y modo de encuadre. Debe admitir:

- `ver todo`, que contiene el plano completo;
- `llenar`, para navegación cercana;
- margen de desplazamiento controlado para no perder el plano;
- centrado de punto, ruta y ubicación.

### 5.4 `WalkingRouteGraph`

Representa los caminos peatonales internos como nodos y aristas con distancias
en metros. Los puntos de interés se conectan al nodo caminable más cercano.

El cálculo usa A* con peso métrico. Una ruta válida devuelve:

- secuencia de coordenadas para la polilínea;
- distancia total y restante;
- nodo de acceso recomendado cuando el origen está fuera;
- advertencia si un punto administrado está demasiado lejos de la red.

La red se versionará en un archivo separado para poder corregir recorridos sin
reescribir la vista.

### 5.5 `DailyWalkTracker`

Acumula distancia únicamente con muestras válidas mientras el mapa esté activo.
El filtro debe:

- rechazar coordenadas sin antigüedad o precisión aceptable;
- ignorar desplazamientos mínimos compatibles con ruido;
- descartar saltos incompatibles con velocidad peatonal;
- evitar sumar dos veces la misma muestra;
- reiniciar el total al cambiar la fecha local;
- persistir fecha y metros en almacenamiento local.

La interfaz mostrará `Recorrido estimado`, nunca una medición certificada.

## 6. Flujo de navegación interior

1. Flutter solicita ubicación al abrir `Mapa` y entrega las muestras al WebView.
2. La posición se transforma al sistema del plano.
3. La persona selecciona un lugar o pulsa un marcador.
4. La ficha muestra la distancia por ruta cuando existe; mientras no haya ruta,
   puede mostrar distancia directa marcada con `≈`.
5. `Iniciar ruta` conecta origen y destino a la red peatonal y calcula A*.
6. Cada muestra válida actualiza el marcador, el tramo recorrido, la distancia
   restante y el contador diario.
7. Si la persona se separa más de 15 m de la polilínea en dos muestras válidas
   consecutivas, se recalcula desde el nodo seguro más cercano. Una sola muestra
   no provoca saltos de ruta.
8. Al entrar en un radio de llegada entre 6 y 15 m, ajustado por la precisión de
   la muestra, la app muestra `Llegaste` y permite finalizar.

## 7. Flujo desde fuera del recinto

Cuando la coordenada está fuera de la geocerca, la aplicación no debe conservar
un marcador interior obsoleto. Debe cambiar a estado `Fuera del recinto`,
ocultar el marcador anterior y mostrar:

- distancia directa aproximada al complejo;
- acceso recomendado según la red y el lado de aproximación;
- acción `Cómo llegar`.

Con internet, `Cómo llegar` abre una pantalla WebView propia de la aplicación
con una URL HTTPS universal de Google Maps hacia el acceso recomendado y modo
peatonal. La navegación bloquea esquemas externos para no sacar silenciosamente
a la persona de la app. Esta ruta exterior es independiente de la red peatonal
interna. Si Google redirige a una aplicación externa, la página no carga o no
existe conexión, la app conserva la orientación aproximada y muestra una acción
explícita para abrir el navegador del sistema, sin hacerlo automáticamente.

La integración mediante URL no debe confundirse con Google Maps SDK ni con
Navigation SDK. Una futura versión con satélite nativo, polilíneas integradas y
navegación exterior completa requerirá proyecto de Google Cloud, facturación y
claves restringidas por plataforma.

## 8. Administración y coherencia de puntos

Los puntos siguen viéndose como están hoy, pero con iconografía consistente con
el PDF y mejor contraste. Los tres escenarios principales conservan mayor
jerarquía.

Cuando el administrador mueve un punto:

1. se guarda en `MapAdminDocument`;
2. el marcador visitante se actualiza inmediatamente;
3. se emite el documento a Flutter;
4. Runi recibe la nueva coordenada;
5. el destino se conecta al nodo caminable más cercano;
6. si queda fuera de tolerancia, el panel muestra una advertencia y no inventa
   una conexión directa.

Los puntos ocultos no aparecen como destino ni participan en Runi. Los eventos
publicados conservan el comportamiento actual.

## 9. Datos y persistencia

- `mr_map_document_v3`: lugares y eventos administrados en el sistema de
  coordenadas del plano validado. La versión 2 se conserva como respaldo de
  migración y no se sobrescribe.
- `mr_fair_programming_v1`: programación diaria.
- `mr_route_graph_v1`: identificador de la red empaquetada como activo de la
  app; no es una clave de `localStorage` ni es editable por el visitante.
- `mr_walk_day_v1`: fecha local, metros estimados y última muestra aceptada.
- `mr_navigation_state_v1`: destino y ruta activa para recuperación breve tras
  recrear el WebView.

Los documentos se validan antes de aplicarse. Un documento inválido conserva la
última versión válida y muestra un estado no destructivo.

### 9.1 Umbrales iniciales de seguimiento

Los valores se centralizan como constantes para poder ajustarlos después de la
prueba física, pero la primera implementación y sus pruebas usan:

- antigüedad máxima de muestra: 10 s;
- precisión horizontal aceptable para ruta: 35 m;
- precisión horizontal aceptable para sumar recorrido: 20 m;
- desplazamiento mínimo acumulable: 2 m;
- velocidad peatonal máxima aceptada: 3,5 m/s;
- separación para recalcular ruta: 15 m durante dos muestras consecutivas;
- tolerancia para conectar un punto administrado a la red: 35 m;
- radio de llegada: `max(6 m, min(precisión, 15 m))`.

Estos umbrales reducen ruido sin comunicar una exactitud inexistente. La prueba
en el recinto podrá endurecerlos, pero no se bajará a 1 m como promesa de
precisión.

## 10. Estados de error y seguridad

- Permiso denegado: mapa exploratorio disponible, sin seguimiento.
- Ubicación imprecisa: círculo de precisión y etiqueta `Precisión baja`; no se
  acumula recorrido con esa muestra.
- Fuera del recinto: eliminar inmediatamente el marcador interior anterior.
- Sin internet: navegación interior continúa; la ruta exterior no se abre.
- Punto fuera de la red: advertencia administrativa y distancia directa
  aproximada para visitante.
- Documento local corrupto: recuperar respaldo, sin eliminar automáticamente la
  configuración existente.
- El acceso administrativo local sigue siendo demostrativo; no se presenta como
  seguridad de producción.

## 11. Pruebas de aceptación

### 11.1 JavaScript

- El encuadre `ver todo` permite visualizar el plano completo en 430 x 932.
- Tras acercar, el plano puede desplazarse en ambos ejes sin desaparecer.
- A* produce una ruta válida entre Plaza de la Luna y Megaescenario.
- La distancia de ruta es mayor o igual que la distancia directa.
- Una posición fuera del recinto limpia el marcador interior.
- El contador rechaza ruido, saltos y muestras imprecisas.
- La ruta no se recalcula por una única muestra desviada y sí se recalcula tras
  dos muestras consecutivas a más de 15 m.
- El contador persiste durante el mismo día y se reinicia al cambiar la fecha.
- Toda mutación administrativa emite el documento actualizado.

### 11.2 Flutter

- `FlutterMapDocument` reemplaza solo documentos válidos.
- Runi usa la coordenada administrada y excluye lugares ocultos.
- La geolocalización comienza solo cuando `Mapa` es visible.
- La vista exterior abre la URL HTTPS correctamente codificada dentro de la app,
  bloquea esquemas externos y ofrece salida explícita al navegador si falla.
- iOS y Android incluyen permisos y configuración necesarios sin ubicación en
  segundo plano.

### 11.3 Simulador y revisión visual

- Instalar y abrir en iPhone 17 Pro Max simulado.
- Simular Plaza de la Luna, iniciar ruta a Megaescenario y avanzar por varios
  puntos de la polilínea.
- Confirmar actualización de metros restantes y recorrido diario.
- Simular una coordenada exterior y comprobar que desaparece el marcador viejo.
- Revisar plano completo, leyenda, accesos, baños y escenarios contra el PDF.
- Ejecutar la misma suite de lógica para Android y compilar cuando el SDK local
  esté disponible.

## 12. Entrega de la primera implementación

La primera entrega queda completa cuando:

- el plano validado se renderiza nítido y sin recorte;
- el usuario puede desplazarse y hacer zoom como en un mapa;
- la ubicación en vivo se representa con calidad visible;
- Plaza de la Luna a Megaescenario tiene una ruta peatonal trazada;
- distancia restante y recorrido diario cambian con posiciones simuladas;
- el editor actualiza destinos y Runi en la misma sesión;
- el modo interior funciona sin red;
- el flujo exterior tiene degradación clara y no inventa precisión.

## 13. Pendientes posteriores

- Backend con autenticación y sincronización entre dispositivos.
- Google Maps SDK o proveedor cartográfico equivalente para satélite nativo.
- Routes API o Navigation SDK para navegación exterior completamente integrada.
- Validación física de calibración, caminos y precisión dentro del complejo.
- Seguimiento en segundo plano, solo si se aprueba su necesidad, privacidad y
  consumo de batería.
