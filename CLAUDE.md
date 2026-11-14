# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Qué es

**pausa**: app Android (Flutter + Kotlin nativo) de control de tiempo de pantalla. Intercepta apps bloqueadas con una pantalla de espera (countdown), limita la sesión y expulsa al usuario al home. UI y textos en español. Solo Android; no hay iOS.

## Comandos

```
flutter pub get
flutter run                      # dispositivo/emulador Android
flutter analyze
flutter test                     # único test actual: placeholder en test/widget_test.dart
flutter test test/widget_test.dart --plain-name "<nombre>"   # un test concreto
dart run build_runner build --delete-conflicting-outputs     # regenerar *.g.dart de Hive tras tocar modelos
flutter build apk --release
```

- La firma de release lee `android/key.properties` (+ `upload-keystore.jks` en `android/app/`), ambos gitignored. **Si falta `key.properties`, el build release firma silenciosamente con claves de debug** (`android/app/build.gradle.kts`). Sin el keystore original, las actualizaciones no se instalan sobre la beta.
- No commitear APKs (`*.apk` está excluido; hubo uno en el historial).
- `AUDITORIA.md` contiene una auditoría de solo lectura con tareas priorizadas (críticas/importantes/mejoras); consúltala antes de arreglar bugs conocidos. Lo marcado "(sin probar en dispositivo)" viene solo de leer código.

## Arquitectura

Dos mitades que se comunican por `MethodChannel`:

**Dart (`lib/`)**: Riverpod (`lib/shared/providers`), go_router (`lib/app/router.dart`), Hive para persistencia. Estructura por feature en `lib/features/{splash,onboarding,auth,home,pausas,rutinas,bloqueos}`; `lib/core` tiene servicios, modelos y widgets compartidos.
- `main.dart` inicializa Hive (`HiveService`) antes de `runApp`. El gate de onboarding vive en `SplashScreen`, no en el router.
- Hive: cuatro boxes (`HiveConstants`), adapters con typeId fijos 0/1/2 (`PausaConfig`, `Rutina`, `Bloqueo`). No cambiar typeIds ni reutilizarlos; regenerar `.g.dart` con build_runner.
- Canales: `com.pausa.pausa_app/usage_stats` y `com.pausa.pausa_app/accessibility`, implementados en `MainActivity.kt`; wrappers Dart en `lib/core/services/`.

**Kotlin (`android/app/src/main/kotlin/com/pausa/pausa_app/`)** — el bloqueo real ocurre aquí, no en Dart:
- `PausaAccessibilityService`: detecta la app en primer plano (con un poller de 1 s), tiene la lista de apps bloqueadas, lanza la interstitial y gestiona expulsión, lockout post-expulsión y cooldown diario. Estado en memoria + `SharedPreferences("pausa_prefs")` (cooldown/expulsión por día natural).
- `PausaInterstitialActivity`: countdown iniciado por el usuario; al terminar entrega la sesión a `PausaTimerService`.
- `PausaTimerService`: aplica el tiempo máximo de sesión y expulsa si la app sigue en primer plano. El estado es solo en memoria (se pierde si matan el proceso).
- `PausaKeepaliveService`: servicio foreground sticky que se reprograma al quitar la tarea (necesario en MIUI/Samsung/etc.).
- `UsageStatsHelper`: agregación de uso (emparejado foreground, pantalla apagada, mínimo 60 s, top 10).

**Sincronización Dart→nativo**: la lista de apps bloqueadas vive en Hive pero el servicio nativo mantiene su propia copia. Hay que re-sincronizarla al cambiar pausas; hoy editar/borrar por swipe no lo hace (solo el botón de papelera), ver AUDITORIA.md.

## Estado conocido / gotchas

- Rutinas y Bloqueos son solo UI: no imponen bloqueo real. La pestaña "Bloqueos" placeholder y el icono de ajustes del dashboard están sin implementar.
- `register_screen` es una maqueta (sin autenticación real).
- minSdk real es Android 7.0 (el README dice 5.0, desactualizado).
- Hay listas de paquetes hardcodeadas (launchers/allowlist en Kotlin; subcadenas de paquetes "improductivos" en Dart) que definen qué se ignora o clasifica.
- Permisos requeridos en runtime: Accesibilidad y Acceso al uso. La app no tiene permiso de internet (Google Fonts no cargará en release).

## Reglas de trabajo
- La hoja de ruta está en AUDITORIA.md. Al terminar una tarea, márcala con [x] y añade una línea con lo que se hizo.
- Una tarea (o un grupo pequeño de tareas relacionadas) cada vez.
- Antes de dar algo por terminado: `flutter analyze` sin errores y `flutter test` en verde. Si tocas Kotlin, `flutter build apk --debug` tiene que compilar.
- Si un cambio afecta al comportamiento en el móvil (bloqueo, temporizador, servicios), dime al final exactamente qué tengo que probar en el dispositivo.
- No cambies la arquitectura, no actualices dependencias y no añadas paquetes sin preguntarme.
- No hagas push. Commits sí, uno por tarea, con mensajes en español.
- Estoy en Windows con PowerShell 5.1: no uses `&&` en los comandos.
- Responde en español.

## Decisiones de producto
- Límite de uso: acumulado DIARIO por app (no por sesión).
- Rutinas y Bloqueos: se muestran como "Próximamente" hasta implementarlos de verdad.
- Registro: se sustituye por una pantalla de permisos al final del onboarding.
