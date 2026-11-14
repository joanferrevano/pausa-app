# pausa v1.0.0-beta ⏸

Primera beta pública de **pausa**: una app Android que te hace esperar unos segundos antes de abrir las apps que te roban el tiempo (TikTok, Instagram…) y te echa cuando se acaba el tiempo que tú mismo te has puesto.

> ⚠️ Es una beta. Puede tener fallos, sobre todo en algunas marcas de móvil. Si algo no va, abre un issue o déjalo en los comentarios del vídeo.

## Qué incluye
- Pantalla de espera configurable antes de abrir una app bloqueada
- Tiempo máximo por sesión: cuando se acaba, te expulsa de la app
- Bloqueo hasta medianoche tras una expulsión (con botón para saltarlo… si te atreves)

## Instalación
1. Descarga `pausa-v1.0.0-beta.apk` de aquí abajo (Assets).
2. Ábrelo en el móvil. Android te pedirá permiso para **instalar apps de origen desconocido**: acéptalo para tu navegador o gestor de archivos.
3. Si sale el aviso de **Play Protect**, pulsa *Más detalles → Instalar de todas formas*. Sale porque la app no viene de Play Store y usa el servicio de Accesibilidad.

### Android 13 o superior (importante)
Android bloquea la Accesibilidad en apps instaladas desde fuera de Play Store. Antes de activarla:
**Ajustes → Aplicaciones → pausa → ⋮ (arriba a la derecha) → Permitir ajustes restringidos**

## Permisos
Al abrir pausa te pedirá dos:
- **Acceso al uso de apps**: para saber qué app tienes abierta
- **Servicio de Accesibilidad**: para mostrar la pantalla de espera y expulsarte

pausa no envía tus datos a ningún sitio. Todo se queda en el móvil.

## Xiaomi, Samsung, Huawei…
Algunas capas cierran las apps en segundo plano y el bloqueo deja de funcionar. Tienes los pasos para cada marca en el [README](../../blob/main/README.md#3-configuración-específica-por-fabricante). En **Xiaomi/MIUI** es obligatorio activar Autostart y poner la batería en *Sin restricciones*.

## Requisitos
Android 5.0 o superior.
