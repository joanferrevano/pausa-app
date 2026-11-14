# Auditoría de pausa — 14-11-2026

Auditoría de solo lectura. No se ha modificado ningún archivo de código; solo se ha creado este informe.

**Qué se ha comprobado de verdad (ejecutado en esta máquina, Flutter 3.41.1 / Dart 3.11.0):**

| Comprobación | Resultado |
|---|---|
| `flutter analyze` | ✅ 0 problemas |
| `flutter test` | ✅ pasa, pero solo hay 1 test y es un placeholder (`expect(true, isTrue)`) |
| `flutter build apk --release` | ✅ compila (50,9 MB, firmado con el keystore propio) |
| Inspección del APK generado (`aapt2`) | minSdk 24, targetSdk 36, etiqueta `pausa_app`, sin permiso INTERNET, 3 arquitecturas |
| `flutter pub outdated` | 62 paquetes con versión más nueva; 4 dependencias directas con salto de versión mayor |

**Qué NO se ha podido comprobar:** nada se ha probado en un móvil o emulador. Todo lo que aparece abajo sobre el comportamiento del bloqueo (servicio de accesibilidad, temporizador, expulsión) sale de leer el código. Donde el fallo depende de cómo se comporte Android en un dispositivo real, lo indico con **(sin probar en dispositivo)**. Tampoco he comprobado si el repositorio de GitHub es público o privado.

---

## Qué es y qué hace

**pausa** es una app Android de autocontrol del tiempo de pantalla. Para cada app que el usuario elige (TikTok, Instagram…) hace tres cosas:

1. Al abrirla, muestra una pantalla de espera con cuenta atrás que no se puede saltar.
2. Al terminar la espera, deja entrar y arranca un temporizador de sesión (5–30 min, o sin límite).
3. Si el temporizador se agota con la app delante, manda al usuario al inicio y **bloquea esa app hasta medianoche** (se puede levantar desde pausa con un diálogo disuasorio).

Además tiene un panel con el tiempo de pantalla del día, un onboarding y dos pestañas más (Rutinas y Bloqueos) que hoy son solo interfaz.

**Stack**

- Flutter (Dart) para toda la interfaz: `flutter_riverpod` 2 (estado), `go_router` 14 (navegación), `hive_flutter` (datos locales), `shared_preferences`, `google_fonts`.
- Kotlin nativo para el bloqueo: 6 archivos, ~1.640 líneas. Sin plugins de terceros en la parte nativa.
- Solo Android. Sin backend, sin red: el APK de release no declara el permiso INTERNET.
- ~9.900 líneas en total (≈8.300 Dart, ≈1.640 Kotlin).

**Arquitectura (cómo se conectan las piezas)**

```
Flutter UI ──(Riverpod)── PausasNotifier ── Hive (pausas_box)        ← fuente de verdad de la configuración
                               │
                               └─ MethodChannel "…/accessibility" · syncPausas
                                        │
                                        ▼
                         SharedPreferences nativas "pausa_prefs" → pausas_list (JSON)
                                        │  (se lee en cada consulta)
                                        ▼
PausaAccessibilityService ── sondea UsageStats cada 1 s para saber qué app está delante
        │  app con pausa detectada → pendingIntercepts → al confirmarse en primer plano:
        ▼
PausaInterstitialActivity (cuenta atrás) ── al acabar: startSession() + arranca
        ▼
PausaTimerService (servicio en primer plano) ── al agotarse: markExpelled() + ir al inicio
        │                                         └─ guarda expelled_day_<paquete> = hoy  → bloqueo diario
PausaKeepaliveService ── notificación permanente para que el sistema no mate el proceso

Flutter UI ──MethodChannel "…/usage_stats"── UsageStatsHelper (tiempo de uso, apps instaladas, iconos)
```

Puntos clave del diseño:

- El bloqueo no depende de que Flutter esté abierto: el servicio de accesibilidad lee la configuración de `pausa_prefs`. Por eso **cualquier cambio en Flutter que no llame a `syncPausas` no llega al bloqueo** (ver bugs 1 y 2).
- Aunque es un servicio de accesibilidad, no usa los eventos de accesibilidad para detectar la app: solo los usa para "despertar" el sondeo de UsageStats (`PausaAccessibilityService.kt:409-418`).
- El estado de sesión/expulsión vive en variables estáticas (`companion object`) compartidas entre el servicio de accesibilidad, la pantalla de espera y el temporizador. Solo la expulsión y el bloqueo diario se guardan en disco.

---

## Estado actual

