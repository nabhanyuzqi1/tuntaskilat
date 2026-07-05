import 'package:flutter/material.dart';

import '../theme/tk_colors.dart';

/// Tombol aksi utama 52dp full-width sesuai Hi-Fi build, dengan state loading
/// (kaidah Umpan Balik Segera). Touch target ≥ 48dp.
class TkButton extends StatelessWidget {
  const TkButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          shadowColor: TkColors.primary.withValues(alpha: 0.25),
          elevation: 6,
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: TkColors.surface,
                ),
              )
            : Text(label),
      ),
    );
  }
}
