# Cuenta, privacidad y preparación para revisión

**Fecha:** 2026-09-02
**Estado:** aprobado en conversación; pendiente validación del documento
**Alcance:** frontend local de la app Flutter existente

## Objetivo

Añadir una experiencia de cuenta clara y verificable que permita entrar como
visitante, cerrar sesión, eliminar la cuenta o los datos locales, entender y
administrar el permiso de ubicación, consultar privacidad y términos, y acceder
a ayuda. La implementación debe ser honesta con el estado del producto: todavía
no existe backend, autenticación real ni sitio web seguro para eliminación.

## Decisiones confirmadas

- Se modifica únicamente la app existente; no se crea otra copia.
- `Sign in with Apple` queda fuera de esta versión por decisión de Alex.
- El acceso de Google se mantiene identificado como demostración visual y no se
  presenta como autenticación real.
- Se añade `Continuar como visitante`, porque las funciones informativas y el
  mapa pueden usarse sin una cuenta.
- El cierre y la eliminación actúan sobre el estado local de la demostración.
- La configuración administrativa del mapa no es información de la cuenta del
  visitante y no se elimina al borrar una sesión personal.
- No se enlaza `complejomushucruna.ec`: al 2026-09-02 redirige a contenido ajeno.
- No se inventan correo, teléfono, URL de soporte ni URL externa de eliminación.
  Esos datos se registran como bloqueadores de publicación hasta que el titular
  de la marca los confirme y se publiquen en HTTPS.

## Base de cumplimiento

La solución prepara la interfaz para los requisitos actuales de App Store y
Google Play, pero no promete aprobación. Apple exige que una app que crea
cuentas permita iniciar su eliminación dentro de la app y mantenga privacidad y
soporte accesibles. Google exige además una URL web externa para solicitar
eliminación y completar la declaración de seguridad de datos. El backend, la
revocación de proveedores, las páginas públicas y la metadata de las tiendas
quedan fuera del frontend actual y deben completarse antes de enviar la app.

## Tesis visual

Una superficie editorial sobria en marfil, blanco, vino, verde y oro, con
tipografía institucional, divisores ligeros y acciones fáciles de escanear. La
cuenta se siente integrada con la marca y no como un panel genérico de tarjetas.

## Plan de contenido

1. Encabezado: identidad del visitante o de la cuenta local y estado de sesión.
2. Privacidad y permisos: ubicación, datos conservados en el dispositivo y
   control para abrir los ajustes del sistema.
3. Ayuda y documentos: soporte, política de privacidad y términos de uso.
4. Sesión: cerrar sesión y zona sensible para eliminar la cuenta o datos locales.

## Tesis de interacción

- La pantalla entra con una transición breve desde el avatar del encabezado.
- Las filas muestran respuesta táctil y los documentos aparecen como páginas
  completas, no como diálogos pequeños.
- Cerrar sesión y eliminar usan confirmaciones claras; eliminar requiere dos
  decisiones consecutivas, sin campos engañosos ni obstáculos excesivos.

## Arquitectura

### `AccessSession`

Modelo inmutable con `displayName`, `email`, `isGuest` y `provider`. El proveedor
solo puede ser `guest`, `local` o `googleDemo`. No contiene tokens ni secretos.

### `AccessGate`

Continúa siendo propietario de la sesión local. Su `appBuilder` recibirá la
sesión y dos acciones:

- `signOut()`: limpia campos sensibles y vuelve al acceso.
- `deleteLocalAccount()`: limpia campos, respuestas del cuestionario y sesión;
  luego vuelve al acceso con un aviso de eliminación local completada.

También ofrecerá `Continuar como visitante`, que entra directamente como
`Visitante` sin contestar el cuestionario.

### `AccountScreen`

Página completa abierta desde un nuevo botón semántico `Abrir cuenta` en el
encabezado de Inicio. Recibe `AccessSession`, callbacks de sesión y una interfaz
pequeña para leer el permiso de ubicación y abrir los ajustes del sistema.