| Funcionalidad | Estado | % aprox. | Comentario |
|---|---|---|---|
| Pantalla de espera (cuenta atrás) | Completa | 90 % | Funciona el flujo principal; quedan casos límite |
| Temporizador de sesión + expulsión | Funcional con fallos | 75 % | Bugs 3, 4 y 5 |
| Bloqueo hasta medianoche + botón para saltarlo | Completa | 85 % | El chip "Bloqueado hoy" no se refresca solo |
| Gestión de pausas (crear / editar / activar / borrar) | Funcional con fallos | 75 % | Editar y deslizar-para-borrar no sincronizan con el nativo; se pueden duplicar apps |
| Panel de inicio (tiempo de pantalla, top apps, racha) | Funcional con fallos | 70 % | Racha y "tiempo recuperado" mal calculados; reparto productivo/improductivo aproximado |
| Onboarding (gancho, dopamina, formulario, cálculo, resultado, upsell) | Completo | 90 % | No pide ningún permiso; las cifras son una estimación fija |
| Registro / cuentas | Maqueta | 10 % | Los tres botones (Google, Apple, email) solo marcan el onboarding como hecho |
| Rutinas (bloqueo por horario) | Solo interfaz | 35 % | Se guardan en Hive y nada más: no bloquean nada |
| Bloqueos ("jaulas") | Solo interfaz | 35 % | Igual: se "activan" con cuenta atrás visual, pero no bloquean nada |
| Ajustes | No existe | 0 % | El icono del engranaje no hace nada (`dashboard_tab.dart:153`) |
| Pantalla de estadísticas (la que anuncia el README) | No existe | 0 % | |
| Petición del permiso de notificaciones | No existe | 0 % | Declarado en el manifiesto, nunca se pide |
| Arranque tras reiniciar el móvil | No existe | 0 % | No hay receptor de `BOOT_COMPLETED` |
| Tests | No existen | ~0 % | 1 test placeholder |
| Términos de uso / política de privacidad | No existen | 0 % | La pantalla de registro dice que se aceptan |

**TODO / FIXME / código a medias encontrado**

- `android/app/build.gradle.kts:34` — `TODO: Specify your own unique Application ID` (resto de la plantilla).
- `lib/features/home/widgets/dashboard_tab.dart:153` — botón de ajustes con `onTap: () {}`.
- `lib/features/home/screens/home_screen.dart:20,32-41` — `_placeholderTabs` y rama `default` que ya no se usan.
- `test/widget_test.dart:4` — "Placeholder — add integration tests as features stabilize."
- Código muerto: ver sección de calidad.
- No hay `FIXME` ni bloques de código comentado relevantes.

---

## Errores y bugs

No hay errores de build, de linter ni de tests. Todo lo siguiente son bugs lógicos encontrados leyendo el código.

### 🔴 Graves (afectan a lo que la app promete)

**1. Borrar una pausa deslizando no la desactiva.**
`lib/shared/providers/pausas_provider.dart:39-44` — `deletePausa` borra de Hive pero no llama a `_syncToNative()`. El deslizado usa ese método (`pausas_screen.dart:128-129`, `pausa_app_card.dart:149`). La app sigue bloqueada hasta que se reabra pausa, se tire para refrescar o se cambie otra pausa. El icono de papelera sí funciona bien (usa `deletePausaByPackage`, que sí sincroniza).

**2. Editar una pausa no se aplica.**
`pausas_provider.dart:32-37` — `updatePausa` tampoco sincroniza. Cambiar la espera o el máximo no tiene efecto hasta la siguiente sincronización. Además `add_pausa_sheet.dart:99-104` construye la pausa editada sin pasar `isActive`, así que **editar una pausa desactivada la vuelve a activar**.

**3. Bloquear el móvil con la app delante acaba en bloqueo de todo el día.** (sin probar en dispositivo)
El temporizador cuenta tiempo de reloj desde que empezó (`PausaTimerService.kt:156-160`) y nada termina la sesión al apagar la pantalla. Si abres TikTok con máximo 5 min, lo usas 1 min y bloqueas el móvil, al pasar los 5 min `isBlockedAppInForeground()` no encuentra eventos en los últimos 5 s y devuelve `true` por defecto (`PausaTimerService.kt:249-270`, líneas 266 y 268) → `expelUser()` → `markExpelled()` → bloqueo hasta medianoche por 1 minuto de uso.

**4. Si Android mata el proceso, la sesión en curso se queda sin límite.** (sin probar en dispositivo)
`PausaTimerService.kt:54-58` dice que los campos estáticos "sobreviven a un kill del proceso". No es así: al morir el proceso se pierden. Al reiniciarse el servicio con intent nulo, `savedPackageName` está vacío y el servicio se para (`:123-131`). El servicio de accesibilidad hace `clearAll()` al reconectar, pero solo vuelve a interceptar cuando hay un evento nuevo de "app al frente" en los últimos 2 s (`PausaAccessibilityService.kt:558-573`), así que quien ya estaba dentro puede seguir sin temporizador. En MIUI, que mata procesos a menudo, es justo el caso más probable.

**5. El límite es por sesión y se reinicia al salir y volver.**
Cada vez que se completa la cuenta atrás empieza un temporizador nuevo con el máximo entero (`PausaTimerService.kt:113-121`); no hay acumulado diario. Salir al inicio a los 4:59 y volver a entrar da otros 5 min, y evita el bloqueo diario. Abrir pausa también cancela el temporizador en curso (`MainActivity.kt:30-38`). Puede ser una decisión de diseño, pero choca con el mensaje "Has usado X por hoy" (`PausaTimerService.kt:185`).

