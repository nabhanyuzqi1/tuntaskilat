import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/tk_colors.dart';

/// Field input standar Hi-Fi: label kecil di atas, kotak 52dp radius 12,
/// error inline real-time dengan ikon "!" merah (kaidah Pencegahan Kesalahan).
class TkTextField extends StatelessWidget {
  const TkTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.textInputAction,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final AutovalidateMode autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: TkColors.label,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          autovalidateMode: autovalidateMode,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: TkColors.inkSoft,
          ),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            error: null,
          ),
        ),
      ],
    );
  }
}

/// Baris pesan error inline dengan lingkaran "!" merah, persis Hi-Fi build —
/// dipakai untuk error di luar TextFormField (mis. error submit form).
class TkInlineError extends StatelessWidget {
  const TkInlineError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: TkColors.error,
          ),
          alignment: Alignment.center,
          child: const Text(
            '!',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: TkColors.surface,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: TkColors.error,
            ),
          ),
        ),
      ],
    );
  }
}