La pantalla se divide mediante títulos y divisores, con una sola tarjeta de
identidad porque allí la tarjeta sí representa el objeto interactivo principal.

### Documentos integrados

`PrivacyPolicyScreen` y `TermsOfUseScreen` se incluyen dentro del paquete para
que siempre abran, incluso sin internet. Sus textos describen únicamente la
demostración actual:

- nombre, correo y respuestas permanecen en memoria durante la sesión;
- el mapa administrativo conserva configuración local del recinto;
- la ubicación se solicita al abrir el mapa, se representa en pantalla y no se
  conserva como historial por esta app;
- `Cómo llegar` puede transferir origen/destino a Apple Maps o Google Maps tras
  una acción explícita;
- no existen pagos, analítica, publicidad ni backend en esta versión;
- cualquier incorporación futura exige actualizar el documento y la declaración
  de las tiendas antes de publicar.

Los documentos se etiquetan como `Versión de demostración · 2 de septiembre de
2026`. No sustituyen la revisión jurídica ni las URLs públicas requeridas para
distribución.

### Soporte

`SupportScreen` ofrece ayuda funcional offline: preguntas frecuentes sobre
acceso, ubicación, mapa y eliminación, además de una sección visible
`Contacto oficial pendiente de confirmación`. No abre enlaces inseguros ni
presenta datos no verificados. El checklist de lanzamiento señalará que Apple
requiere una Support URL funcional y Google una URL externa de eliminación.

### Eliminación

Para una cuenta local, la acción se llama `Eliminar cuenta local`; para invitado,
`Borrar datos de esta sesión`. La primera pantalla explica qué se elimina y qué
no. El botón sensible abre una confirmación final que nombra la acción. Al
confirmar:

1. se limpian nombre, correo, contraseñas y respuestas en memoria;
2. se cierra la sesión;
3. se muestra el acceso con un aviso de éxito;
4. no se toca el documento administrativo del mapa.

Cuando exista backend, el mismo callback deberá esperar confirmación del servidor
antes de mostrar éxito. Si falla, la sesión permanece abierta y se muestra un
mensaje reintentable.

## Estados y errores

- Ubicación: `No solicitado`, `Permitido`, `Limitado` o `Bloqueado`.
- Si no puede abrirse Ajustes, aparece un mensaje local y la pantalla sigue útil.
- Los documentos siempre están disponibles porque son widgets incluidos.
- Cerrar un diálogo no ejecuta acciones sensibles.
- La eliminación no puede dispararse con un solo toque accidental.

## Accesibilidad

- Objetivos táctiles de al menos 44 × 44 puntos.
- Etiquetas semánticas para cuenta, cierre, eliminación, documentos y permisos.
- El color no es el único indicador de acciones sensibles.
- Contraste alto y soporte de escalado de texto y desplazamiento vertical.

## Pruebas

- Test unitario de `AccessSession` y limpieza del estado local.
- Tests de widgets para acceso invitado, apertura de Cuenta, cierre de sesión y
  eliminación confirmada/cancelada.
- Tests de documentos y soporte accesibles sin red.
- Test de estado de permiso mediante dependencia inyectada.
- Regresión completa de acceso, onboarding, navegación, mapa y superficies.
- Revisión visual a 430 × 932 y compilación del simulador iOS.

## Fuera de alcance y bloqueadores reales de publicación

- Autenticación real de Google y Apple.
- Creación, recuperación o cambio real de contraseña.
- Backend de cuentas y eliminación de datos del servidor.
- Revocación de tokens de proveedores.
- URL HTTPS pública de privacidad, soporte y eliminación externa.
- Datos de contacto oficiales confirmados por el titular.
- Formularios Data Safety/Privacy Nutrition Labels y metadata de tiendas.
- Revisión jurídica de privacidad, términos, retención y tratamiento de menores.

La app no debe enviarse a revisión declarando estas funciones como productivas
hasta resolver esos bloqueadores.