**6. Las notificaciones probablemente no se ven en Android 13+.** (sin probar en dispositivo)
`POST_NOTIFICATIONS` está en el manifiesto (`AndroidManifest.xml:10`) pero no se pide en ningún sitio, y el APK apunta a SDK 36. En Android 13+ las notificaciones vienen desactivadas hasta que el usuario las acepta, así que el aviso "Tiempo agotado" (`PausaTimerService.kt:182-188`) no llega a mostrarse.

**7. Rutinas y Bloqueos no bloquean nada.**
Ningún archivo de `rutinas/` o `bloqueos/` llama al canal nativo, y el servicio nativo solo lee `pausas_list`. El usuario puede crear una "jaula", activarla y ver la cuenta atrás (`active_bloqueo_banner.dart:43-53`) creyendo que está protegido. Es el fallo más serio de cara al usuario porque la interfaz no avisa de que no funciona.

### 🟠 Importantes

**8. El nombre de la app instalada es `pausa_app`.** `AndroidManifest.xml:12` usa `android:label="pausa_app"`; `strings.xml:3` define `app_name = "Pausa"` pero nadie lo usa. Confirmado en el APK (`application-label:'pausa_app'`).

**9. Las fuentes de Google no pueden cargarse en release.** (deducido del APK; sin probar en dispositivo)
`google_fonts` descarga las fuentes por internet en tiempo de ejecución. El APK de release no tiene permiso INTERNET (solo lo tiene el manifiesto de debug) y `pubspec.yaml:28-29` no incluye ninguna fuente como asset. En debug se ven DM Sans / DM Serif Display; en release debería verse la fuente por defecto.

**10. La versión mínima real es Android 7.0, no 5.0.** El APK tiene `minSdkVersion 24` (`build.gradle.kts:38` usa `flutter.minSdkVersion`). El README (`README.md:11`), las notas de la release (`NOTAS_RELEASE_v1.0.0-beta.md:32`) y `pubspec.yaml:37` dicen Android 5.0 / API 21.

**11. Se puede añadir la misma app dos veces.** `add_pausa_sheet.dart:92-106` y `pausas_provider.dart:26-30` no comprueban duplicados. El nativo usa la primera coincidencia (`PausaAccessibilityService.kt:584-594`); la papelera borra las dos.

**12. Racha y "tiempo recuperado" dan cifras engañosas.** `lib/core/utils/streak_calculator.dart`:
- La meta está fija en 360 min (6 h) al día (`:7`); no usa las horas que el usuario indicó en el onboarding (`user_provider.dart` guarda `dailyHours` y nadie lo lee).
- El día de hoy cuenta siempre aunque no haya terminado (`:27-35`): al abrir la app por la mañana la racha ya suma 1.
- "Recuperado esta semana" suma `meta − minutos` también para el día en curso (`:48-55`): a las 8:00 con 10 min de uso muestra casi 6 h "recuperadas".
- Solo hay dato de los días en que se abrió pausa (`usage_stats_provider.dart:103-104`); un día sin abrirla rompe la racha.

**13. Reparto productivo / improductivo aproximado.** `usage_stats_provider.dart:98-101` calcula lo improductivo solo con las 10 apps más usadas y de más de 1 min (`UsageStatsHelper.kt:118-121`); todo lo demás, incluido el lanzador y la propia pausa, cuenta como "productivo". La clasificación depende de la categoría que declare cada app (`UsageStatsHelper.kt:17-40`); las que no declaran categoría salen como productivas.

**14. El selector ofrece apps que el servicio ignora siempre.** `PausaAccessibilityService.kt:508-512` descarta todo paquete `com.android.*` salvo Chrome, y `:449-452` todo paquete que contenga "pausa". Se puede crear una pausa para, por ejemplo, el navegador de serie de un fabricante y nunca se aplicará, sin aviso.

**15. La lista de "cambiador de tareas" es código muerto y contradice su comentario.** Todos los paquetes de `taskSwitcherPackages` (`:348-364`) están también en `homeAndLauncherPackages` (`:305-346`), y la comprobación de inicio va antes (`:472-493`), así que la rama `:498-502` ("no terminar la sesión") nunca se ejecuta. En MIUI, Samsung, Huawei, OnePlus, Oppo y Realme, abrir recientes termina la sesión.

**16. Comprobación de permiso de uso poco fiable.** `UsageStatsHelper.kt:144-155` da el permiso por concedido si `queryUsageStats` devuelve datos. En un móvil recién encendido o sin uso reciente puede devolver vacío con el permiso concedido. Lo correcto es consultar `AppOpsManager`. Además `usage_stats_provider.dart:66,83` nunca vuelve a `false` si el permiso se revoca con la app abierta.

**17. El servicio keepalive no arranca tras reiniciar el móvil.** Solo se lanza desde `MainActivity.kt:22-27`. Android relanza el servicio de accesibilidad tras un reinicio, pero la notificación que protege el proceso no vuelve hasta abrir pausa.

**18. Tipo de servicio en primer plano incorrecto.** `AndroidManifest.xml:72` y `PausaTimerService.kt:143` declaran el temporizador como `mediaPlayback` sin reproducir nada. Funciona hoy, pero es un uso indebido del tipo (motivo de rechazo en Play Store). Debería ser `specialUse`, como el keepalive.

### 🟢 Menores

