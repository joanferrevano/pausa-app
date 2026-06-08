# pausa ⏸

> *Recupera tu tiempo. Recupera tu vida.*

**pausa** es una app Android de control de tiempo de pantalla que intercepta apps bloqueadas mostrando una pantalla de espera configurable antes de permitir el acceso, y expulsa al usuario cuando se agota el tiempo máximo permitido.

---

## Requisitos

- Android 5.0+ (API 21)
- Permiso de **Accesibilidad** (`AccessibilityService`)
- Permiso de **Uso de apps** (`UsageStatsManager`)
- Permiso de **Servicio en primer plano** (concedido automáticamente en instalación)

---

## Instalación y configuración inicial

### 1. Instalar la app
Instala el APK desde Android Studio o descarga la release desde GitHub.

### 2. Abrir pausa y conceder permisos
Al abrir la app por primera vez, se solicitarán dos permisos:

**Permiso de uso de apps**
- Pulsa *Conceder permiso*
- En ajustes, busca **pausa** y activa *Permitir acceso al uso*

**Permiso de accesibilidad**
- Pulsa *Activar servicio*
- En ajustes, busca **pausa** en la lista de servicios instalados
- Actívalo y confirma

### 3. Configuración específica por fabricante

#### Xiaomi / MIUI (obligatorio)
Sin estos pasos el bloqueo no funcionará con la app cerrada:

1. **Autostart** → Ajustes → Aplicaciones → pausa → Autostart → Activar
2. **Batería** → Ajustes → Aplicaciones → pausa → Ahorro de batería → Sin restricciones
3. (Opcional) Bloquear pausa en recientes para que MIUI no la mate

#### Samsung One UI
1. Ajustes → Cuidado del dispositivo → Batería → Límites de uso en segundo plano → Desactivar para pausa
2. Ajustes → Aplicaciones → pausa → Batería → Sin restricciones

#### Huawei / EMUI
1. Ajustes → Aplicaciones → pausa → Inicio → Gestión manual → Activar los tres toggles (Autoarranque, Arranque secundario, Ejecutar en segundo plano)

#### OnePlus / OxygenOS
Generalmente funciona sin configuración adicional. Si falla:
1. Ajustes → Batería → Optimización de batería → pausa → No optimizar

---

## Uso

### Crear una pausa

1. Abre pausa y ve a la pestaña **Pausas**
2. Pulsa **+ Añadir pausa**
3. Busca y selecciona la app a bloquear (ej. TikTok, Instagram)
4. Configura:
    - **Espera** — segundos de countdown antes de poder entrar (ej. 15s)
    - **Máximo** — minutos máximos de uso por sesión (ej. 5 min). Pon 0 para solo countdown sin límite de tiempo.
5. Activa el toggle y guarda

### Cómo funciona el bloqueo

Cada vez que abres una app bloqueada:

1. **Countdown** — aparece la pantalla de pausa con un contador regresivo. No puedes saltarla ni cerrarla con el botón atrás.
2. **Sesión activa** — cuando el contador llega a 0, puedes usar la app. Si configuraste un tiempo máximo, un timer empieza a correr en segundo plano.
3. **Expulsión** — cuando se agota el tiempo máximo, pausa te envía al home automáticamente. La app queda bloqueada durante 10 segundos para evitar que vuelvas inmediatamente.

### Activar / desactivar una pausa
Usa el toggle en la pantalla de Pausas. Las pausas desactivadas no bloquean la app.

---

## Arquitectura técnica

```
pausa/
├── Flutter (UI)
│   ├── Pantalla Home — estadísticas de uso
│   ├── Pantalla Pausas — gestión de bloqueos
│   ├── Pantalla Rutinas — (próximamente)
│   └── Pantalla Estadísticas — (próximamente)
│
└── Android nativo (Kotlin)
    ├── PausaAccessibilityService   — detecta cambios de app en foreground
    ├── PausaInterstitialActivity   — pantalla de countdown (no saltable)
    ├── PausaTimerService           — timer de sesión activa (foreground service)
    └── PausaKeepaliveService       — mantiene el proceso vivo en background
```

### Flujo de bloqueo

```
App bloqueada abre
        ↓
AccessibilityService detecta foreground change
        ↓
pendingIntercepts[pkg] registrado
        ↓
Poller (cada 1s) confirma app en foreground
        ↓
PausaInterstitialActivity lanzada
        ↓
Countdown completado → startSession(pkg)
        ↓
PausaTimerService arranca (si maxMinutes > 0)
        ↓
Timer agota → expelUser() → home
```

### SharedPreferences
Las pausas configuradas se guardan en `pausa_prefs` → `pausas_list` (JSON array). El `AccessibilityService` lee directamente de SharedPreferences — no depende del proceso Flutter para bloquear apps.

---

## Desarrollo

### Requisitos
- Flutter 3.x
- Android Studio Hedgehog+
- Android SDK 35
- Dispositivo físico recomendado (el emulador no soporta `UsageStatsManager` correctamente)

### Setup
```bash
git clone https://github.com/joanferrevano/pausa-app.git
cd pausa-app
flutter pub get
flutter run
```

### Ramas
```
main        ← versión estable
develop     ← integración
feature/*   ← desarrollo de features
```

### Commits
Los mensajes de commit siguen el formato:
```
tipo: descripción en español

feat:   nueva funcionalidad
fix:    corrección de bug
refactor: refactorización sin cambio de comportamiento
docs:   documentación
```

---

## Bugs conocidos / limitaciones

| Fabricante | Issue | Workaround |
|---|---|---|
| Xiaomi MIUI | El servicio puede ser matado sin Autostart | Activar Autostart + batería sin restricciones |
| Todos | Apps con pantalla de splash larga pueden tardar hasta 3s en ser interceptadas | El sistema de `pendingIntercepts` espera hasta 3s |
| Todos | El bloqueo no funciona en el launcher del sistema ni en apps del sistema | Por diseño — solo afecta apps de usuario |

---

## Licencia
Proyecto privado — Joan Ferrer © 2025