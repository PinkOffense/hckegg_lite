import 'dart:math';
import 'package:flutter/material.dart';

/// Mini chicken icon for footer and about dialog
class MiniChickenIcon extends StatelessWidget {
  final double size;

  const MiniChickenIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MiniChickenPainter(),
    );
  }
}

class _MiniChickenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final centerX = s / 2;
    final centerY = s / 2 + 2;

    // Colors
    const bodyPink = Color(0xFFFFB6C1);
    const darkPink = Color(0xFFFF69B4);
    const beakOrange = Color(0xFFFF8C00);
    const combRed = Color(0xFFFF4757);

    // Head
    canvas.drawCircle(
      Offset(centerX, centerY),
      s * 0.38,
      Paint()..color = bodyPink,
    );

    // Head highlight
    canvas.drawCircle(
      Offset(centerX - s * 0.08, centerY - s * 0.12),
      s * 0.12,
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );

    // Comb
    final combPath = Path()
      ..moveTo(centerX - s * 0.12, centerY - s * 0.32)
      ..quadraticBezierTo(centerX - s * 0.05, centerY - s * 0.52, centerX + s * 0.02, centerY - s * 0.34)
      ..quadraticBezierTo(centerX + s * 0.1, centerY - s * 0.5, centerX + s * 0.18, centerY - s * 0.3)
      ..close();
    canvas.drawPath(combPath, Paint()..color = combRed);

    // Eye (happy closed)
    final eyePath = Path()
      ..moveTo(centerX - s * 0.08, centerY - s * 0.04)
      ..quadraticBezierTo(centerX + s * 0.02, centerY - s * 0.14, centerX + s * 0.14, centerY - s * 0.04);
    canvas.drawPath(
      eyePath,
      Paint()
        ..color = Colors.black87
        ..strokeWidth = s * 0.06
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Blush
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - s * 0.18, centerY + s * 0.08),
        width: s * 0.14,
        height: s * 0.1,
      ),
      Paint()..color = darkPink.withValues(alpha: 0.5),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + s * 0.22, centerY + s * 0.08),
        width: s * 0.14,
        height: s * 0.1,
      ),
      Paint()..color = darkPink.withValues(alpha: 0.5),
    );

    // Beak
    final beakPath = Path()
      ..moveTo(centerX + s * 0.28, centerY - s * 0.02)
      ..lineTo(centerX + s * 0.46, centerY + s * 0.06)
      ..lineTo(centerX + s * 0.28, centerY + s * 0.14)
      ..close();
    canvas.drawPath(beakPath, Paint()..color = beakOrange);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Cute animated pink chicken with egg - for the login page
class AnimatedChickens extends StatefulWidget {
  final double height;

  const AnimatedChickens({super.key, this.height = 220});

  @override
  State<AnimatedChickens> createState() => _AnimatedChickensState();
}

class _AnimatedChickensState extends State<AnimatedChickens>
    with TickerProviderStateMixin {
  late AnimationController _sitController;
  late AnimationController _eggController;
  late AnimationController _heartController;
  late Animation<double> _sitAnimation;
  late Animation<double> _eggWiggle;
  late Animation<double> _heartAnimation;

  @override
  void initState() {
    super.initState();

    // Chicken sitting/nesting animation
    _sitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _sitAnimation = Tween<double>(begin: 0, end: 3).animate(
      CurvedAnimation(parent: _sitController, curve: Curves.easeInOut),
    );

    // Egg wiggle animation
    _eggController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _eggWiggle = Tween<double>(begin: 0, end: 0.08).animate(
      CurvedAnimation(parent: _eggController, curve: Curves.elasticIn),
    );

    // Heart float animation
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _heartAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeOut),
    );

    // Random egg wiggle
    _startEggWiggle();
  }

  void _startEggWiggle() async {
    while (mounted) {
      await Future.delayed(Duration(milliseconds: 3000 + Random().nextInt(2000)));
      if (mounted) {
        await _eggController.forward();
        await _eggController.reverse();
        await Future.delayed(const Duration(milliseconds: 200));
        await _eggController.forward();
        await _eggController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _sitController.dispose();
    _eggController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ListenableBuilder(
        listenable: Listenable.merge([_sitAnimation, _eggWiggle, _heartAnimation]),
        builder: (context, child) {
          return CustomPaint(
            painter: _ChickenWithEggPainter(
              sitOffset: _sitAnimation.value,
              eggWiggle: _eggWiggle.value,
              heartProgress: _heartAnimation.value,
            ),
            size: Size(double.infinity, widget.height),
          );
        },
      ),
    );
  }
}

/// Custom painter for chicken sitting on egg
class _ChickenWithEggPainter extends CustomPainter {
  final double sitOffset;
  final double eggWiggle;
  final double heartProgress;