- **Editar un bloqueo activo lo desactiva**: `add_bloqueo_sheet.dart:80-87` crea el objeto sin `isActive` ni `activatedAtMs`.
- **Un bloqueo con duración nunca se desactiva al llegar a cero**: `active_bloqueo_banner.dart:43-53` solo deja el contador en 0.
- **Rutinas sin validar** que la hora de fin sea distinta de la de inicio (`add_rutina_sheet.dart:62-86`).
- **Chip "Bloqueado hoy" desactualizado**: `pausa_app_card.dart:42-52` solo consulta al crear la tarjeta.
- **`router.dart:14`**: el parámetro `onboardingDone` no se usa; `main.dart:15-16` lo lee para nada (el splash lo vuelve a leer en `splash_screen.dart:138-143`).
- **`main.dart:43-47`**: registra un `addPostFrameCallback` dentro de `build` y crea el `GoRouter` en cada reconstrucción (`:53`).
- **`PausaKeepaliveService.kt:36-49`**: el reinicio por alarma usa `PendingIntent.getService`, que en Android 8+ no puede arrancar un servicio en primer plano desde segundo plano. Es redundante con `stopWithTask="false"`. (sin probar)
- **`pausas_provider.dart:46-56`**: `deletePausaByPackage` vacía la caja y la reescribe; si la app muere a mitad se pierden pausas.
- **`UsageStatsHelper.kt:51-111`**: el uso de una app abierta desde antes de medianoche no cuenta el tramo de hoy hasta que cambia de pantalla.
- **Manipulable con el reloj**: el temporizador y el bloqueo diario usan la hora del sistema (`PausaTimerService.kt:119`, `PausaAccessibilityService.kt:251-261`).
- **Errores silenciados**: `accessibility_service.dart` y `usage_stats_service.dart` capturan todo y devuelven valores por defecto; si falla `syncPausas` el usuario no se entera (`accessibility_service.dart:47-49`).
- **`README.md:75`** dice que tras la expulsión la app queda bloqueada 10 segundos; el código la bloquea hasta medianoche. **`README.md:89`** marca Rutinas como "próximamente" cuando ya hay pantalla.

---

## Seguridad

**Bien**

- **No hay claves en el código ni en el historial de git.** `android/key.properties` y `android/app/upload-keystore.jks` existen en disco, están en `android/.gitignore:12-14` y he comprobado que nunca se han subido a ningún commit (búsqueda por nombre en los 51 commits).
- **La app no tiene acceso a red en release** (sin permiso INTERNET), lo que respalda la frase "pausa no envía tus datos a ningún sitio" de las notas de la release.
- **Componentes expuestos**: solo `MainActivity` y el servicio de accesibilidad (protegido con `BIND_ACCESSIBILITY_SERVICE`). La pantalla de espera y los otros dos servicios tienen `exported="false"`.
- El servicio de accesibilidad pide `canRetrieveWindowContent="false"` (`accessibility_service_config.xml:6`): no lee el contenido de la pantalla.

**A corregir o tener en cuenta**

- **El keystore solo está dentro de la carpeta del proyecto.** Si se pierde, no se podrá publicar ninguna actualización que instale encima de la v1.0.0-beta. Conviene una copia fuera del proyecto (no he comprobado si ya existe).
- **APK de 53 MB en el historial de git.** Se añadió en el commit `3f7c2e4` y se quitó en `13a9239`. Los dos commits están sin subir (`main` va 2 por delante de `origin/main`): si se unen antes de hacer push, el APK no llega a GitHub.
- **Registro falso.** `register_screen.dart:9-13,85,111,141`: "Continuar con Google / Apple / email" no autentican nada. El texto promete "Crea tu cuenta para guardar tu progreso" (`:69`) y dice "Al continuar aceptas nuestros Términos de uso y Política de privacidad" (`:174`), documentos que no existen. Para una app que se reparte en público y usa accesibilidad y datos de uso, hace falta al menos una política de privacidad real, o quitar el texto.
- **Logs en release.** 48 llamadas a `Log.d/Log.e` en Kotlin; el sondeo escribe el paquete en primer plano cada segundo (`PausaAccessibilityService.kt:44`) y el temporizador cada tic (`PausaTimerService.kt:25`). Solo se leen por ADB, pero es historial de uso en claro y coste inútil.
- **Permisos sensibles para Play Store.** `QUERY_ALL_PACKAGES` (`AndroidManifest.xml:5`) y el uso de accesibilidad para algo que no es accesibilidad necesitan declaración y justificación ante Google. Solo importa si se quiere publicar en la tienda. `FOREGROUND_SERVICE_MEDIA_PLAYBACK` (`:8`) no está justificado (bug 18).
- **Validación de entradas.** `MainActivity.kt:139-145` guarda lo que llegue por `syncPausas` sin validar. Riesgo bajo: el canal solo lo usa la propia app y la interfaz solo ofrece valores fijos.
- **Formas de saltarse el bloqueo** (es una app de autocontrol, no de control parental, pero conviene saberlo): desactivar el servicio de accesibilidad, forzar detención, desinstalar, cambiar la fecha del sistema, el botón de saltar el bloqueo diario, salir y volver a entrar (bug 5). No he podido comprobar pantalla dividida, ventanas flotantes ni imagen-en-imagen.

