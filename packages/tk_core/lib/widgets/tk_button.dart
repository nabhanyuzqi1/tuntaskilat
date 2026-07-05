import 'package:flutter/material.dart';

import '../theme/tk_colors.dart';

/// Tombol aksi utama 52dp full-width sesuai Hi-Fi build, dengan state loading
/// (kaidah Umpan Balik Segera). Touch target ≥ 48dp.
///
/// Umpan balik tekan: scale halus 0.97 (120ms) + ripple Material — elevation
/// dibuat konstan supaya shadow tidak "melompat" saat ditekan.
class TkButton extends StatefulWidget {
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
  State<TkButton> createState() => _TkButtonState();
}

class _TkButtonState extends State<TkButton> {
  bool _ditekan = false;

  bool get _aktif => !widget.loading && widget.onPressed != null;

  void _setDitekan(bool v) {
    if (_ditekan != v) setState(() => _ditekan = v);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _ditekan && _aktif ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Listener(
        onPointerDown: (_) => _setDitekan(true),
        onPointerUp: (_) => _setDitekan(false),
        onPointerCancel: (_) => _setDitekan(false),
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.loading ? null : widget.onPressed,
            style: ButtonStyle(
              elevation: const WidgetStatePropertyAll(6),
              shadowColor: WidgetStatePropertyAll(
                TkColors.primary.withValues(alpha: 0.25),
              ),
              overlayColor: WidgetStatePropertyAll(
                Colors.white.withValues(alpha: 0.12),
              ),
              splashFactory: InkSparkle.splashFactory,
            ),
            child: widget.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: TkColors.surface,
                    ),
                  )
                : Text(widget.label),
          ),
        ),
      ),
    );
  }
}
