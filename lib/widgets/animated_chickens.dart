import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Widget that displays the 3D chicken model on the login page
class AnimatedChickens extends StatelessWidget {
  const AnimatedChickens({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Center(
        child: SizedBox(
          width: 200,
          height: 150,
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
            backgroundColor: Colors.transparent,
            cameraOrbit: '0deg 75deg 2.5m',
            fieldOfView: '30deg',
            interactionPrompt: InteractionPrompt.none,
            loading: Loading.eager,
          ),
        ),
      ),
    );
  }
}
