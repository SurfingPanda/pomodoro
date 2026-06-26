import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// An animated circular timer illustration used as the hero of the Focus
/// screen. A faint clock track with minute ticks sits behind a slowly
/// orbiting "comet" arc, with [child] (usually the chosen duration) centered
/// and gently pulsing. Purely decorative — no progress is implied.
class FocusRing extends StatefulWidget {
  final double size;
  final Widget child;

  const FocusRing({super.key, this.size = 220, required this.child});

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pulse = 1 + 0.02 * math.sin(_controller.value * 2 * math.pi);
          return CustomPaint(
            painter: _RingPainter(_controller.value),
            child: Center(
              child: Transform.scale(scale: pulse, child: child),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  /// Animation phase in the range [0, 1).
  final double t;
  _RingPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 16;

    // Faint background track.
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..color = AppColors.accent.withValues(alpha: 0.08);
    canvas.drawCircle(center, radius, track);

    // Minute ticks, every fifth one longer/darker like a clock face.
    final tick = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 60; i++) {
      final angle = (i / 60) * 2 * math.pi - math.pi / 2;
      final major = i % 5 == 0;
      final outer = radius - 20;
      final inner = outer - (major ? 9 : 4);
      tick
        ..strokeWidth = major ? 2.4 : 1.2
        ..color = AppColors.accent.withValues(alpha: major ? 0.22 : 0.10);
      canvas.drawLine(
        center + Offset(math.cos(angle) * outer, math.sin(angle) * outer),
        center + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
        tick,
      );
    }

    // Orbiting comet arc with a soft fading tail.
    final rect = Rect.fromCircle(center: center, radius: radius);
    const sweep = math.pi * 0.55;
    final start = t * 2 * math.pi - math.pi / 2;
    final shader = SweepGradient(
      startAngle: 0,
      endAngle: sweep,
      colors: [
        AppColors.accent.withValues(alpha: 0),
        AppColors.accent,
        AppColors.accentDark,
      ],
      stops: const [0.0, 0.7, 1.0],
      transform: GradientRotation(start),
    ).createShader(rect);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..shader = shader;
    canvas.drawArc(rect, start, sweep, false, arc);

    // Leading dot at the head of the comet.
    final headAngle = start + sweep;
    final head = center + Offset(math.cos(headAngle) * radius, math.sin(headAngle) * radius);
    canvas.drawCircle(head, 9, Paint()..color = Colors.white);
    canvas.drawCircle(head, 6, Paint()..color = AppColors.accentDark);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.t != t;
}
