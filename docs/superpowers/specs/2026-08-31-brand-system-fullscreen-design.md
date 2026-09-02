# Sistema visual oficial y acceso de pantalla completa

Fecha: 2026-08-31
Estado: diseño listo para revisión de Alex

## Objetivo

Hacer que login, registro y onboarding aprovechen toda la pantalla y unificar la
identidad visual de la aplicación Mushuc Runa con los colores documentados en el
manual de marca entregado por Alex. La intervención conserva el repositorio, el
logotipo ya presente, los flujos frontend, el mapa y toda la funcionalidad.

## Fuente de verdad de marca

Para reproducción en pantalla se usarán los valores RGB legibles en el manual:

- vino institucional oscuro: `#5E0000`;
- vino institucional principal: `#7A0708`;
- verde institucional: `#004F18`;
- dorado institucional: `#BEA458`;
- negro institucional: `#0A0203`.

Los fondos claros, líneas y estados suaves serán mezclas derivadas de estos
colores con blanco. No se añadirán tonos principales inventados. Los colores
semánticos que ayudan a distinguir baños, accesos, ubicación, alertas y otras
categorías pueden mantenerse cuando reemplazarlos perjudique la comprensión.

## Sistema tipográfico

La tipografía del manual se aplicará por función y no como una sola fuente para
todo el contenido:

1. **Trajan:** carácter institucional, denominación del complejo, encabezados
   ceremoniales y etiquetas breves en mayúsculas con espaciado amplio. Su estilo
   romano no se usará en párrafos, campos ni botones.
2. **Signboard modificada:** únicamente el nombre expresivo `Mushuc Runa` dentro
   del logotipo o encabezado de marca ya existente. No se extenderá a textos de
   navegación o lectura.
3. **Tipografía de interfaz:** sistema sans serif para formularios, filtros,
   descripciones, horarios, botones y datos. El manual no especifica una fuente
   de cuerpo y la lectura móvil tiene prioridad.

La búsqueda local confirmó que no existen archivos instalables de Trajan o
Signboard dentro del proyecto ni en las bibliotecas tipográficas del equipo. Por
ello, esta versión respetará su jerarquía, caja, espaciado y función sin incluir
archivos propietarios no entregados ni presentar una sustitución como oficial.
El logotipo existente conservará la función de Signboard. Los estilos se
centralizarán para que, si después llegan archivos autorizados, se reemplacen en
un solo punto sin rediseñar las pantallas.

## Arquitectura visual

Se creará una fuente compartida de tokens de marca y roles tipográficos dentro
de `lib/design/`. `ThemeData`, las pantallas de acceso y los componentes de la
aplicación consumirán esos tokens. El HTML del mapa tendrá variables CSS
equivalentes con los mismos valores RGB y la misma jerarquía tipográfica. Así se
evita mantener paletas, pesos y estilos aproximados diferentes.

La marca tendrá tres niveles:

1. Vino para navegación, acciones primarias, estados seleccionados y cabeceras.
2. Dorado para detalles institucionales, foco y jerarquía secundaria.
3. Verde para presencia cultural y estados positivos o de acceso, sin competir
   con la acción principal vino.

El patrón geométrico andino del manual aparecerá como una banda vectorial muy
sutil en cabeceras o separadores. No se usará como textura repetida detrás de
texto ni se intentará reconstruir el sello oficial a partir de fotografías.

## Login y registro

En móvil, la fotografía del complejo ocupará todo el ancho desde el borde
superior. Una hoja blanca con esquinas superiores amplias se superpondrá a la
imagen y llegará hasta el borde inferior de la pantalla. El formulario, Google,
la acción principal, el registro y la nota de demostración pertenecerán a esa
misma superficie. En alturas pequeñas o con teclado, el contenido podrá
desplazarse sin perder campos ni producir desbordamientos.

El registro usará una cabecera institucional vino y la misma hoja blanca hasta
el final. Esto mantendrá continuidad visual sin repetir una segunda portada.

## Onboarding

El fondo superior será vino institucional y contendrá navegación, progreso e
identificación del paso. La pregunta y sus opciones vivirán en una hoja blanca
que empieza debajo de la cabecera y termina en el borde inferior. Las opciones
tendrán al menos 88 px de alto, la opción impar ocupará todo el ancho y el botón
permanecerá visible en la zona inferior. Las respuestas y el retroceso seguirán
funcionando como ahora.

Las transiciones serán breves: entrada suave de la hoja, desplazamiento lateral
entre preguntas y confirmación de color/check al seleccionar. No se añadirán
animaciones ornamentales permanentes.

## Resto de la aplicación

Inicio, Mapa, Paquetes, Comida, Runi, navegación inferior, hojas modales y
acciones compartidas adoptarán los tokens oficiales. Se sustituirán vinos y
dorados aproximados, además de textos oscuros y fondos derivados. El mapa
mantendrá sus pines semánticos, geolocalización, filtros y plano; solo se
alinearán cabeceras, selección, detalles institucionales y superficies.

No se hará una refactorización general de las casi seis mil líneas de
`main.dart`. Se cambiará únicamente la fuente de tokens y los puntos visuales
que todavía usen valores aproximados incompatibles con el manual.

## Validación

- Pruebas de widget a 430 × 932 para demostrar que login, registro y onboarding
  llegan al borde inferior y no desbordan.
- Pruebas existentes de acceso, respuestas, retroceso, navegación, mapa y
  superficies de producto.
- Verificación de `ThemeData` y controles principales usando los colores RGB
  oficiales.
- `flutter test`, `flutter analyze`, prueba JavaScript del mapa y compilación
  iOS para simulador.
- Revisión visual en el iPhone simulado de acceso, onboarding, Inicio y Mapa.

## Fuera de alcance

- Backend, OAuth real, persistencia y credenciales.
- Compra o incorporación de tipografías propietarias no entregadas.
- Reproducción del sello oficial desde una fotografía borrosa.
- Modificación de datos del mapa, eventos mock o georreferencia.
- Creación de otro repositorio, copia, rama, commit, push o despliegue remoto.
