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
    // Cache MediaQuery to avoid multiple calls
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final baseTextStyle = textStyle ?? _getResponsiveTextStyle(screenWidth);
    final animationSize = _getAnimationSize(screenWidth);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenWidth * 0.85,
          maxHeight: double.infinity,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animation responsive
            SizedBox(
              width: animationSize,
              height: animationSize,
              child: Lottie.asset(
                animation,
                fit: BoxFit.contain,
                repeat: true,
              ),
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
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            if (showAction && actionText != null) ...[
              const SizedBox(height: AppSizes.defaultSpace),
              SizedBox(
                width: 250,
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
          ],
        ),
      ),
    );
  }

  // Responsive animation size - use screenWidth directly to avoid context issues
  double _getAnimationSize(double screenWidth) {
    if (screenWidth > 1600) {
      return 420.0;
    } else if (screenWidth > 900) {
      return 340.0;
    } else if (screenWidth > 600) {
      return 280.0;
    } else if (screenWidth > 400) {
      return screenWidth * 0.6;
    } else {
      // For very small screens, limit the size
      return screenWidth * 0.7 > 200 ? 200 : screenWidth * 0.7;
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