---

## Calidad de código y deuda técnica

**Tests**

- Cobertura real: 0 %. Un único test placeholder. No hay CI.
- La lógica más delicada (máquina de estados de sesión / expulsión) está en Kotlin, repartida en variables estáticas mutables entre tres clases (`PausaAccessibilityService.kt:131-284`, `PausaTimerService.kt:50-89`). Así es difícil de probar y de razonar; los commits recientes (`fix: cooldown bloqueo persistente sin bucle`…) y la cantidad de guardas y comentarios defensivos indican que ya ha dado guerra.
- Lo más fácil de testear hoy sin tocar arquitectura: `StreakCalculator`, los notifiers de Riverpod y los modelos.

**Duplicación**

- `_FadeSlide` está definido cuatro veces (`pausas_screen.dart`, `dashboard_tab.dart`, `bloqueos_screen.dart`, `rutinas_screen.dart`) y además existe `app/widgets/fade_slide_in.dart`, que hace lo mismo.
- El patrón de "encoger al pulsar" (`_down/_up/_cancel` + `AnimatedScale`) está copiado en 14 archivos, existiendo ya `app/widgets/pressable_feedback.dart`.
- Formateo de duración duplicado: `app_usage_info.dart:16-23` y `usage_stats_service.dart:119-126`; etiquetas de espera/máximo duplicadas entre `add_pausa_sheet.dart:24-32` y `pausa_app_card.dart:15-16`.
- "Enviar al inicio" repetido 5 veces en Kotlin (`PausaAccessibilityService.kt:75-78,99-102`, `PausaInterstitialActivity.kt:52-55,64-67`, `PausaTimerService.kt:192-208`).
- La fecha `yyyyMMdd` se formatea en tres sitios (`PausaAccessibilityService.kt:183,256,378`).

**Código muerto**

- `lib/features/rutinas/widgets/rutina_app_selector.dart` y `lib/features/bloqueos/widgets/bloqueo_app_selector.dart`: no los importa nadie.
- `getProductiveTimeMs` / `getUnproductiveTimeMs`: definidos en Dart (`usage_stats_service.dart:51-69`), en el canal (`MainActivity.kt:81-97`) y en Kotlin (`UsageStatsHelper.kt:138-142`), sin ningún uso.
- `StreakCalculator.hasAnyData` (`:15-18`), `UserState.dailyHours`, los `fromMap` de los tres modelos, `toMap` de `Bloqueo` y `Rutina`.
- `android/app/src/main/res/drawable/pausa_logo.xml` no se referencia.
- Rama de `taskSwitcherPackages` (bug 15) y `_placeholderTabs` en `home_screen.dart`.
- El extra `userInitiated` (`PausaInterstitialActivity.kt:32,43-46`) es redundante: la actividad no está exportada.

**Malas prácticas y nombres**

- `Bloqueo.appNames` y `Rutina.appNames` guardan nombres de paquete, no nombres de app (`add_bloqueo_sheet.dart:25` lo reconoce en un comentario).
- `PausaInterstitialActivity.kt:19` y `PausaTimerService.kt:15` declaran un campo `packageName` que tapa el `packageName` propio de la actividad/servicio. Funciona, pero invita a errores.
- Las pausas se identifican por posición en la lista (`togglePausa(index)`, `updatePausa(index)`), mientras rutinas y bloqueos usan `id`.
- Tres cargas simultáneas de estadísticas al arrancar: constructor del notifier (`usage_stats_provider.dart:63`), `main.dart:46` y `splash_screen.dart:122`.
- Lista de lanzadores escrita a mano (`PausaAccessibilityService.kt:305-346`); se puede preguntar al sistema cuál es el lanzador, como ya hace `PausaTimerService.kt:196-197`.
- Textos en español fijos en el código, sin sistema de traducción (aceptable si solo va a estar en español).
- `android/gradle.properties:1` reserva 8 GB de memoria para Gradle (valor de la plantilla; puede ahogar equipos con poca RAM).

**Archivos grandes**

- `PausaAccessibilityService.kt` (598 líneas): mezcla estado global, sondeo, reglas por fabricante y lectura de preferencias. Es el candidato claro a dividir.
- El resto está en tamaños razonables (el mayor en Dart, `pausa_app_card.dart`, 363 líneas).

**Dependencias**

| Paquete | Actual | Última | Nota |
|---|---|---|---|
| `flutter_riverpod` | 2.6.1 | 3.5.0 | Salto mayor; `StateNotifier` pasa a ser API antigua |
| `go_router` | 14.8.1 | 18.1.4 | Salto mayor |
| `google_fonts` | 6.3.3 | 9.0.0 | Salto mayor (y ver bug 9) |
| `flutter_lints` | 4.0.0 | 6.0.0 | Reglas más estrictas |
| `hive_flutter` / `hive_generator` | 1.1.0 / 2.0.1 | — | Hasta donde sé, Hive 2 lleva tiempo sin mantenimiento activo; arrastra un `analyzer` 6.4.1 muy antiguo |
| `build_resolvers`, `build_runner_core` | — | — | Marcados como **descontinuados** por pub (transitivos de `build_runner` 2.4) |
| Flutter | 3.41.1 | — | De febrero de 2026 (9 meses) |

