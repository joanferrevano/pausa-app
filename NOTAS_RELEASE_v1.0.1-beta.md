# pausa v1.0.1-beta ⏸

Segunda beta de **pausa**: la app Android que te hace esperar unos segundos antes de abrir las apps que te roban el tiempo y te echa cuando se acaba el tiempo que tú mismo te has puesto.

Esta versión arregla los fallos más serios de la primera beta y cambia cómo cuenta el tiempo.

> ⚠️ Sigue siendo una beta. Puede tener fallos, sobre todo en algunas marcas de móvil. Si algo no va, abre un issue o déjalo en los comentarios del vídeo.

## Qué cambia

### El límite ahora es por día
- **Antes** el máximo era por sesión: salías, volvías a entrar y tenías otra vez el tiempo entero.
- **Ahora** el máximo es el total del día para esa app. Si tienes 10 minutos y usas 4, al volver te quedan 6. A medianoche se reinicia.
- La pantalla de espera y la notificación te dicen cuánto te queda hoy.
- Cuando se te acaba el tiempo, la app queda bloqueada hasta el día siguiente: al abrirla vuelves al inicio directamente, sin cuenta atrás.
- **Saltar el bloqueo** (desde la tarjeta de la pausa) ahora te da 5 minutos más, no el día entero otra vez.

### Fallos arreglados
- **Apagar la pantalla ya no te castiga.** Antes, si bloqueabas el móvil con la app abierta, el tiempo seguía corriendo y podías acabar con la app bloqueada todo el día. Ahora apagar la pantalla cuenta como salir.
- **La pausa sigue funcionando después de cerrar todas las apps o reiniciar el móvil.** Antes podías entrar sin espera hasta que abrías pausa otra vez.
- **La pantalla de espera sale siempre.** En algunos móviles a veces no aparecía al abrir la app desde el inicio.
- **Editar o borrar una pausa se aplica al momento.** Antes los cambios no llegaban al bloqueo hasta reabrir pausa.
- Ya no se puede añadir la misma app dos veces, y editar una pausa desactivada no la vuelve a activar.
- La app instalada se llama **Pausa** (antes aparecía como `pausa_app`) y ya no muestra una pantalla en negro al abrirse.

### Permisos más claros
- Al terminar la introducción hay una **pantalla de permisos** con cada paso, su estado y un botón que te lleva al ajuste. Sustituye a la pantalla de "crear cuenta", que no creaba nada.
- pausa pide ahora el permiso de **notificaciones**, para avisarte cuando se agota el tiempo.
- Si la accesibilidad se desactiva o deja de funcionar, el Inicio te avisa y te dice cómo arreglarlo. Desde ese aviso puedes abrir la pantalla de permisos con **Revisar permisos**.

### Rutinas y Bloqueos: próximamente
Las pestañas **Rutinas** (bloquear apps por horario) y **Bloqueos** (bloquear apps durante un tiempo sin poder entrar) se veían en la primera beta, pero no bloqueaban nada. Ahora aparecen como **Próximamente**. Llegarán en una versión futura.

## Instalación
1. Descarga `pausa-v1.0.1-beta.apk` de aquí abajo (Assets).
2. Ábrelo en el móvil. Android te pedirá permiso para **instalar apps de origen desconocido**: acéptalo para tu navegador o gestor de archivos.
3. Si sale el aviso de **Play Protect**, pulsa *Más detalles → Instalar de todas formas*. Sale porque la app no viene de Play Store y usa el servicio de Accesibilidad.

**Si ya tienes la v1.0.0-beta**, instala esta encima: no hace falta desinstalar y conservas tus pausas. Después abre pausa y comprueba en el Inicio que no hay avisos de permisos.

## Permisos
La pantalla de permisos te guía por estos pasos:
- **Notificaciones**: para avisarte cuando se agota tu tiempo.
- **Acceso al uso de apps**: para saber qué app tienes abierta.
- **Accesibilidad**: para mostrar la pantalla de espera y mandarte al inicio. pausa no lee lo que hay en tu pantalla.

pausa no envía tus datos a ningún sitio. No tiene permiso de internet: todo se queda en el móvil.

### Android 13 o superior (importante)
Android bloquea la Accesibilidad en apps instaladas desde fuera de Play Store. Si al activarla te dice **«Ajuste restringido»**:

1. Ve a **Ajustes → Aplicaciones → pausa**.
2. Toca **⋮** (arriba a la derecha) → **Permitir ajustes restringidos**.
3. Vuelve a Accesibilidad y actívala.

La opción solo aparece después de haber intentado activar la accesibilidad una vez.

## Xiaomi, Redmi y POCO (MIUI / HyperOS)
En estos móviles el sistema cierra pausa y puede apagar su accesibilidad si no haces esto. Hazlo **antes** de activar la accesibilidad:

1. **Inicio automático**: Ajustes → Aplicaciones → pausa → *Inicio automático* → activar.
2. **Batería sin restricciones**: Ajustes → Aplicaciones → pausa → *Ahorro de batería* → *Sin restricciones*.
3. **Candado en recientes**: abre la vista de apps recientes, mantén pulsada la tarjeta de pausa y toca el candado. Así no se cierra al pulsar "cerrar todo".

La pantalla de permisos tiene botones que te llevan a los dos primeros ajustes.

## Samsung, Huawei y otras marcas
Algunas capas también cierran las apps en segundo plano. Tienes los pasos para cada marca en el [README](../../blob/main/README.md#3-configuración-específica-por-fabricante).

## Limitaciones conocidas
- Con el máximo en **Sin límite**, ese uso no se cuenta para el total del día.
- Rutinas y Bloqueos todavía no están disponibles.
- Es una app de autocontrol, no de control parental: se puede desactivar desde los ajustes del móvil.

## Requisitos
Android 7.0 o superior.
