import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';

class CalculatingScreen extends StatefulWidget {
  final Map<String, dynamic>? extra;
  const CalculatingScreen({super.key, this.extra});

  @override
  State<CalculatingScreen> createState() => _CalculatingScreenState();
}

class _CalculatingScreenState extends State<CalculatingScreen>
    with TickerProviderStateMixin {
  late AnimationController _ringController;
  late AnimationController _textController;
  late Animation<double> _ringAnimation;
  late Animation<double> _fadeText;

  int _messageIndex = 0;
  final List<String> _messages = [
    'Analizando tus hábitos...',
    'Calculando días perdidos...',
    'Proyectando años de vida...',
    'Casi listo...',
  ];

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _ringAnimation = CurvedAnimation(
      parent: _ringController,
      curve: Curves.easeInOut,
    );

    _fadeText = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    );

    _textController.forward();
    _ringController.repeat();

    // Ciclar mensajes
    Future.delayed(const Duration(milliseconds: 800), _nextMessage);

    // Navegar al resultado tras 3.5s
    Future.delayed(const Duration(milliseconds: 3500), _goToResult);
  }

  void _nextMessage() {
    if (!mounted) return;
    if (_messageIndex < _messages.length - 1) {
      _textController.reverse().then((_) {
        if (!mounted) return;
        setState(() => _messageIndex++);
        _textController.forward();
        Future.delayed(const Duration(milliseconds: 800), _nextMessage);
      });
    }
  }

  void _goToResult() {
    if (!mounted) return;
    final nombre = widget.extra?['nombre'] as String? ?? '';
    final horas = widget.extra?['horas'] as double? ?? 3.5;

    // Cálculo
    final diasAno = (horas * 365 / 24).round();
    final aniosVida = (horas * 50 / 24).round();
    final aniosRecuperables = (aniosVida * 0.45).round();

    context.goNamed('resultado', extra: {
      'nombre': nombre,
      'horas': horas,
      'diasAno': diasAno,
      'aniosVida': aniosVida,
      'aniosRecuperables': aniosRecuperables,
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PausaColors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Anillo animado
              SizedBox(
                width: 120,
                height: 120,
                child: AnimatedBuilder(
                  animation: _ringAnimation,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _RingPainter(_ringAnimation.value),
                    );
                  },
                ),
              ),

              const SizedBox(height: 48),

              // Mensaje animado
              FadeTransition(
                opacity: _fadeText,
                child: Text(
                  _messages[_messageIndex],
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    color: PausaColors.textSecondary,
                    letterSpacing: 0.02,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Track
    final trackPaint = Paint()
      ..color = PausaColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, trackPaint);

    // Arco animado
    final arcPaint = Paint()
      ..color = PausaColors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // -90 grados
      progress * 2 * 3.14159,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}