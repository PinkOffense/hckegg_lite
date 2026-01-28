import 'dart:math';
import 'package:flutter/material.dart';

/// Animated chickens widget that shows cute chickens pecking at corn
/// Creates a charming scene for the login page
class AnimatedChickens extends StatefulWidget {
  const AnimatedChickens({super.key});

  @override
  State<AnimatedChickens> createState() => _AnimatedChickensState();
}

class _AnimatedChickensState extends State<AnimatedChickens>
    with TickerProviderStateMixin {
  late final List<_ChickenController> _chickens;

  @override
  void initState() {
    super.initState();
    // Create 3 chickens with different positions and timing
    _chickens = [
      _ChickenController(
        this,
        initialX: 0.15,
        color: const Color(0xFFD4A373), // Light brown
        peckDelay: 0,
        facingRight: true,
      ),
      _ChickenController(
        this,
        initialX: 0.5,
        color: const Color(0xFFBC6C25), // Dark brown
        peckDelay: 400,
        facingRight: false,
      ),
      _ChickenController(
        this,
        initialX: 0.8,
        color: const Color(0xFFFAEDCD), // Cream/white
        peckDelay: 800,
        facingRight: true,
      ),
    ];
  }

  @override
  void dispose() {
    for (final chicken in _chickens) {
      chicken.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ground with grass
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 30),
              painter: _GroundPainter(),
            ),
          ),
          // Corn scattered on ground
          ..._buildCornKernels(),
          // Chickens
          for (final chicken in _chickens)
            ListenableBuilder(
              listenable: Listenable.merge([
                chicken.peckAnimation,
                chicken.walkAnimation,
                chicken.bobAnimation,
              ]),
              builder: (context, child) {
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: 25,
                  child: FractionallySizedBox(
                    alignment: Alignment(chicken.currentX * 2 - 1, 0),
                    widthFactor: 0.15,
                    child: Transform.translate(
                      offset: Offset(0, chicken.bobAnimation.value * 3),
                      child: CustomPaint(
                        size: const Size(60, 60),
                        painter: _ChickenPainter(
                          color: chicken.color,
                          peckAngle: chicken.peckAnimation.value,
                          facingRight: chicken.facingRight,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCornKernels() {
    final random = Random(42); // Fixed seed for consistent placement
    return List.generate(12, (index) {
      final x = random.nextDouble() * 0.9 + 0.05;
      final y = random.nextDouble() * 10 + 5;
      return Positioned(
        left: 0,
        right: 0,
        bottom: y,
        child: FractionallySizedBox(
          alignment: Alignment(x * 2 - 1, 0),
          widthFactor: 0.02,
          child: Container(
            width: 6,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFF4D03F),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// Controller for individual chicken animations
class _ChickenController {
  final Color color;
  final bool facingRight;
  double currentX;
  bool _isDisposed = false;

  late final AnimationController _peckController;
  late final Animation<double> peckAnimation;

  late final AnimationController _walkController;
  late final Animation<double> walkAnimation;

  late final AnimationController _bobController;
  late final Animation<double> bobAnimation;

  _ChickenController(
    TickerProvider vsync, {
    required double initialX,
    required this.color,
    required int peckDelay,
    required this.facingRight,
  }) : currentX = initialX {
    // Pecking animation (head bob down and up)
    _peckController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 300),
    );

    peckAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.4).chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.4, end: 0.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
    ]).animate(_peckController);

    // Walking animation (subtle position change)
    _walkController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 2000),
    );

    walkAnimation = Tween<double>(begin: 0, end: 0.05).animate(
      CurvedAnimation(parent: _walkController, curve: Curves.easeInOut),
    );

    // Body bob animation
    _bobController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 600),
    );

    bobAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -2.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -2.0, end: 0.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: _bobController, curve: Curves.easeInOut));

    // Start animations with staggered delays
    Future.delayed(Duration(milliseconds: peckDelay), _startAnimations);
  }

  void _startAnimations() {
    // Peck randomly
    _peckLoop();
    // Bob continuously
    _bobController.repeat();
  }

  void _peckLoop() async {
    while (!_isDisposed) {
      await Future.delayed(Duration(milliseconds: 800 + Random().nextInt(1500)));
      if (_isDisposed) break;
      if (!_peckController.isAnimating) {
        try {
          await _peckController.forward();
          await _peckController.reverse();
          // Sometimes do a double peck
          if (!_isDisposed && Random().nextBool()) {
            await Future.delayed(const Duration(milliseconds: 200));
            if (!_isDisposed) {
              await _peckController.forward();
              await _peckController.reverse();
            }
          }
        } catch (_) {
          // Controller was disposed during animation
          break;
        }
      }
    }
  }

  void dispose() {
    _isDisposed = true;
    _peckController.dispose();
    _walkController.dispose();
    _bobController.dispose();
  }
}

