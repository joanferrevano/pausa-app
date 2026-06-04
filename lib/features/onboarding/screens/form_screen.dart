import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  final TextEditingController _nameController = TextEditingController();
  double _hours = 3.5;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _continuar() {
    final nombre = _nameController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: PausaColors.surface,
          content: Text(
            'Escribe tu nombre para continuar',
            style: GoogleFonts.dmSans(color: PausaColors.textPrimary),
          ),
        ),
      );
      return;
    }
    context.goNamed(
      'calculando',
      extra: {'nombre': nombre, 'horas': _hours},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PausaColors.black,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 64),

                Text(
                  'Vamos a descubrir\ncuánto tiempo\nperderás en tu vida.',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 32,
                    height: 1.2,
                    color: PausaColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 48),

                // Campo nombre
                Text(
                  'CÓMO TE LLAMAS',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    letterSpacing: 0.14,
                    color: PausaColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    color: PausaColors.textPrimary,
                  ),
                  cursorColor: PausaColors.white,
                  decoration: InputDecoration(
                    hintText: 'Tu nombre',
                    hintStyle: GoogleFonts.dmSans(
                      fontSize: 18,
                      color: PausaColors.textMuted,
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: PausaColors.border),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: PausaColors.white),
                    ),
                    filled: false,
                  ),
                ),

                const SizedBox(height: 48),

                // Slider horas
                Text(
                  'TIEMPO DIARIO EN EL MÓVIL',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    letterSpacing: 0.14,
                    color: PausaColors.textMuted,
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _hours.toStringAsFixed(1),
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 56,
                        height: 1.0,
                        color: PausaColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'h / día',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          color: PausaColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 1.5,
                    activeTrackColor: PausaColors.white,
                    inactiveTrackColor: PausaColors.border,
                    thumbColor: PausaColors.white,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    value: _hours,
                    min: 0.5,
                    max: 12.0,
                    divisions: 23,
                    onChanged: (v) => setState(() => _hours = v),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0.5h', style: GoogleFonts.dmSans(fontSize: 11, color: PausaColors.textMuted)),
                    Text('12h', style: GoogleFonts.dmSans(fontSize: 11, color: PausaColors.textMuted)),
                  ],
                ),

                const Spacer(),

                GestureDetector(
                  onTap: _continuar,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: PausaColors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'Calcular tiempo perdido',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: PausaColors.black,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}