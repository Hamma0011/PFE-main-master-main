import 'package:caferesto/common/styles/spacing_styles.dart';
import 'package:caferesto/utils/constants/text_strings.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;

import '../../../utils/constants/sizes.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen(
      {super.key,
      required this.image,
      required this.title,
      required this.subTitle,
      required this.onPressed});

  final String image, title, subTitle;
  final VoidCallback onPressed;

  // Responsive animation size helper
  double _getAnimationSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final shortestSide = math.min(screenWidth, screenHeight);
    
    // For very large screens (PC), limit the size
    if (screenWidth > 1600) {
      return 400.0;
    } else if (screenWidth > 1200) {
      return 350.0;
    } else if (screenWidth > 900) {
      return 300.0;
    } else if (screenWidth > 600) {
      return math.min(shortestSide * 0.6, 280.0);
    } else {
      return math.min(shortestSide * 0.7, 250.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
          child: Padding(
        padding: TSpacingStyle.paddingWithAppBarHeight * 2,
        child: Column(
          children: [
            /// Image with responsive size
            Lottie.asset(
              image,
              width: _getAnimationSize(context),
              fit: BoxFit.contain,
            ),
            const SizedBox(
              height: AppSizes.spaceBtwSections,
            ),

            /// Title and SubTitle
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: AppSizes.spaceBtwItems,
            ),
            Text(
              subTitle,
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: AppSizes.spaceBtwSections,
            ),

            /// Buttons
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: onPressed, child: const Text(TTexts.continueFr)))
          ],
        ),
      )),
    );
  }
}
