import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../navigation_menu.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/loaders/animation_loader.dart';

class EmptyCartView extends StatelessWidget {
  const EmptyCartView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(AppSizes.defaultSpace),
        child: EmptyCartContent(),
      ),
    );
  }
}

class EmptyCartContent extends StatelessWidget {
  const EmptyCartContent({super.key});

  @override
  Widget build(BuildContext context) {
    final size = _getAnimationSize(context);
    final textStyle = _getTextStyle(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: size,
              maxWidth: size * 1.2,
            ),
            child: FittedBox(
              fit: BoxFit.contain,
              child: TAnimationLoaderWidget(
                text: "Votre panier est vide !",
                animation: TImages.pencilAnimation,
                showAction: true,
                actionText: 'Explorer les produits',
                textStyle: textStyle, // ✅ Texte agrandi et responsive
                actionTextStyle: textStyle.copyWith(
                  fontSize: textStyle.fontSize! * 0.9,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.w600,
                ),
                onActionPressed: () => Get.off(() => const NavigationMenu()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double _getAnimationSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;
    final longestSide = size.longestSide;

    // 🔹 Taille relative, adaptative et sécurisée
    double computedSize = min(shortestSide * 0.6, longestSide * 0.4);
    return computedSize.clamp(220.0, 380.0);
  }

  static TextStyle _getTextStyle(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 400) {
      return const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    } else if (width < 800) {
      return const TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
    } else {
      return const TextStyle(fontSize: 24, fontWeight: FontWeight.w700);
    }
  }
}
