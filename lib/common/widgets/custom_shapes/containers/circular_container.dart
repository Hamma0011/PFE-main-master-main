import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../utils/constants/colors.dart';

class TCircularContainer extends StatelessWidget {
  const TCircularContainer({
    super.key,
    this.child,
    this.width = 400,
    this.height = 400,
    this.radius = 400,
    this.padding = 0,
    this.backgroundColor = AppColors.white,
    this.margin,
    this.blurSigma = 15,
    this.borderWidth = 1.5,
    this.borderOpacity = 0.2,
    this.backgroundOpacity = 0.15,
  });
  final double? width;
  final double? height;
  final double radius;
  final double padding;
  final Widget? child;
  final Color? backgroundColor;
  final EdgeInsets? margin;
  final double blurSigma;

  final double backgroundOpacity;

  final double borderOpacity;

  final double borderWidth;
  @override
  Widget build(BuildContext context) {
    final cirularClip = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          margin: margin,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: Colors.white.withAlpha((255 * backgroundOpacity).toInt()),
              border: Border.all(
                color: Colors.white.withAlpha((255 * borderOpacity).toInt()),
                width: borderWidth,
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.white.withAlpha((255 * 0.05).toInt()),
                    blurRadius: 20,
                    offset: const Offset(0, 4))
              ]),
          child: child,
        ),
      ),
    );

    return cirularClip;
  }
}
