import 'package:flutter/material.dart';

import '../theme/tk_colors.dart';

/// Efek skeleton/shimmer ringan tanpa paket eksternal. Membungkus [child]
/// (biasanya kotak abu placeholder) dengan animasi kilau bergerak.
///
/// Pakai saat memuat list/detail agar UI tak "kosong" (kaidah Umpan Balik
/// Segera). Hentikan dengan mengganti ke konten asli saat data siap.
class TkShimmer extends StatefulWidget {
  const TkShimmer({super.key, required this.child});

  final Widget child;

  @override
  State<TkShimmer> createState() => _TkShimmerState();
}

class _TkShimmerState extends State<TkShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = bounds.width * (_c.value * 2 - 1);
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0x00FFFFFF),
                Color(0x66FFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: const [0.35, 0.5, 0.65],
              transform: _SlideGradient(dx / (bounds.width == 0 ? 1 : bounds.width)),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Geser gradient horizontal berdasarkan fraksi [-1..1].
class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.fraction);
  final double fraction;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * fraction, 0, 0);
}

/// Kotak placeholder abu dengan sudut membulat — blok penyusun skeleton.
class TkSkeletonBox extends StatelessWidget {
  const TkSkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: TkColors.textMuted.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Kartu skeleton siap-pakai untuk item list (avatar + 2 baris teks).
class TkSkeletonListTile extends StatelessWidget {
  const TkSkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return TkShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          const TkSkeletonBox(width: 48, height: 48, radius: 12),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                TkSkeletonBox(width: 160, height: 14),
                SizedBox(height: 8),
                TkSkeletonBox(width: 100, height: 12),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
