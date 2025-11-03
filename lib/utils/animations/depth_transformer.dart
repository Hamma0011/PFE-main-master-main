import 'package:flutter/material.dart';

/// swipe liquide
class LiquidPageTransformer extends PageTransformer {
  final double minScale;
  final double waveStrength;

  LiquidPageTransformer({
    this.minScale = 0.85,
    this.waveStrength = 30.0,
  });

  @override
  Widget transform(Widget child, TransformInfo info) {
    final position = info.position;

    // diminuer la taille en swipant
    final scale = (1 - position.abs() * 0.15).clamp(minScale, 1.0);

    // curved wave clipping for liquid effect
    return ClipPath(
      clipper: _LiquidWaveClipper(position, waveStrength),
      child: Transform.scale(
        scale: scale,
        child: child,
      ),
    );
  }
}

/// Custom wave clipper for liquid transition
class _LiquidWaveClipper extends CustomClipper<Path> {
  final double position;
  final double strength;

  _LiquidWaveClipper(this.position, this.strength);

  @override
  Path getClip(Size size) {
    final path = Path();

    if (position == 0) {
      // fully visible, normal rectangle
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      return path;
    }

    final waveCenterY = size.height / 2;
    final curveOffset = strength * position.sign;

    path.moveTo(0, 0);
    path.lineTo(size.width * (1 - position.abs()), 0);

    // Liquid wave curve
    path.quadraticBezierTo(
      size.width * (1 - position.abs()) + curveOffset,
      waveCenterY,
      size.width * (1 - position.abs()),
      size.height,
    );

    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant _LiquidWaveClipper oldClipper) {
    return oldClipper.position != position;
  }
}

/// Base transformer contract
abstract class PageTransformer {
  Widget transform(Widget child, TransformInfo info);
}

class TransformInfo {
  final double position;
  final double width;
  final double height;

  TransformInfo({
    required this.position,
    required this.width,
    required this.height,
  });
}