  _ChickenWithEggPainter({
    required this.sitOffset,
    required this.eggWiggle,
    required this.heartProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final nestY = size.height * 0.82;  // Nest position (base of scene)

    // Colors
    const bodyPink = Color(0xFFFFB6C1);
    const darkPink = Color(0xFFFF69B4);
    const beakOrange = Color(0xFFFF8C00);
    const combRed = Color(0xFFFF4757);
    const eggCream = Color(0xFFFFF8DC);
    const strawLight = Color(0xFFDEB887);
    const strawMedium = Color(0xFFD2961E);
    const strawDark = Color(0xFFA0522D);

    // === LAYER 1: Back of nest (behind everything) ===
    _drawNestBack(canvas, centerX, nestY, strawMedium, strawDark);

    // === LAYER 2: Egg peeking out (mostly hidden under chicken) ===
    // Only the top of the egg is visible, nestled in the straw
    canvas.save();
    final eggY = nestY - 8;
    canvas.translate(centerX + 15, eggY);
    canvas.rotate(eggWiggle * sin(eggWiggle * 50));
    canvas.translate(-(centerX + 15), -eggY);

    // Just the top peek of egg visible from under chicken
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 15, eggY),
        width: 22,
        height: 28,
      ),
      Paint()..color = eggCream,
    );
    // Egg shine
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 10, eggY - 6),
        width: 5,
        height: 8,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
    canvas.restore();

    // === LAYER 3: Chicken body sitting IN the nest ===
    final chickenY = nestY - 35 + sitOffset;  // Lower into nest

    // Shadow under chicken (inside nest)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, nestY - 5),
        width: 80,
        height: 20,
      ),
      Paint()..color = strawDark.withValues(alpha: 0.3),
    );

    // Tail feathers (behind body)
    final tailPath = Path()
      ..moveTo(centerX - 35, chickenY)
      ..quadraticBezierTo(centerX - 60, chickenY - 25, centerX - 50, chickenY + 10)
      ..quadraticBezierTo(centerX - 45, chickenY + 5, centerX - 35, chickenY);
    canvas.drawPath(tailPath, Paint()..color = darkPink);

    // Wing behind (left)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 30, chickenY + 5),
        width: 25,
        height: 32,
      ),
      Paint()..color = darkPink.withValues(alpha: 0.6),
    );

    // Main body - fluffier, sitting shape (wider at bottom)
    final bodyPath = Path();
    bodyPath.moveTo(centerX - 40, chickenY - 5);
    bodyPath.quadraticBezierTo(centerX - 50, chickenY + 15, centerX - 35, chickenY + 28);
    bodyPath.quadraticBezierTo(centerX, chickenY + 35, centerX + 35, chickenY + 28);
    bodyPath.quadraticBezierTo(centerX + 50, chickenY + 15, centerX + 40, chickenY - 5);
    bodyPath.quadraticBezierTo(centerX, chickenY - 25, centerX - 40, chickenY - 5);
    canvas.drawPath(bodyPath, Paint()..color = bodyPink);

    // Body fluff texture - small curves to show feathers
    final fluffPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 5; i++) {
      final fx = centerX - 20 + (i * 10);
      final fy = chickenY + 10 + (i % 2 * 5);
      canvas.drawArc(
        Rect.fromCenter(center: Offset(fx, fy), width: 12, height: 8),
        0.5, 2, false, fluffPaint,
      );
    }

    // Body highlight
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 10, chickenY - 5),
        width: 28,
        height: 18,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    // Wing front (right) - tucked around egg
    final wingPath = Path()
      ..moveTo(centerX + 15, chickenY - 5)
      ..quadraticBezierTo(centerX + 40, chickenY + 5, centerX + 35, chickenY + 25)
      ..quadraticBezierTo(centerX + 25, chickenY + 30, centerX + 15, chickenY + 20)
      ..quadraticBezierTo(centerX + 10, chickenY + 10, centerX + 15, chickenY - 5);
    canvas.drawPath(wingPath, Paint()..color = darkPink.withValues(alpha: 0.5));

    // === LAYER 4: Head ===
    final headY = chickenY - 32;
    canvas.drawCircle(
      Offset(centerX + 5, headY),
      26,
      Paint()..color = bodyPink,
    );

    // Head highlight
    canvas.drawCircle(
      Offset(centerX, headY - 10),
      9,
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );

    // Comb
    final combPath = Path()
      ..moveTo(centerX - 5, headY - 22)
      ..quadraticBezierTo(centerX, headY - 38, centerX + 5, headY - 24)
      ..quadraticBezierTo(centerX + 10, headY - 40, centerX + 15, headY - 22)
      ..close();
    canvas.drawPath(combPath, Paint()..color = combRed);

    // Eye (happy closed)
    final eyePath = Path()
      ..moveTo(centerX, headY - 2)
      ..quadraticBezierTo(centerX + 8, headY - 8, centerX + 18, headY - 2);
    canvas.drawPath(
      eyePath,
      Paint()
        ..color = Colors.black87
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Blush cheeks
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX - 8, headY + 6), width: 12, height: 8),
      Paint()..color = darkPink.withValues(alpha: 0.45),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX + 22, headY + 6), width: 12, height: 8),
      Paint()..color = darkPink.withValues(alpha: 0.45),
    );

    // Beak
    final beakPath = Path()
      ..moveTo(centerX + 25, headY - 2)
      ..lineTo(centerX + 38, headY + 4)
      ..lineTo(centerX + 25, headY + 10)
      ..close();
    canvas.drawPath(beakPath, Paint()..color = beakOrange);

    // === LAYER 5: Front of nest (in front of chicken body) ===
    _drawNestFront(canvas, centerX, nestY, strawLight, strawMedium, strawDark);

    // === LAYER 6: Floating hearts ===
    _drawHeart(canvas, centerX + 50, chickenY - 55 - (heartProgress * 20),
        heartProgress, darkPink);
    _drawHeart(canvas, centerX - 45, chickenY - 45 - ((heartProgress + 0.4) % 1 * 20),
        (heartProgress + 0.4) % 1, combRed);
  }

  void _drawNestBack(Canvas canvas, double centerX, double y, Color strawMedium, Color strawDark) {
    // Back rim of nest (curved bowl shape)
    final backPath = Path()
      ..moveTo(centerX - 65, y - 15)
      ..quadraticBezierTo(centerX, y - 25, centerX + 65, y - 15)
      ..quadraticBezierTo(centerX + 75, y + 10, centerX + 55, y + 20)
      ..lineTo(centerX - 55, y + 20)
      ..quadraticBezierTo(centerX - 75, y + 10, centerX - 65, y - 15);

    // Nest shadow
    canvas.drawPath(
      backPath.shift(const Offset(3, 3)),
      Paint()..color = Colors.black.withValues(alpha: 0.1),
    );

    canvas.drawPath(backPath, Paint()..color = strawMedium);

    // Inner dark area (the inside of the nest bowl)
    final innerPath = Path()
      ..moveTo(centerX - 50, y - 10)
      ..quadraticBezierTo(centerX, y - 18, centerX + 50, y - 10)
      ..quadraticBezierTo(centerX + 55, y + 5, centerX + 40, y + 10)
      ..lineTo(centerX - 40, y + 10)
      ..quadraticBezierTo(centerX - 55, y + 5, centerX - 50, y - 10);
    canvas.drawPath(innerPath, Paint()..color = strawDark.withValues(alpha: 0.35));
  }

  void _drawNestFront(Canvas canvas, double centerX, double y, Color strawLight, Color strawMedium, Color strawDark) {
    // Front rim of nest (covers bottom of chicken body)
    final frontRimPath = Path()
      ..moveTo(centerX - 60, y - 5)
      ..quadraticBezierTo(centerX, y + 5, centerX + 60, y - 5)
      ..quadraticBezierTo(centerX + 65, y + 8, centerX + 50, y + 15)
      ..lineTo(centerX - 50, y + 15)
      ..quadraticBezierTo(centerX - 65, y + 8, centerX - 60, y - 5);
    canvas.drawPath(frontRimPath, Paint()..color = strawMedium);

    // Straw texture on front rim
    final strawPaint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 10; i++) {
      final xStart = centerX - 50 + (i * 11);
      final yOffset = sin(i * 0.8) * 3;
      strawPaint.color = i % 2 == 0 ? strawLight : strawDark.withValues(alpha: 0.6);
      canvas.drawLine(
        Offset(xStart, y + yOffset),
        Offset(xStart + 15, y + 3 + yOffset),
        strawPaint,
      );
    }

    // Straw pieces sticking up (in front)
    final stickPaint = Paint()
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Left straws
    stickPaint.color = strawLight;
    canvas.drawLine(Offset(centerX - 55, y - 5), Offset(centerX - 65, y - 18), stickPaint);
    canvas.drawLine(Offset(centerX - 48, y - 2), Offset(centerX - 58, y - 15), stickPaint);

    // Right straws
    stickPaint.color = strawMedium;
    canvas.drawLine(Offset(centerX + 55, y - 5), Offset(centerX + 65, y - 16), stickPaint);
    canvas.drawLine(Offset(centerX + 48, y - 2), Offset(centerX + 60, y - 14), stickPaint);

    // Front highlight on rim
    final highlightPath = Path()
      ..moveTo(centerX - 50, y)
      ..quadraticBezierTo(centerX, y + 6, centerX + 50, y);
    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = strawLight.withValues(alpha: 0.8)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawNest(Canvas canvas, double centerX, double y) {
    // This method is kept for compatibility but the nest is now drawn in parts
  }

  void _drawHeart(Canvas canvas, double x, double y, double progress, Color color) {
    final opacity = (1 - progress).clamp(0.0, 1.0);
    final scale = 0.5 + (progress * 0.5);

    canvas.save();
    canvas.translate(x, y);
    canvas.scale(scale);

    final path = Path()
      ..moveTo(0, 4)
      ..cubicTo(-10, -6, -18, 4, 0, 18)
      ..cubicTo(18, 4, 10, -6, 0, 4);

    canvas.drawPath(
      path,
      Paint()..color = color.withValues(alpha: opacity * 0.8),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ChickenWithEggPainter oldDelegate) {
    return oldDelegate.sitOffset != sitOffset ||
        oldDelegate.eggWiggle != eggWiggle ||
        oldDelegate.heartProgress != heartProgress;
  }
}
