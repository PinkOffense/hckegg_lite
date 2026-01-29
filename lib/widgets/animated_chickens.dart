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

    _sitAnimation = Tween<double>(begin: 0, end: 4).animate(
      CurvedAnimation(parent: _sitController, curve: Curves.easeInOut),
    );

    // Egg wiggle animation
    _eggController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _eggWiggle = Tween<double>(begin: 0, end: 0.1).animate(
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
      height: 160,
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
            size: const Size(double.infinity, 160),
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
    final baseY = size.height * 0.7;

    // Colors
    const bodyPink = Color(0xFFFFB6C1);
    const darkPink = Color(0xFFFF69B4);
    const beakOrange = Color(0xFFFF8C00);
    const combRed = Color(0xFFFF4757);
    const eggWhite = Color(0xFFFFFAF0);
    const eggShadow = Color(0xFFFFE4B5);

    // Nest/straw
    _drawNest(canvas, centerX, baseY + 15);

    // Egg (behind chicken)
    canvas.save();
    canvas.translate(centerX, baseY - 5);
    canvas.rotate(eggWiggle * sin(eggWiggle * 50));
    canvas.translate(-centerX, -(baseY - 5));

    // Egg shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 3, baseY),
        width: 38,
        height: 48,
      ),
      Paint()..color = eggShadow,
    );
    // Egg
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, baseY - 5),
        width: 35,
        height: 45,
      ),
      Paint()..color = eggWhite,
    );
    // Egg shine
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 8, baseY - 15),
        width: 8,
        height: 12,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
    canvas.restore();

    // Chicken body (sitting on egg)
    final chickenY = baseY - 35 + sitOffset;

    // Wing behind
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 25, chickenY + 5),
        width: 20,
        height: 28,
      ),
      Paint()..color = darkPink.withValues(alpha: 0.6),
    );

    // Body
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, chickenY),
        width: 60,
        height: 45,
      ),
      Paint()..color = bodyPink,
    );

    // Body highlight
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 8, chickenY - 5),
        width: 20,
        height: 15,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.3),
    );

    // Wing front
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 18, chickenY + 3),
        width: 18,
        height: 25,
      ),
      Paint()..color = darkPink.withValues(alpha: 0.5),
    );

    // Tail
    final tailPath = Path()
      ..moveTo(centerX - 28, chickenY - 5)
      ..quadraticBezierTo(centerX - 45, chickenY - 20, centerX - 38, chickenY + 5)
      ..quadraticBezierTo(centerX - 35, chickenY, centerX - 28, chickenY);
    canvas.drawPath(tailPath, Paint()..color = darkPink);

    // Head
    final headY = chickenY - 30;
    canvas.drawCircle(
      Offset(centerX + 5, headY),
      22,
      Paint()..color = bodyPink,
    );

    // Head highlight
    canvas.drawCircle(
      Offset(centerX, headY - 8),
      7,
      Paint()..color = Colors.white.withValues(alpha: 0.4),
    );

    // Comb
    final combPath = Path()
      ..moveTo(centerX - 2, headY - 20)
      ..quadraticBezierTo(centerX + 2, headY - 32, centerX + 6, headY - 22)
      ..quadraticBezierTo(centerX + 10, headY - 35, centerX + 14, headY - 20)
      ..close();
    canvas.drawPath(combPath, Paint()..color = combRed);

    // Eye (happy/closed when sitting)
    // Closed happy eye (arc)
    final eyePath = Path()
      ..moveTo(centerX, headY - 2)
      ..quadraticBezierTo(centerX + 8, headY - 8, centerX + 16, headY - 2);
    canvas.drawPath(
      eyePath,
      Paint()
        ..color = Colors.black
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Blush
    canvas.drawCircle(
      Offset(centerX - 8, headY + 5),
      6,
      Paint()..color = darkPink.withValues(alpha: 0.4),
    );
    canvas.drawCircle(
      Offset(centerX + 20, headY + 5),
      6,
      Paint()..color = darkPink.withValues(alpha: 0.4),
    );

    // Beak (small and cute)
    final beakPath = Path()
      ..moveTo(centerX + 20, headY)
      ..lineTo(centerX + 30, headY + 3)
      ..lineTo(centerX + 20, headY + 6)
      ..close();
    canvas.drawPath(beakPath, Paint()..color = beakOrange);

    // Floating hearts
    _drawHeart(canvas, centerX + 40, chickenY - 50 - (heartProgress * 30),
               heartProgress, darkPink);
    _drawHeart(canvas, centerX - 35, chickenY - 40 - ((heartProgress + 0.3) % 1 * 30),
               (heartProgress + 0.3) % 1, combRed);
  }

  void _drawNest(Canvas canvas, double centerX, double y) {
    const strawColor = Color(0xFFDEB887);
    const strawDark = Color(0xFFD2691E);

    final paint = Paint()
      ..color = strawColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final darkPaint = Paint()
      ..color = strawDark
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Draw straw pieces
    for (int i = 0; i < 12; i++) {
      final x = centerX - 40 + (i * 7);
      final wobble = sin(i * 0.8) * 5;
      canvas.drawLine(
        Offset(x, y + wobble),
        Offset(x + 15, y - 8 + wobble),
        i % 2 == 0 ? paint : darkPaint,
      );
    }

    // Nest base curve
    final nestPath = Path()
      ..moveTo(centerX - 50, y)
      ..quadraticBezierTo(centerX, y + 20, centerX + 50, y);
    canvas.drawPath(
      nestPath,
      Paint()
        ..color = strawDark
        ..strokeWidth = 8
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
      ..cubicTo(-8, -4, -14, 4, 0, 14)
      ..cubicTo(14, 4, 8, -4, 0, 4);

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
