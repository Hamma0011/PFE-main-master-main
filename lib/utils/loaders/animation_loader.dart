import 'package:caferesto/utils/device/device_utility.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';

class TAnimationLoaderWidget extends StatelessWidget {
  const TAnimationLoaderWidget({
    super.key,
    required this.text,
    required this.animation,
    this.showAction = false,
    this.actionText,
    this.onActionPressed,
    this.textStyle,
    this.actionTextStyle,
  });

  final String text;
  final String animation;
  final bool showAction;
  final String? actionText;
  final VoidCallback? onActionPressed;

  /// Optional custom text styles for responsiveness
  final TextStyle? textStyle;
  final TextStyle? actionTextStyle;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseTextStyle = textStyle ?? _getResponsiveTextStyle(screenWidth);

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animation responsive
            Lottie.asset(
              animation,
              width: _getAnimationSize(context),
              fit: BoxFit.contain,
            ),
            const SizedBox(height: AppSizes.spaceBtwSections),

            // Texte lisible et adaptatif
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSizes.defaultSpace),
              child: Text(
                text,
                style: baseTextStyle,
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: AppSizes.defaultSpace),

            // --- Bouton reverted to original implementation ---
            if (showAction && actionText != null)
              SizedBox(
                width: 250, // <-- original fixed width
                child: OutlinedButton(
                  onPressed: onActionPressed,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.dark,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    actionText!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .apply(color: AppColors.light),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Responsive animation size
  double _getAnimationSize(BuildContext context) {
    final screenWidth = TDeviceUtils.getScreenWidth(context);

    if (screenWidth > 1600) {
      return 420.0;
    } else if (screenWidth > 900) {
      return 340.0;
    } else if (screenWidth > 600) {
      return 280.0;
    } else {
      return screenWidth * 0.7;
    }
  }

  // Texte principal adaptatif
  TextStyle _getResponsiveTextStyle(double width) {
    if (width < 400) {
      return const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    } else if (width < 800) {
      return const TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
    } else {
      return const TextStyle(fontSize: 24, fontWeight: FontWeight.w700);
    }
  }
}
