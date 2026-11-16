# pausa ⏸

> *Recupera tu tiempo. Recupera tu vida.*

**pausa** es una app Android de control de tiempo de pantalla. Intercepta las apps que elijas con una pantalla de espera configurable antes de dejarte entrar, y te expulsa cuando se agota el tiempo máximo que te has puesto para ese día.

Versión actual: **v1.0.1-beta** ([notas de la release](NOTAS_RELEASE_v1.0.1-beta.md)).

---

## Requisitos

- Android 7.0+ (API 24)
- Permiso de **Accesibilidad** (`AccessibilityService`)
- Permiso de **Acceso al uso** (`UsageStatsManager`)
- Permiso de **Notificaciones** (Android 13+), para el aviso de tiempo agotado
- Permiso de **Servicio en primer plano** (concedido automáticamente en la instalación)

La app no tiene permiso de internet: no envía datos a ningún sitio.

---

## Instalación y configuración inicial

### 1. Instalar la app
Descarga el APK de la release en GitHub, o instálalo desde Android Studio.

### 2. Abrir pausa y conceder permisos
Al terminar la introducción aparece una **pantalla de permisos** con cada paso, su estado (concedido o pendiente) y un botón que lleva al ajuste correspondiente:

- **Notificaciones** — para avisarte cuando se agota tu tiempo.
- **Acceso a uso** — para saber qué app tienes abierta.
- **Accesibilidad** — para mostrar la pausa al abrir una app.

Se puede continuar sin concederlos, pero las pausas no funcionarán sin el acceso a uso y la accesibilidad. Más tarde, los avisos del Inicio tienen un botón **Revisar permisos** que abre la misma pantalla.

**Android 13 o superior, con el APK instalado fuera de Play Store:** si al activar la accesibilidad Android dice «Ajuste restringido», ve a *Ajustes → Aplicaciones → pausa → ⋮ → Permitir ajustes restringidos* y vuelve a activarla. La opción solo aparece después de haberlo intentado una vez.

### 3. Configuración específica por fabricante

#### Xiaomi / Redmi / POCO (MIUI y HyperOS) — obligatorio
Sin estos pasos el sistema cierra pausa al limpiar las apps recientes y puede desactivar su accesibilidad. Hazlos **antes** de activar la accesibilidad:

1. **Inicio automático** → Ajustes → Aplicaciones → pausa → Inicio automático → Activar
2. **Batería** → Ajustes → Aplicaciones → pausa → Ahorro de batería → Sin restricciones
3. **Candado en recientes** → en la vista de apps recientes, mantén pulsada la tarjeta de pausa y toca el candado

La pantalla de permisos muestra este paso en estos móviles, con botones a los dos primeros ajustes.

#### Samsung One UI
1. Ajustes → Cuidado del dispositivo → Batería → Límites de uso en segundo plano → Desactivar para pausa
2. Ajustes → Aplicaciones → pausa → Batería → Sin restricciones

#### Huawei / EMUI
1. Ajustes → Aplicaciones → pausa → Inicio → Gestión manual → Activar los tres toggles (Autoarranque, Arranque secundario, Ejecutar en segundo plano)

#### OnePlus / OxygenOS
Generalmente funciona sin configuración adicional. Si falla:
1. Ajustes → Batería → Optimización de batería → pausa → No optimizar

Solo se ha probado en un Xiaomi con HyperOS 3. Los pasos de las otras marcas no están comprobados en dispositivo.

---

## Uso

### Crear una pausa

1. Abre pausa y ve a la pestaña **Pausas**
2. Pulsa **+ Añadir pausa**
3. Busca y selecciona la app (ej. TikTok, Instagram)
4. Configura:
    - **Espera** — segundos de cuenta atrás antes de poder entrar (ej. 15 s)
    - **Máximo** — minutos máximos de uso **al día** (ej. 10 min). Con *Sin límite* solo hay cuenta atrás.
5. Guarda

### Cómo funciona el bloqueo

Cada vez que abres una app con pausa:

1. **Cuenta atrás** — aparece la pantalla de espera con un contador y el tiempo que te queda hoy. No se puede saltar ni cerrar con el botón atrás.
2. **Sesión activa** — al llegar a 0 puedes usar la app. Si hay máximo, un temporizador descuenta del tiempo que te queda hoy. Salir de la app o apagar la pantalla cierra la sesión; al volver hay cuenta atrás otra vez.
3. **Expulsión** — cuando se agota el máximo del día, pausa te manda al inicio y la app queda bloqueada hasta medianoche. Al intentar abrirla vuelves al inicio directamente, sin cuenta atrás.
4. **Saltar el bloqueo** — desde la tarjeta de la pausa ("Bloqueado hoy") puedes pedir 5 minutos más, tras un diálogo disuasorio.