Nada de esto rompe el build hoy.

**Documentación**

- README claro y útil, pero desactualizado en cuatro puntos: versión mínima (bug 10), duración del bloqueo tras expulsión, estado de Rutinas, y "al abrir la app se solicitarán dos permisos" (`README.md:24`), cuando en realidad solo aparecen avisos en Inicio y Pausas.
- Describe las ramas `develop` y `feature/*`; el repositorio local solo trabaja en `main`.

---

## Rendimiento y UX

**Rendimiento**

- **Sondeo cada segundo, siempre.** `PausaAccessibilityService.kt:38-129` consulta UsageStats cada 1 s las 24 h, también con la pantalla apagada y aunque no haya ninguna pausa activa. Además lee y parsea el JSON de `pausa_prefs` en cada consulta (`:577-597`). Es el principal sospechoso de consumo de batería. (No medido.)
- **Eventos de accesibilidad de más.** Se suscribe a `typeWindowsChanged` y `typeViewFocused` con `FLAG_INCLUDE_NOT_IMPORTANT_VIEWS` (`:396-404`), pero solo usa `TYPE_WINDOW_STATE_CHANGED`. El sistema despierta el servicio para nada.
- **Un hilo nuevo por icono.** `MainActivity.kt:113-123` crea un `Thread` por cada `getAppIcon`; al desplazar el selector de apps se lanzan decenas. Los iconos van como PNG al 100 % y se guardan en una caché sin límite (`usage_stats_service.dart:9`).
- **Los eventos de uso del día se recorren dos veces** en cada refresco del panel (`getTotalScreenTimeMs` + `getTodayUsage`, `usage_stats_provider.dart:90-93`), cada 60 s y en cada vuelta a la app.
- **Lista de apps instaladas**: tres pasadas sobre todos los paquetes (`UsageStatsHelper.kt:157-214`). Se hace una vez y se cachea; aceptable.
- **APK de 50,9 MB** con tres arquitecturas (arm64, armv7, x86_64). Con `--split-per-abi` el de arm64 sería bastante más pequeño; x86_64 solo sirve para emuladores.

**UX**

- **Rutinas y Bloqueos aparentan funcionar y no funcionan** (bug 7). O se ocultan o se marcan como "próximamente" hasta que estén.
- **El onboarding no pide permisos.** Tras seis pantallas el usuario aterriza en Inicio con todo a cero y un aviso; la accesibilidad solo se pide en la pestaña Pausas. Sin esos dos permisos la app no hace nada, y en Android 13+ con APK externo hay además el paso de "Permitir ajustes restringidos", que solo se explica en las notas de la release.
- **Pantalla de registro engañosa**: botón de Apple en una app solo Android y promesa de cuenta que no existe.
- **La app bloqueada se ve entre 1 y 2 segundos** antes de que aparezca la pantalla de espera: el interceptado se encola en un tic y se dispara en el siguiente (`PausaAccessibilityService.kt:84-127,551-553`). (Sin probar; el README ya admite hasta 3 s.)
- **Sin aviso antes de la expulsión**: el tiempo restante solo está en una notificación silenciosa de prioridad mínima y oculta en la pantalla de bloqueo (`PausaTimerService.kt:214-228`). Con el castigo de un día entero, un aviso a 1 minuto del final sería razonable.
- **Sin ajustes**: no se puede cambiar el nombre ni las horas del onboarding, ni repetirlo, ni ver la versión.
- **Tono del diálogo de saltar bloqueo** ("¿Esclavo de la dopamina?", `pausa_app_card.dart:65-69`): es decisión de producto; lo anoto por si se quiere suavizar para público general.
- **Detalles**: el aviso de "Selecciona una app primero" se muestra detrás de la hoja inferior (`add_pausa_sheet.dart:93-97`); "Pausas activas hoy" cuenta pausas configuradas, no las que han saltado hoy (`dashboard_tab.dart:92`); la interfaz está fijada en vertical (`main.dart:18-20`).

---

## Plan de trabajo priorizado

### 🔴 Crítico

- [x] **Sincronizar siempre con el nativo.** Llamar a `_syncToNative()` en `updatePausa` y `deletePausa`. — `lib/shared/providers/pausas_provider.dart`
  - Hecho: `updatePausa` y `deletePausa` llaman a `_syncToNative()`; tests en `test/pausas_provider_test.dart`.
- [x] **Conservar `isActive` al editar una pausa** e impedir duplicados por paquete (al guardar, si ya existe, actualizar). — `lib/features/pausas/widgets/add_pausa_sheet.dart`, `lib/shared/providers/pausas_provider.dart`
  - Hecho: `updatePausa` conserva el `isActive` guardado y `addPausa` actualiza si el paquete ya existe; tests en `test/pausas_provider_test.dart`.
