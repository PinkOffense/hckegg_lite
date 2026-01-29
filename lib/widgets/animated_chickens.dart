import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Widget that displays the 3D chicken model on the login page
class AnimatedChickens extends StatelessWidget {
  const AnimatedChickens({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: ModelViewer(
        src: 'assets/galinha+3d+fofa.glb',
        alt: 'Galinha 3D',
        autoPlay: true,
        autoRotate: true,
        autoRotateDelay: 0,
        rotationPerSecond: '30deg',
        cameraControls: false,
        disableZoom: true,
        disablePan: true,
        disableTap: true,
        backgroundColor: const Color(0xFFFDF2F8), // Light pink background
        cameraOrbit: '0deg 80deg 2m',
        fieldOfView: '35deg',
        interactionPrompt: InteractionPrompt.none,
        loading: Loading.eager,
      ),
    );
  }
}
