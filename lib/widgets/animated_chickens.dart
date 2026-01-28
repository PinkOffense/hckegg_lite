import 'dart:math';
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Animated chickens widget that shows 3D chicken models
/// Creates a charming scene for the login page using the GLB asset
class AnimatedChickens extends StatefulWidget {
  const AnimatedChickens({super.key});

  @override
  State<AnimatedChickens> createState() => _AnimatedChickensState();
}

class _AnimatedChickensState extends State<AnimatedChickens>
    with TickerProviderStateMixin {
  late final List<_ChickenData> _chickens;
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Bounce animation for chickens
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Create 3 chickens at different positions
    _chickens = [
      _ChickenData(
        positionX: 0.1,
        scale: 0.8,
        rotationY: -30,
        delay: 0,
      ),
      _ChickenData(
        positionX: 0.5,
        scale: 1.0,
        rotationY: 15,
        delay: 500,
      ),
      _ChickenData(
        positionX: 0.85,
        scale: 0.9,
        rotationY: -45,
        delay: 250,
      ),
    ];
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ground with grass
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomPaint(
              size: const Size(double.infinity, 35),
              painter: _GroundPainter(),
            ),
          ),
          // Corn scattered on ground
          ..._buildCornKernels(),
          // 3D Chickens
          for (int i = 0; i < _chickens.length; i++)
            _buildChicken(_chickens[i], i),
        ],
      ),
    );
  }

  Widget _buildChicken(_ChickenData chicken, int index) {
    return ListenableBuilder(
      listenable: _bounceAnimation,
      builder: (context, child) {
        // Each chicken bounces with a slight delay offset
        final offset = sin((_bounceAnimation.value + index * 2) * pi / 8) * 4;

        return Positioned(
          left: chicken.positionX * MediaQuery.of(context).size.width - 40,
          bottom: 25 + offset,
          width: 80 * chicken.scale,
          height: 100 * chicken.scale,
          child: IgnorePointer(
            child: ModelViewer(
              src: 'assets/galinha+3d+fofa.glb',
              alt: 'Chicken',
              autoPlay: true,
              autoRotate: false,
              cameraControls: false,
              disableZoom: true,
              disablePan: true,
              disableTap: true,
              backgroundColor: Colors.transparent,
              cameraOrbit: '${chicken.rotationY}deg 75deg 2m',
              fieldOfView: '30deg',
              interactionPrompt: InteractionPrompt.none,
              loading: Loading.eager,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildCornKernels() {
    final random = Random(42); // Fixed seed for consistent placement
    return List.generate(15, (index) {
      final x = random.nextDouble() * 0.9 + 0.05;
      final y = random.nextDouble() * 12 + 5;
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

/// Data class for chicken positioning
class _ChickenData {
  final double positionX;
  final double scale;
  final double rotationY;
  final int delay;

  _ChickenData({
    required this.positionX,
    required this.scale,
    required this.rotationY,
    required this.delay,
  });
}

/// Custom painter for the ground
class _GroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Dirt/ground
    final groundPaint = Paint()..color = const Color(0xFF8B7355);
    canvas.drawRect(
      Rect.fromLTWH(0, 12, size.width, size.height - 12),
      groundPaint,
    );

    // Grass tufts
    final grassPaint = Paint()
      ..color = const Color(0xFF4A7C59)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final random = Random(42);
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final height = random.nextDouble() * 10 + 6;
      final lean = (random.nextDouble() - 0.5) * 0.3;

      canvas.drawLine(
        Offset(x, 14),
        Offset(x + lean * height, 14 - height),
        grassPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