- [ ] **No expulsar con la pantalla apagada.** Registrar `ACTION_SCREEN_OFF` y terminar o pausar la sesión; en `isBlockedAppInForeground()` devolver `false` si no hay eventos o la pantalla no está activa. — `PausaAccessibilityService.kt`, `PausaTimerService.kt`
- [x] **Interceptar tras morir el proceso** (hallado el 14-11 con logcat: tras "cerrar todo" en MIUI, la app bloqueada abierta antes de que volviera el proceso entraba sin pausa). — `PausaAccessibilityService.kt`, nuevo `ForegroundHelper.kt`
  - Hecho: al reconectar, el primer tic busca el último evento de primer plano en una ventana de 2 h en vez de 2 s; si es el lanzador o una app sin pausa no intercepta. Pendiente de probar en dispositivo.
- [x] **Pantalla en negro al abrir Pausa en frío** (hallado el 14-11: `MainActivity` ponía el fondo de la ventana en negro puro y el fondo de arranque no tenía logo). — `MainActivity.kt`, `res/drawable*/launch_background.xml`
  - Hecho: el fondo de arranque muestra el logo centrado y `MainActivity` ya no lo sustituye por negro. Pendiente de probar en dispositivo.
- [x] **Guardar la sesión en disco.** Persistir paquete, inicio y máximo en `pausa_prefs` y restaurarlos en `onStartCommand` con intent nulo y en `onServiceConnected`. Corregir el comentario de `PausaTimerService.kt:54`. — `PausaTimerService.kt`, `PausaAccessibilityService.kt`
  - Hecho: nuevo `SessionStore.kt` guarda paquete, inicio, máximo y último latido en `pausa_prefs`; se restaura en `onStartCommand` (intent nulo o `restore`) y en `onServiceConnected`. Una sesión restaurada solo expulsa con la pantalla activa y la app confirmada delante; si no, se cierra sin expulsar. También acumula segundos usados por app y día (`used_seconds_<día>_<paquete>`) como base del límite diario. Comentario de `PausaTimerService.kt` corregido. Pendiente de probar en dispositivo.
- [x] **Alarma de reinicio del keepalive** (hallado el 14-11 con `dumpsys alarm`: tras "cerrar todo" en HyperOS la alarma quedaba aplazada ~52 min por `app_standby`, y usaba `PendingIntent.getService`). — `PausaKeepaliveService.kt`
  - Hecho: `getForegroundService` en Android 8+ y `setAndAllowWhileIdle(ELAPSED_REALTIME_WAKEUP)`; `startForeground` protegido con try/catch. Sin permisos nuevos. En Xiaomi sigue haciendo falta "Inicio automático" (probado en dispositivo: sin él el proceso no vuelve; con él vuelve en ~5 s).
- [x] **Arrancar el keepalive desde el servicio de accesibilidad** (antes solo lo lanzaba `MainActivity`, así que si el sistema revivía el servicio sin abrir la app no había notificación protegiendo el proceso). — `PausaAccessibilityService.kt`, `PausaKeepaliveService.kt`, `MainActivity.kt`
  - Hecho: nuevo `PausaKeepaliveService.start(context)` (no lanza si el sistema lo niega), llamado desde `onServiceConnected` y desde `MainActivity.onCreate`. Pendiente de probar en dispositivo.
- [ ] **Ocultar o marcar como "próximamente" Rutinas y Bloqueos** hasta que bloqueen de verdad. — `lib/features/home/widgets/bottom_nav.dart`, `lib/features/home/screens/home_screen.dart`, `lib/features/rutinas/screens/rutinas_screen.dart`, `lib/features/bloqueos/screens/bloqueos_screen.dart`
- [x] **Arreglar el nombre de la app**: `android:label="@string/app_name"`. — `android/app/src/main/AndroidManifest.xml`
  - Hecho: `android:label` de la aplicación apunta a `@string/app_name` ("Pausa").
- [ ] **Unir los dos commits sin subir** (`3f7c2e4` y `13a9239`) antes de hacer push para que el APK de 53 MB no entre en GitHub. — historial de git
- [ ] **Copia de seguridad del keystore y de `key.properties`** fuera de la carpeta del proyecto. — `android/app/upload-keystore.jks`, `android/key.properties`

### 🟠 Importante

