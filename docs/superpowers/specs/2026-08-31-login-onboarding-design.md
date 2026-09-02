# Acceso y onboarding Mushuc Runa — Especificación de diseño

## Objetivo

Anteponer a la aplicación existente un recorrido frontend agradable que permita
iniciar sesión visualmente, crear una cuenta de demostración y responder tres
preguntas de preferencias antes de entrar a Inicio.

## Alcance y límites

- El trabajo se realiza sobre `/Users/afnaranjo/traiding/park-demo-flutter`.
- No se crea otra copia, rama o proyecto.
- No se añade backend, Firebase, OAuth, red ni credenciales.
- `Continuar con Google` es un punto de integración visual: en esta fase abre el
  onboarding y no afirma que Google haya autenticado al usuario.
- Los datos viven solo durante la ejecución actual. No se guardan contraseñas ni
  respuestas en disco.
- La navegación, el mapa, la geolocalización y las pantallas actuales se
  conservan.

## Tesis visual

La bienvenida debe sentirse como la entrada a una experiencia familiar y no
como un formulario corporativo. Se utilizará un lienzo marfil, una fotografía
local de una atracción como apertura, un bloque vino sólido y acentos dorados.
La interfaz conservará los radios y la tipografía robusta de la app actual, con
una sola acción primaria visible por paso y sin agregar nuevos degradados.

## Contenido

### Acceso

- Marca `Mushuc Runa` y mensaje `Tu aventura comienza aquí`.
- Acción `Continuar con Google`.
- Campos `Correo` y `Contraseña` para una demostración de inicio existente.
- Acción `Iniciar sesión`.
- Enlace `Crear una cuenta`.
- Una nota discreta informa que esta versión es una demostración visual.

### Registro

- Campos obligatorios: nombre, correo, contraseña y confirmación.
- Validación local de correo, mínimo de seis caracteres y coincidencia de
  contraseñas.
- Ningún valor se persiste ni sale del dispositivo.

### Onboarding

1. `¿Qué te trae a Mushuc Runa?` permite una o más selecciones entre Shows,
   Conciertos, Granja, Atracciones y Todo.
2. `¿Cuántas veces nos has visitado?` permite una selección entre Primera vez,
   1 vez, 2 veces, 3 veces y Más de 3.
3. `¿Qué te haría recomendar nuestra experiencia?` permite una o más selecciones
   entre Diversión familiar, Espectáculos, Organización, Atención y Variedad.

Cada pregunta muestra progreso, retroceso y una acción `Continuar` o `Terminar`.
No se puede avanzar sin responder.

## Interacción

- Google abre el onboarding con el nombre provisional `Visitante`.
- Crear una cuenta validada abre el onboarding usando el primer nombre escrito.
- Iniciar sesión validado abre Inicio y deriva un saludo del correo.
- Al terminar el onboarding, Inicio muestra `¡Hola, <nombre>!`.
- Los cambios de etapa usan transiciones breves de opacidad y desplazamiento.
- La interfaz evita desbordamientos con teclado, respeta SafeArea y ofrece áreas
  táctiles de al menos 44 puntos.

## Accesibilidad y estados

- Controles con etiquetas claras, contraste alto y estado seleccionado visible
  mediante color, borde e icono.
- Errores se presentan junto al campo correspondiente.
- Botones bloqueados usan contraste suficiente y no responden al toque.
- El gesto o botón Atrás nunca cierra la app desde una etapa interna: vuelve a
  la etapa anterior.

## Criterios de aceptación

- La app inicia en Acceso, no en Inicio.
- Google y Crear cuenta llegan al primer paso del onboarding.
- Registro impide avanzar con datos inválidos.
- Las tres preguntas aparecen en orden y bloquean el avance sin respuesta.
- Terminar abre la app existente con saludo personalizado.
- Iniciar sesión local abre la app sin ejecutar el onboarding.
- Las pruebas anteriores de Inicio, Mapa, Paquetes, Comida y geolocalización
  continúan pasando.
- `flutter analyze`, `flutter test` y `flutter build ios --simulator` terminan
  correctamente.
