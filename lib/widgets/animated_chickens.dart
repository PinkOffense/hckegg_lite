import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Widget that displays the 3D chicken model on the login page
class AnimatedChickens extends StatelessWidget {
  const AnimatedChickens({super.key});

  @override
  Widget build(BuildContext context) {
    // For web, use the correct asset path
    final modelPath = kIsWeb
        ? 'assets/galinha+3d+fofa.glb'
        : 'assets/galinha+3d+fofa.glb';

    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ModelViewer(
          src: modelPath,
          alt: 'Galinha 3D',
          autoPlay: true,
          autoRotate: true,
          autoRotateDelay: 0,
          rotationPerSecond: '30deg',
          cameraControls: false,
          disableZoom: true,
          disablePan: true,
          disableTap: true,
          backgroundColor: const Color(0xFFFDF2F8),
          cameraOrbit: '0deg 75deg 1.5m',
          fieldOfView: '40deg',
          interactionPrompt: InteractionPrompt.none,
          loading: Loading.eager,
        ),
      ),
    );
  }
}