El contador de cada app se reinicia a medianoche. El uso con *Sin límite* no se cuenta.

### Activar / desactivar una pausa
Usa el interruptor en la pantalla de Pausas. Las pausas desactivadas no bloquean la app.

### Rutinas y Bloqueos
Las pestañas **Rutinas** (bloquear apps por horario) y **Bloqueos** (bloquear apps durante un tiempo) se muestran como **Próximamente**: todavía no están implementadas.

---

## Arquitectura técnica

```
pausa/
├── Flutter (UI)
│   ├── Inicio — estadísticas de uso y avisos de permisos
│   ├── Pausas — gestión de pausas
│   ├── Rutinas — (próximamente)
│   ├── Bloqueos — (próximamente)
│   └── Onboarding — introducción y pantalla de permisos
│
└── Android nativo (Kotlin)
    ├── PausaAccessibilityService   — detecta la app en primer plano y lanza la espera
    ├── PausaInterstitialActivity   — pantalla de cuenta atrás (no saltable)
    ├── PausaTimerService           — temporizador de la sesión (foreground service)
    ├── SessionStore                — sesión en curso y uso acumulado por app y día
    ├── ForegroundHelper            — qué app está delante (ventana larga)
    ├── PausaKeepaliveService       — mantiene el proceso vivo en segundo plano
    └── BootReceiver                — relanza el keepalive al encender el móvil
```

### Flujo de bloqueo

```
Se abre una app con pausa
        ↓
El poller (cada 1 s, con UsageStats) la detecta en primer plano
        ↓
¿Tiempo de hoy agotado? → al inicio, sin cuenta atrás
        ↓ no
pendingIntercepts[pkg] registrado → PausaInterstitialActivity lanzada
        ↓ (si el sistema no la trae al frente, se reintenta; a los 10 s, al inicio)
Cuenta atrás completada → startSession(pkg)
        ↓
PausaTimerService arranca con lo que queda de hoy (si maxMinutes > 0)
        ↓
Tiempo agotado con la app delante → expelUser() → inicio
```

### Persistencia
- Las pausas viven en Hive (Flutter) y se sincronizan a `pausa_prefs` → `pausas_list` (JSON). El servicio nativo lee de ahí: no depende de que Flutter esté abierto.
- La sesión en curso y los segundos usados hoy por app también están en `pausa_prefs` (`SessionStore`), para sobrevivir a que el sistema mate el proceso.

---

## Desarrollo

### Requisitos
- Flutter 3.x
- Android Studio
- Dispositivo físico recomendado (el emulador no soporta `UsageStatsManager` correctamente)

### Setup
```bash
git clone https://github.com/joanferrevano/pausa-app.git
cd pausa-app
flutter pub get
flutter run
```

### Comprobaciones
```bash
flutter analyze
flutter test
flutter build apk --release
```

La firma de release necesita `android/key.properties` y el keystore (no están en el repositorio). Sin ellos el build firma con claves de debug y no se puede instalar sobre una release publicada.

### Ramas
Se trabaja directamente en `main`.

### Commits
Los mensajes de commit siguen el formato:
```
tipo: descripción en español

feat:   nueva funcionalidad
fix:    corrección de bug
refactor: refactorización sin cambio de comportamiento
docs:   documentación
```

El plan de trabajo y el estado de cada tarea están en `AUDITORIA.md`.

---

## Bugs conocidos / limitaciones

| Dónde | Problema | Solución o estado |
|---|---|---|
| Xiaomi / Redmi / POCO | El sistema cierra pausa y puede apagar la accesibilidad sin inicio automático | Activar inicio automático, batería sin restricciones y candado en recientes |
| Todos | La app con pausa puede verse 1–2 s antes de que aparezca la espera | El poller confirma la app delante antes de interceptar |
| Todos | No se aplica al lanzador ni a apps del sistema (`com.android.*`, salvo Chrome) | Por diseño |
| Todos | El uso con máximo *Sin límite* no cuenta para el total del día | Pendiente |
| Todos | Subir el máximo de una pausa bloqueada la desbloquea sin diálogo | Pendiente (futuro "Modo extremo") |
| Todos | Depende de la hora del sistema: cambiarla altera el límite diario | Pendiente |

---

## Licencia
Proyecto privado — Joan Ferrer © 2025
