import 'dart:ui';

import 'package:flutter/material.dart';

/// Glassmorphism sesuai design-tokens.md — HANYA untuk elemen permukaan
/// mengambang (bottom nav, app bar saat scroll, kartu di atas peta, FAB).
/// Jangan dipakai pada form input/tabel (menurunkan keterbacaan, melanggar
/// kaidah Kejelasan).
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.radius = 20,
    this.opacity = 0.55,
    this.padding,
  });

  final Widget child;
  final double radius;
  final double opacity;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: child,
        ),
      ),
    );
  }
}
