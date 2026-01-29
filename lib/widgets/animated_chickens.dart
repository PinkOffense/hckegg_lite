import 'dart:math';
import 'package:flutter/material.dart';

/// Cute animated pink chicken widget for the login page
class AnimatedChickens extends StatefulWidget {
  const AnimatedChickens({super.key});

  @override
  State<AnimatedChickens> createState() => _AnimatedChickensState();
}

class _AnimatedChickensState extends State<AnimatedChickens>
    with TickerProviderStateMixin {
  late AnimationController _bobController;
  late AnimationController _blinkController;
  late Animation<double> _bobAnimation;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();

    // Body bob animation
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bobAnimation = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeInOut),
    );

    // Blink animation
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _blinkAnimation = Tween<double>(begin: 1, end: 0.1).animate(_blinkController);

    // Random blink
    _startBlinking();
  }

  void _startBlinking() async {
    while (mounted) {
      await Future.delayed(Duration(milliseconds: 2000 + Random().nextInt(3000)));
      if (mounted) {
        await _blinkController.forward();
        await _blinkController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _bobController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: Listenable.merge([_bobAnimation, _blinkAnimation]),
        builder: (context, child) {
          return CustomPaint(
            painter: _PinkChickenPainter(
              bobOffset: _bobAnimation.value,
              blinkFactor: _blinkAnimation.value,
            ),
            size: const Size(double.infinity, 180),
          );
        },
      ),
    );
  }
}

/// Custom painter for a cute pink chicken
class _PinkChickenPainter extends CustomPainter {
  final double bobOffset;
  final double blinkFactor;

  _PinkChickenPainter({
    required this.bobOffset,
    required this.blinkFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2 + bobOffset;

    // Colors
    const bodyPink = Color(0xFFFFB6C1); // Light pink
    const darkPink = Color(0xFFFF69B4); // Hot pink
    const beakOrange = Color(0xFFFF8C00);
    const combRed = Color(0xFFFF4757);
    const white = Colors.white;
    const black = Colors.black;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, size.height - 15),
        width: 90,
        height: 20,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.1),
    );

    // Legs
    final legPaint = Paint()
      ..color = beakOrange
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Left leg
    canvas.drawLine(
      Offset(centerX - 15, centerY + 35),
      Offset(centerX - 20, centerY + 55),
      legPaint,
    );
    // Left foot
    canvas.drawLine(
      Offset(centerX - 28, centerY + 55),
      Offset(centerX - 12, centerY + 55),
      legPaint,
    );

    // Right leg
    canvas.drawLine(
      Offset(centerX + 15, centerY + 35),
      Offset(centerX + 20, centerY + 55),
      legPaint,
    );
    // Right foot
    canvas.drawLine(
      Offset(centerX + 12, centerY + 55),
      Offset(centerX + 28, centerY + 55),
      legPaint,
    );

    // Body (main oval)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY + 10),
        width: 80,
        height: 65,
      ),
      Paint()..color = bodyPink,
    );

    // Body highlight
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 10, centerY + 5),
        width: 30,
        height: 25,
      ),
      Paint()..color = white.withValues(alpha: 0.3),
    );

    // Wing
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 20, centerY + 15),
        width: 25,
        height: 35,
      ),
      Paint()..color = darkPink.withValues(alpha: 0.5),
    );

    // Tail feathers
    final tailPath = Path()
      ..moveTo(centerX - 35, centerY + 5)
      ..quadraticBezierTo(centerX - 55, centerY - 15, centerX - 45, centerY + 20)
      ..quadraticBezierTo(centerX - 40, centerY + 10, centerX - 35, centerY + 15);
    canvas.drawPath(tailPath, Paint()..color = darkPink);

    // Head
    canvas.drawCircle(
      Offset(centerX, centerY - 25),
      32,
      Paint()..color = bodyPink,
    );

    // Head highlight
    canvas.drawCircle(
      Offset(centerX - 8, centerY - 32),
      10,
      Paint()..color = white.withValues(alpha: 0.4),
    );

    // Comb (on top of head)
    final combPath = Path()
      ..moveTo(centerX - 12, centerY - 52)
      ..quadraticBezierTo(centerX - 8, centerY - 70, centerX - 5, centerY - 55)
      ..quadraticBezierTo(centerX, centerY - 75, centerX + 5, centerY - 55)
      ..quadraticBezierTo(centerX + 8, centerY - 70, centerX + 12, centerY - 52)
      ..close();
    canvas.drawPath(combPath, Paint()..color = combRed);

    // Eyes
    final eyeY = centerY - 25;
    final eyeRadius = 8.0 * blinkFactor;

    // Left eye white
    canvas.drawCircle(
      Offset(centerX - 12, eyeY),
      10,
      Paint()..color = white,
    );
    // Left eye pupil
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 12, eyeY),
        width: 8,
        height: eyeRadius * 2,
      ),
      Paint()..color = black,
    );
    // Left eye shine
    if (blinkFactor > 0.5) {
      canvas.drawCircle(
        Offset(centerX - 14, eyeY - 3),
        2.5,
        Paint()..color = white,
      );
    }

    // Right eye white
    canvas.drawCircle(
      Offset(centerX + 12, eyeY),
      10,
      Paint()..color = white,
    );
    // Right eye pupil
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 12, eyeY),
        width: 8,
        height: eyeRadius * 2,
      ),
      Paint()..color = black,
    );
    // Right eye shine
    if (blinkFactor > 0.5) {
      canvas.drawCircle(
        Offset(centerX + 10, eyeY - 3),
        2.5,
        Paint()..color = white,
      );
    }

    // Beak
    final beakPath = Path()
      ..moveTo(centerX - 8, centerY - 15)
      ..lineTo(centerX, centerY - 5)
      ..lineTo(centerX + 8, centerY - 15)
      ..close();
    canvas.drawPath(beakPath, Paint()..color = beakOrange);

    // Blush cheeks
    canvas.drawCircle(
      Offset(centerX - 25, centerY - 18),
      8,
      Paint()..color = darkPink.withValues(alpha: 0.4),
    );
    canvas.drawCircle(
      Offset(centerX + 25, centerY - 18),
      8,
      Paint()..color = darkPink.withValues(alpha: 0.4),
    );
  }

  @override
  bool shouldRepaint(covariant _PinkChickenPainter oldDelegate) {
    return oldDelegate.bobOffset != bobOffset ||
        oldDelegate.blinkFactor != blinkFactor;
  }
}

/// AnimatedBuilder wrapper for Listenable.merge
class AnimatedBuilder extends StatelessWidget {
  final Listenable animation;
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: animation,
      builder: builder,
    );
  }
}
