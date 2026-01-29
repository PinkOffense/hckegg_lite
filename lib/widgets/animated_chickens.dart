import 'dart:math';
import 'package:flutter/material.dart';

/// Cute animated pink chicken with egg - for the login page
class AnimatedChickens extends StatefulWidget {
  const AnimatedChickens({super.key});

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
      height: 180,
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
            size: const Size(double.infinity, 180),
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
    final baseY = size.height * 0.75;

    // Colors
    const bodyPink = Color(0xFFFFB6C1);
    const darkPink = Color(0xFFFF69B4);
    const beakOrange = Color(0xFFFF8C00);
    const combRed = Color(0xFFFF4757);
    const eggCream = Color(0xFFFFF8DC);
    const eggShadow = Color(0xFFFFE4B5);

    // Draw nest first (behind everything)
    _drawNest(canvas, centerX, baseY + 20);

    // Egg (smaller, behind chicken)
    canvas.save();
    canvas.translate(centerX, baseY);
    canvas.rotate(eggWiggle * sin(eggWiggle * 50));
    canvas.translate(-centerX, -baseY);

    // Egg shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 2, baseY + 5),
        width: 28,
        height: 36,
      ),
      Paint()..color = eggShadow,
    );
    // Egg main
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, baseY),
        width: 26,
        height: 34,
      ),
      Paint()..color = eggCream,
    );
    // Egg shine
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 6, baseY - 8),
        width: 6,
        height: 10,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
    canvas.restore();

    // Chicken body (bigger, sitting on egg)
    final chickenY = baseY - 45 + sitOffset;

    // Shadow under chicken
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, baseY + 15),
        width: 70,
        height: 18,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );

    // Wing behind (left)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 35, chickenY + 8),
        width: 28,
        height: 38,
      ),
      Paint()..color = darkPink.withValues(alpha: 0.6),
    );

    // Body (bigger)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, chickenY),
        width: 85,
        height: 65,
      ),
      Paint()..color = bodyPink,
    );

    // Body highlight
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 12, chickenY - 10),
        width: 30,
        height: 22,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    // Wing front (right)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 25, chickenY + 5),
        width: 25,
        height: 35,
      ),
      Paint()..color = darkPink.withValues(alpha: 0.5),
    );

    // Tail feathers
    final tailPath = Path()
      ..moveTo(centerX - 40, chickenY - 8)
      ..quadraticBezierTo(centerX - 65, chickenY - 30, centerX - 55, chickenY + 5)
      ..quadraticBezierTo(centerX - 50, chickenY, centerX - 40, chickenY);
    canvas.drawPath(tailPath, Paint()..color = darkPink);

    // Small tail accent
    final tailPath2 = Path()
      ..moveTo(centerX - 38, chickenY - 5)
      ..quadraticBezierTo(centerX - 58, chickenY - 20, centerX - 50, chickenY + 8);
    canvas.drawPath(
      tailPath2,
      Paint()
        ..color = darkPink.withValues(alpha: 0.7)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Head (bigger)
    final headY = chickenY - 40;
    canvas.drawCircle(
      Offset(centerX + 8, headY),
      30,
      Paint()..color = bodyPink,
    );

    // Head highlight
    canvas.drawCircle(
      Offset(centerX + 2, headY - 12),
      10,
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );

    // Comb (bigger, more defined)
    final combPath = Path()
      ..moveTo(centerX - 5, headY - 26)
      ..quadraticBezierTo(centerX + 2, headY - 45, centerX + 8, headY - 28)
      ..quadraticBezierTo(centerX + 14, headY - 48, centerX + 20, headY - 26)
      ..close();
    canvas.drawPath(combPath, Paint()..color = combRed);

    // Comb highlight
    canvas.drawCircle(
      Offset(centerX + 5, headY - 35),
      4,
      Paint()..color = Colors.white.withValues(alpha: 0.3),
    );

    // Eye (happy/closed - curved line)
    final eyePath = Path()
      ..moveTo(centerX + 2, headY - 2)
      ..quadraticBezierTo(centerX + 12, headY - 10, centerX + 22, headY - 2);
    canvas.drawPath(
      eyePath,
      Paint()
        ..color = Colors.black87
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Blush cheeks
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 10, headY + 8),
        width: 14,
        height: 10,
      ),
      Paint()..color = darkPink.withValues(alpha: 0.45),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 28, headY + 8),
        width: 14,
        height: 10,
      ),
      Paint()..color = darkPink.withValues(alpha: 0.45),
    );

    // Beak
    final beakPath = Path()
      ..moveTo(centerX + 30, headY - 2)
      ..lineTo(centerX + 45, headY + 4)
      ..lineTo(centerX + 30, headY + 10)
      ..close();
    canvas.drawPath(beakPath, Paint()..color = beakOrange);

    // Beak highlight
    canvas.drawPath(
      Path()
        ..moveTo(centerX + 32, headY)
        ..lineTo(centerX + 40, headY + 3)
        ..lineTo(centerX + 32, headY + 5)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.3),
    );

    // Floating hearts
    _drawHeart(canvas, centerX + 55, chickenY - 60 - (heartProgress * 25),
        heartProgress, darkPink);
    _drawHeart(canvas, centerX - 50, chickenY - 50 - ((heartProgress + 0.4) % 1 * 25),
        (heartProgress + 0.4) % 1, combRed);
  }

  void _drawNest(Canvas canvas, double centerX, double y) {
    // Nest colors
    const strawLight = Color(0xFFDEB887);
    const strawMedium = Color(0xFFD2961E);
    const strawDark = Color(0xFFA0522D);

    // Nest base (oval bowl shape)
    final nestBasePath = Path()
      ..moveTo(centerX - 60, y - 5)
      ..quadraticBezierTo(centerX - 70, y + 25, centerX - 50, y + 30)
      ..lineTo(centerX + 50, y + 30)
      ..quadraticBezierTo(centerX + 70, y + 25, centerX + 60, y - 5)
      ..quadraticBezierTo(centerX, y + 15, centerX - 60, y - 5);

    // Nest shadow
    canvas.drawPath(
      nestBasePath.shift(const Offset(3, 3)),
      Paint()..color = Colors.black.withValues(alpha: 0.1),
    );

    // Nest fill
    canvas.drawPath(nestBasePath, Paint()..color = strawMedium);

    // Inner nest darker area
    final innerNestPath = Path()
      ..moveTo(centerX - 45, y)
      ..quadraticBezierTo(centerX - 50, y + 15, centerX - 35, y + 18)
      ..lineTo(centerX + 35, y + 18)
      ..quadraticBezierTo(centerX + 50, y + 15, centerX + 45, y)
      ..quadraticBezierTo(centerX, y + 10, centerX - 45, y);
    canvas.drawPath(innerNestPath, Paint()..color = strawDark.withValues(alpha: 0.4));

    // Straw texture - horizontal strokes
    final strawPaint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      final xStart = centerX - 55 + (i * 14);
      final yOffset = sin(i * 0.7) * 4;
      strawPaint.color = i % 2 == 0 ? strawLight : strawDark;
      canvas.drawLine(
        Offset(xStart, y + 5 + yOffset),
        Offset(xStart + 20, y + 8 + yOffset),
        strawPaint,
      );
    }

    // Straw pieces sticking out on edges
    final stickingStrawPaint = Paint()
      ..color = strawLight
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Left side straws
    canvas.drawLine(Offset(centerX - 58, y), Offset(centerX - 68, y - 12), stickingStrawPaint);
    canvas.drawLine(Offset(centerX - 52, y + 5), Offset(centerX - 65, y - 5), stickingStrawPaint);
    canvas.drawLine(Offset(centerX - 55, y + 10), Offset(centerX - 70, y + 5), stickingStrawPaint);

    // Right side straws
    stickingStrawPaint.color = strawMedium;
    canvas.drawLine(Offset(centerX + 58, y), Offset(centerX + 68, y - 10), stickingStrawPaint);
    canvas.drawLine(Offset(centerX + 52, y + 5), Offset(centerX + 65, y - 3), stickingStrawPaint);
    canvas.drawLine(Offset(centerX + 55, y + 10), Offset(centerX + 70, y + 8), stickingStrawPaint);

    // Nest rim highlight
    final rimPath = Path()
      ..moveTo(centerX - 55, y)
      ..quadraticBezierTo(centerX, y - 8, centerX + 55, y);
    canvas.drawPath(
      rimPath,
      Paint()
        ..color = strawLight
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
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