/// Custom painter for drawing a cute chicken
class _ChickenPainter extends CustomPainter {
  final Color color;
  final double peckAngle;
  final bool facingRight;

  _ChickenPainter({
    required this.color,
    required this.peckAngle,
    required this.facingRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Flip canvas if facing left
    if (!facingRight) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    final bodyPaint = Paint()..color = color;
    final beakPaint = Paint()..color = const Color(0xFFE67E22);
    final combPaint = Paint()..color = const Color(0xFFE74C3C);
    final eyePaint = Paint()..color = Colors.black;
    final legPaint = Paint()
      ..color = const Color(0xFFE67E22)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Legs
    canvas.drawLine(
      Offset(centerX - 5, centerY + 15),
      Offset(centerX - 8, centerY + 28),
      legPaint,
    );
    canvas.drawLine(
      Offset(centerX + 5, centerY + 15),
      Offset(centerX + 2, centerY + 28),
      legPaint,
    );
    // Feet
    canvas.drawLine(
      Offset(centerX - 12, centerY + 28),
      Offset(centerX - 4, centerY + 28),
      legPaint,
    );
    canvas.drawLine(
      Offset(centerX - 2, centerY + 28),
      Offset(centerX + 6, centerY + 28),
      legPaint,
    );

    // Body (oval)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY + 5),
        width: 35,
        height: 28,
      ),
      bodyPaint,
    );

    // Wing detail
    final wingPaint = Paint()
      ..color = HSLColor.fromColor(color).withLightness(
        (HSLColor.fromColor(color).lightness - 0.1).clamp(0.0, 1.0),
      ).toColor();
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 3, centerY + 6),
        width: 18,
        height: 14,
      ),
      wingPaint,
    );

    // Tail feathers
    final tailPath = Path()
      ..moveTo(centerX - 15, centerY)
      ..quadraticBezierTo(centerX - 25, centerY - 10, centerX - 20, centerY + 10)
      ..lineTo(centerX - 15, centerY + 5);
    canvas.drawPath(tailPath, bodyPaint);

    // Head (rotates when pecking)
    canvas.save();
    canvas.translate(centerX + 10, centerY - 5);
    canvas.rotate(peckAngle);
    canvas.translate(-(centerX + 10), -(centerY - 5));

    // Head circle
    canvas.drawCircle(
      Offset(centerX + 12, centerY - 8),
      12,
      bodyPaint,
    );

    // Comb (red)
    final combPath = Path()
      ..moveTo(centerX + 8, centerY - 18)
      ..lineTo(centerX + 10, centerY - 22)
      ..lineTo(centerX + 13, centerY - 18)
      ..lineTo(centerX + 15, centerY - 24)
      ..lineTo(centerX + 18, centerY - 18)
      ..close();
    canvas.drawPath(combPath, combPaint);

    // Eye
    canvas.drawCircle(
      Offset(centerX + 16, centerY - 10),
      3,
      eyePaint,
    );
    // Eye highlight
    canvas.drawCircle(
      Offset(centerX + 17, centerY - 11),
      1,
      Paint()..color = Colors.white,
    );

    // Beak
    final beakPath = Path()
      ..moveTo(centerX + 22, centerY - 6)
      ..lineTo(centerX + 30, centerY - 4)
      ..lineTo(centerX + 22, centerY - 2)
      ..close();
    canvas.drawPath(beakPath, beakPaint);

    // Wattle (red hanging part)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 18, centerY),
        width: 5,
        height: 8,
      ),
      combPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ChickenPainter oldDelegate) {
    return oldDelegate.peckAngle != peckAngle;
  }
}

/// Custom painter for the ground
class _GroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Dirt/ground
    final groundPaint = Paint()..color = const Color(0xFF8B7355);
    canvas.drawRect(
      Rect.fromLTWH(0, 10, size.width, size.height - 10),
      groundPaint,
    );

    // Grass tufts
    final grassPaint = Paint()
      ..color = const Color(0xFF4A7C59)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final random = Random(42);
    for (int i = 0; i < 40; i++) {
      final x = random.nextDouble() * size.width;
      final height = random.nextDouble() * 8 + 5;
      final lean = (random.nextDouble() - 0.5) * 0.3;

      canvas.drawLine(
        Offset(x, 12),
        Offset(x + lean * height, 12 - height),
        grassPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
