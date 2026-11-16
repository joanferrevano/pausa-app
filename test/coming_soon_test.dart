import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pausa_app/core/widgets/coming_soon_view.dart';
import 'package:pausa_app/features/home/widgets/bottom_nav.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> show(WidgetTester tester, Widget child) async {
    // Las fuentes de Google no están disponibles en test; se ignora ese aviso.
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('GoogleFonts')) return;
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
    await tester.pump();
  }

  testWidgets('Rutinas: icono, título, Próximamente y frase', (tester) async {
    await show(
      tester,
      ComingSoonView(
        icon: navIcons[2],
        title: 'Rutinas',
        description: 'Bloquea apps según el horario que elijas.',
      ),
    );
    expect(find.byIcon(navIcons[2]), findsOneWidget);
    expect(find.text('Rutinas'), findsOneWidget);
    expect(find.text('Próximamente'), findsOneWidget);
    expect(find.text('Bloquea apps según el horario que elijas.'),
        findsOneWidget);
  });

  testWidgets('Bloqueos: icono, título, Próximamente y frase', (tester) async {
    await show(
      tester,
      ComingSoonView(
        icon: navIcons[3],
        title: 'Bloqueos',
        description: 'Bloquea apps durante un tiempo, sin poder entrar.',
      ),
    );
    expect(find.byIcon(navIcons[3]), findsOneWidget);
    expect(find.text('Bloqueos'), findsOneWidget);
    expect(find.text('Próximamente'), findsOneWidget);
    expect(find.text('Bloquea apps durante un tiempo, sin poder entrar.'),
        findsOneWidget);
  });
}