- [ ] **Decidir el modelo de límite**: por sesión (actual) o acumulado diario. Si es diario, guardar minutos usados por paquete y día y descontarlos al iniciar sesión; si es por sesión, cambiar el texto "Has usado X por hoy". — `PausaTimerService.kt`, `PausaAccessibilityService.kt`
- [ ] **Pedir el permiso de notificaciones** en Android 13+ (canal nativo nuevo o `permission_handler`). — `MainActivity.kt`, `lib/core/services/accessibility_service.dart`, pantalla donde se pida
- [ ] **Empaquetar las fuentes** DM Sans y DM Serif Display como assets y desactivar la descarga en tiempo de ejecución. — `pubspec.yaml`, `assets/fonts/`, `lib/main.dart`
- [ ] **Pantalla de permisos al final del onboarding** (uso, accesibilidad, notificaciones, aviso de "ajustes restringidos") en lugar del registro falso. — `lib/features/auth/screens/register_screen.dart`, `lib/app/router.dart`, `lib/features/onboarding/screens/upsell_screen.dart`
- [ ] **Quitar el registro falso y el texto legal**, o escribir una política de privacidad real y enlazarla. — `lib/features/auth/screens/register_screen.dart`
- [ ] **Corregir racha y tiempo recuperado**: excluir el día en curso, usar la meta del usuario, y añadir tests. — `lib/core/utils/streak_calculator.dart`, `lib/shared/providers/usage_stats_provider.dart`, `test/streak_calculator_test.dart`
- [ ] **Cambiar el tipo del temporizador a `specialUse`** y quitar `FOREGROUND_SERVICE_MEDIA_PLAYBACK`. — `AndroidManifest.xml`, `PausaTimerService.kt`
- [ ] **Comprobar el permiso de uso con `AppOpsManager`** y permitir que vuelva a `false`. — `UsageStatsHelper.kt`, `lib/shared/providers/usage_stats_provider.dart`
- [ ] **Reducir el sondeo**: pararlo con la pantalla apagada y cuando no haya pausas activas; cachear la lista de pausas en memoria e invalidarla en `syncPausas`. — `PausaAccessibilityService.kt`, `MainActivity.kt`
- [ ] **Quitar o condicionar los logs en release** (`if (BuildConfig.DEBUG)`). — los 4 archivos Kotlin de servicios, `build.gradle.kts`
- [ ] **Arreglar la lista de recientes / lanzador**: detectar el lanzador preguntando al sistema y decidir qué hacer con recientes (hoy termina la sesión). — `PausaAccessibilityService.kt`
- [ ] **No ofrecer en el selector apps que el servicio ignora**, o quitar el filtro `com.android.*`. — `UsageStatsHelper.kt`, `PausaAccessibilityService.kt`
- [x] **Receptor de `BOOT_COMPLETED`** que arranque el keepalive. — `AndroidManifest.xml`, nuevo `BootReceiver.kt`
  - Hecho: `BootReceiver` arranca el keepalive en `BOOT_COMPLETED` y `MY_PACKAGE_REPLACED`; permiso `RECEIVE_BOOT_COMPLETED` añadido al manifest. Pendiente de probar en dispositivo.
- [ ] **Actualizar README y notas de la release**: Android 7.0+, bloqueo hasta medianoche, estado real de Rutinas/Bloqueos, permisos. — `README.md`, `NOTAS_RELEASE_v1.0.0-beta.md`, `pubspec.yaml`
- [ ] **Tests de los notifiers y modelos** (pausas, rutinas, bloqueos) con Hive en memoria. — `test/`
- [ ] **Prueba manual en dispositivo de los puntos marcados "(sin probar en dispositivo)"**, empezando por los bugs 3, 4, 6 y 9, para confirmarlos antes de invertir tiempo.

### 🟢 Mejora

- [ ] **Extraer la máquina de estados de sesión** a una clase propia sin dependencias de Android, con tests unitarios. — `PausaAccessibilityService.kt`, nuevo `SessionState.kt`
- [ ] **Unificar `_FadeSlide` y el efecto de pulsado** usando los widgets que ya existen. — los 14 archivos con `_down/_up/_cancel`, `lib/app/widgets/`
- [ ] **Borrar código muerto**: los dos selectores sin uso, `getProductiveTimeMs`/`getUnproductiveTimeMs` en los tres niveles, `hasAnyData`, `pausa_logo.xml`, `_placeholderTabs`, parámetro `onboardingDone` del router, `TODO` de `build.gradle.kts:34`.
- [ ] **Pantalla de ajustes** mínima (nombre, meta diaria, permisos, versión) y conectar el engranaje. — `lib/features/home/widgets/dashboard_tab.dart`, nueva pantalla, `lib/app/router.dart`
- [ ] **Aviso un minuto antes de la expulsión.** — `PausaTimerService.kt`
- [ ] **Refrescar el chip "Bloqueado hoy"** al volver a la app. — `lib/features/pausas/widgets/pausa_app_card.dart`
- [ ] **Identificar las pausas por paquete o `id`** en vez de por posición. — `pausas_provider.dart`, `pausas_screen.dart`, `pausa_config.dart`
- [ ] **Iconos**: usar un pool de hilos y limitar la caché. — `MainActivity.kt`, `lib/core/services/usage_stats_service.dart`
- [ ] **Calcular el uso del día en una sola llamada nativa.** — `UsageStatsHelper.kt`, `MainActivity.kt`, `usage_stats_service.dart`, `usage_stats_provider.dart`
- [ ] **Publicar APK por arquitectura** (`--split-per-abi`) para bajar el tamaño de descarga. — proceso de release
- [ ] **Renombrar `appNames` a `packageNames`** en `Bloqueo` y `Rutina` (conservando los índices de campo de Hive). — modelos y sus usos
- [ ] **Actualizar dependencias** por pasos: primero `flutter_lints`, luego `go_router`, luego Riverpod 3; valorar sustituir Hive 2. — `pubspec.yaml`
- [ ] **CI básico** (analyze + test en cada push). — `.github/workflows/`
- [ ] **Implementar de verdad Rutinas y Bloqueos**: sincronizarlos al nativo y hacer que el servicio los aplique (tarea grande; dividir en "sincronizar", "aplicar bloqueos" y "aplicar horarios"). — `rutinas_provider.dart`, `bloqueos_provider.dart`, `MainActivity.kt`, `PausaAccessibilityService.kt`
