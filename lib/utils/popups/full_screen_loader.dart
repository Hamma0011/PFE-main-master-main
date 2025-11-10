import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';
import '../helpers/helper_functions.dart';
import '../loaders/animation_loader.dart';

/// A utility class for managing a full-screen loading dialog.
class TFullScreenLoader {
  /// Open a full-screen loading dialog with a given text and animation.
  /// This method doesn't return anything.
  ///
  /// Parameters:
  ///   - text: The text to be displayed in the loading dialog.
  ///   - animation: The Lottie animation to be shown.
  static void openLoadingDialog(String text, String animation) {
    showDialog(
      context: Get.overlayContext!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDark = THelperFunctions.isDarkMode(context);
        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: isDark ? AppColors.dark : AppColors.white,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.defaultSpace),
                  child: TAnimationLoaderWidget(
                    text: text,
                    animation: animation,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Stop the currently open loading dialog.
  /// This method doesn't return anything.
  static stopLoading() {
    Navigator.of(Get.overlayContext!).pop();
  }
}
