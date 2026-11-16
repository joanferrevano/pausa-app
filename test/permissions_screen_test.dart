import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pausa_app/features/onboarding/screens/permissions_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const accessibility = MethodChannel('com.pausa.pausa_app/accessibility');
  const usage = MethodChannel('com.pausa.pausa_app/usage_stats');

  void mockNative({
    bool notifications = false,
    bool usageAccess = false,
    bool accessibilityOn = false,
    bool xiaomi = false,
    int sdk = 34,
  }) {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(accessibility, (call) async {
      switch (call.method) {
        case 'areNotificationsEnabled':
          return notifications;
        case 'isAccessibilityEnabled':
        case 'isAccessibilityRunning':
          return accessibilityOn;
        case 'isXiaomi':
          return xiaomi;
        case 'sdkInt':
          return sdk;
      }
      return null;
    });
    messenger.setMockMethodCallHandler(usage, (call) async {
      if (call.method == 'hasPermission') return usageAccess;
      return null;
    });
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    // Las fuentes de Google no están disponibles en test; se ignora ese aviso.
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('GoogleFonts')) return;
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);

    // Pantalla alta para que la lista construya todos los pasos.
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 3000);
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const PermissionsScreen(fromOnboarding: true),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (_, __) => const Scaffold(body: Text('INICIO')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('sin permisos: todo pendiente y aviso al continuar',
      (tester) async {
    mockNative();
    await pumpScreen(tester);

    expect(find.text('Pendiente'), findsNWidgets(3));
    expect(find.text('Concedido'), findsNothing);
    expect(find.textContaining('Inicio automático y batería'), findsNothing);
    expect(find.textContaining('Permitir ajustes restringidos'), findsOneWidget);

    await tester.tap(find.text('Ir al inicio'));
    await tester.pumpAndSettle();
    expect(find.text('Las pausas no funcionarán'), findsOneWidget);

    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('INICIO'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_done'), isNull);

    await tester.tap(find.text('Ir al inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar igualmente'));
    await tester.pumpAndSettle();
    expect(find.text('INICIO'), findsOneWidget);
    expect(prefs.getBool('onboarding_done'), isTrue);
  });

  testWidgets('todo concedido: entra al inicio sin aviso', (tester) async {
    mockNative(notifications: true, usageAccess: true, accessibilityOn: true);
    await pumpScreen(tester);

    expect(find.text('Concedido'), findsNWidgets(3));
    expect(find.text('Pendiente'), findsNothing);
    // Con todo concedido no hacen falta los botones ni la nota.
    expect(find.text('Abrir Accesibilidad'), findsNothing);
    expect(find.textContaining('Permitir ajustes restringidos'), findsNothing);

    await tester.tap(find.text('Ir al inicio'));
    await tester.pumpAndSettle();
    expect(find.text('Las pausas no funcionarán'), findsNothing);
    expect(find.text('INICIO'), findsOneWidget);
  });

  testWidgets('Xiaomi: paso propio antes de Accesibilidad, con casilla',
      (tester) async {
    mockNative(
      notifications: true,
      usageAccess: true,
      accessibilityOn: true,
      xiaomi: true,
    );
    await pumpScreen(tester);

    final xiaomiStep = find.text('3. Inicio automático y batería');
    final accessStep = find.text('4. Accesibilidad');
    expect(xiaomiStep, findsOneWidget);
    expect(accessStep, findsOneWidget);
    expect(
      tester.getTopLeft(xiaomiStep).dy,
      lessThan(tester.getTopLeft(accessStep).dy),
    );

    // Sin marcar la casilla, avisa antes de continuar.
    await tester.tap(find.text('Ir al inicio'));
    await tester.pumpAndSettle();
    expect(find.text('Pausa puede dejar de funcionar'), findsOneWidget);
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ya lo he hecho'));
    await tester.pumpAndSettle();
    expect(find.text('Hecho'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(xiaomiSetupDoneKey), isTrue);

    await tester.tap(find.text('Ir al inicio'));
    await tester.pumpAndSettle();
    expect(find.text('INICIO'), findsOneWidget);
  });

  testWidgets('Android 12 o inferior: sin nota de ajustes restringidos',
      (tester) async {
    mockNative(sdk: 31);
    await pumpScreen(tester);

    expect(find.text('Abrir Accesibilidad'), findsOneWidget);
    expect(find.textContaining('Permitir ajustes restringidos'), findsNothing);
    expect(find.text('Ficha de la app'), findsNothing);
  });

  testWidgets('solo faltan notificaciones: deja pasar con una nota',
      (tester) async {
    mockNative(usageAccess: true, accessibilityOn: true);
    await pumpScreen(tester);

    expect(find.textContaining('Sin notificaciones no verás'), findsOneWidget);
    await tester.tap(find.text('Ir al inicio'));
    await tester.pumpAndSettle();
    expect(find.text('INICIO'), findsOneWidget);
  });
}
