import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../app/widgets/fade_slide_in.dart';
import '../../../app/widgets/pausa_primary_button.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final TextEditingController _nameController = TextEditingController();
  double _hours = 3.5;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _continuar() {
    final nombre = _nameController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
      // resizeToAvoidBottomInset: true is the default — the SingleChildScrollView
      // below handles the overflow when the keyboard appears
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 64),

              // Headline
              FadeSlideIn(
                delay: const Duration(milliseconds: 0),
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'Vamos a descubrir\ncuánto tiempo\nperderás en tu vida.',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 32,
                    height: 1.2,
                    color: PausaColors.textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 56),

              // Name field
              FadeSlideIn(
                delay: const Duration(milliseconds: 160),
                duration: const Duration(milliseconds: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CÓMO TE LLAMAS',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.16,
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
                      cursorWidth: 1.5,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Tu nombre',
                        hintStyle: GoogleFonts.dmSans(
                          fontSize: 18,
                          color: PausaColors.textMuted,
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: PausaColors.border,
                            width: 0.5,
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: PausaColors.white,
                            width: 0.5,
                          ),
                        ),
                        filled: false,
                        isDense: true,
                        contentPadding: const EdgeInsets.only(bottom: 10),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 56),

              // Hours slider
              FadeSlideIn(
                delay: const Duration(milliseconds: 320),
                duration: const Duration(milliseconds: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIEMPO DIARIO EN EL MÓVIL',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.16,
                        color: PausaColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _hours.toStringAsFixed(1),
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 64,
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

                    const SizedBox(height: 24),

                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 1.0,
                        activeTrackColor: PausaColors.white,
                        inactiveTrackColor: PausaColors.border,
                        thumbColor: PausaColors.white,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                          elevation: 0,
                          pressedElevation: 0,
                        ),
                        overlayShape: SliderComponentShape.noOverlay,
                        trackShape: const RectangularSliderTrackShape(),
                      ),
                      child: Slider(
                        value: _hours,
                        min: 0.5,
                        max: 12.0,
                        divisions: 23,
                        onChanged: (v) {
                          HapticFeedback.selectionClick();
                          setState(() => _hours = v);
                        },
                      ),
                    ),

                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '0.5h',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: PausaColors.textMuted,
                          ),
                        ),
                        Text(
                          '12h',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: PausaColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 56),

              FadeSlideIn(
                delay: const Duration(milliseconds: 480),
                duration: const Duration(milliseconds: 500),
                child: PausaPrimaryButton(
                  label: 'Calcular tiempo perdido',
                  onTap: _continuar,
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
