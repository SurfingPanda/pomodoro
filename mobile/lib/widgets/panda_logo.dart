import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A winking panda head, drawn as vector art so it stays crisp at any size.
class PandaLogo extends StatelessWidget {
  final double size;
  const PandaLogo({super.key, this.size = 104});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PandaPainter()),
    );
  }
}

class _PandaPainter extends CustomPainter {
  static const _ink = Color(0xFF222933); // soft black
  static const _blush = Color(0xB3FFB3BF); // ~70% pink

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final ink = Paint()
      ..color = _ink
      ..isAntiAlias = true;
    final white = Paint()
      ..color = Colors.white
      ..isAntiAlias = true;

    // --- Ears (drawn first so the face overlaps their lower half) ---
    canvas.drawCircle(Offset(w * 0.26, h * 0.20), w * 0.155, ink);
    canvas.drawCircle(Offset(w * 0.74, h * 0.20), w * 0.155, ink);

    // --- Face ---
    final faceRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.57),
      width: w * 0.88,
      height: h * 0.82,
    );
    canvas.drawOval(faceRect, white);

    // --- Eye patches (tilted black ellipses) ---
    void drawPatch(double cx, double cy, double angle) {
      canvas.save();
      canvas.translate(w * cx, h * cy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: w * 0.24,
          height: h * 0.30,
        ),
        ink,
      );
      canvas.restore();
    }

    drawPatch(0.355, 0.52, 0.45);
    drawPatch(0.645, 0.52, -0.45);

    // --- Right eye: open, looking at you ---
    final rightEye = Offset(w * 0.655, h * 0.535);
    canvas.drawCircle(rightEye, w * 0.06, white);
    canvas.drawCircle(rightEye, w * 0.032, ink);
    canvas.drawCircle(
      rightEye + Offset(-w * 0.015, -h * 0.015),
      w * 0.013,
      white,
    );

    // --- Left eye: the wink (a happy upward curve) ---
    final wink = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.028
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.345, h * 0.55),
        width: w * 0.13,
        height: h * 0.11,
      ),
      math.pi * 0.95, // start near the left
      math.pi * 1.1, // sweep across the bottom -> "‿"
      false,
      wink,
    );

    // --- Blush ---
    final blush = Paint()..color = _blush;
    canvas.drawCircle(Offset(w * 0.25, h * 0.64), w * 0.055, blush);
    canvas.drawCircle(Offset(w * 0.75, h * 0.64), w * 0.055, blush);

    // --- Nose ---
    final nx = w * 0.5, ny = h * 0.645;
    final nose = Path()
      ..moveTo(nx - w * 0.055, ny)
      ..quadraticBezierTo(nx, ny - h * 0.025, nx + w * 0.055, ny)
      ..quadraticBezierTo(nx + w * 0.03, ny + h * 0.055, nx, ny + h * 0.06)
      ..quadraticBezierTo(nx - w * 0.03, ny + h * 0.055, nx - w * 0.055, ny)
      ..close();
    canvas.drawPath(nose, ink);

    // --- Mouth (small line + two smile curves) ---
    final mouth = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.022
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(nx, ny + h * 0.06),
      Offset(nx, ny + h * 0.10),
      mouth,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(nx - w * 0.055, ny + h * 0.10),
        width: w * 0.11,
        height: h * 0.07,
      ),
      0,
      math.pi,
      false,
      mouth,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(nx + w * 0.055, ny + h * 0.10),
        width: w * 0.11,
        height: h * 0.07,
      ),
      0,
      math.pi,
      false,
      mouth,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
