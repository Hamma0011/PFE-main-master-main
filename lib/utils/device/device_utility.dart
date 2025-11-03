import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class TDeviceUtils {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 768 && width < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  static Future<void> setStatusBarColor(Color color) async {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: color),
    );
  }

  static bool isLandscapeOrientation(BuildContext context) {
    final viewInsets = View.of(context).viewInsets;
    return viewInsets.bottom == 0;
  }

  static bool isPortraitOrientation(BuildContext context) {
    final viewInsets = View.of(context).viewInsets;
    return viewInsets.bottom != 0;
  }

  static void setFullScreen(bool enable) {
    SystemChrome.setEnabledSystemUIMode(
        enable ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge);
  }

  static double getScreenHeight() {
    return MediaQuery.of(Get.context!).size.height;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getPixelRatio() {
    return MediaQuery.of(Get.context!).devicePixelRatio;
  }

  static double getStatusBarHeight() {
    return MediaQuery.of(Get.context!).padding.top;
  }

  static double getBottomNavigationBarHeight() {
    return kBottomNavigationBarHeight;
  }

  static double getAppBarHeight() {
    return kToolbarHeight;
  }

  static double getKeyboardHeight() {
    final viewInsets = MediaQuery.of(Get.context!).viewInsets;
    return viewInsets.bottom;
  }

  static Future<bool> isKeyboardVisible() async {
    final viewInsets = View.of(Get.context!).viewInsets;
    return viewInsets.bottom > 0;
  }

  static Future<bool> isPhysicalDevice() async {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static void vibrate(Duration duration) {
    HapticFeedback.vibrate();
    Future.delayed(duration, () => HapticFeedback.vibrate());
  }

  static Future<void> setPreferredOrientations(
      List<DeviceOrientation> orientations) async {
    await SystemChrome.setPreferredOrientations(orientations);
  }

  static void hideStatusBar() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  static void showStatusBar() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
  }

  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static bool isIOS() {
    return Platform.isIOS;
  }

  static bool isAndroid() {
    return Platform.isAndroid;
  }

  static void launchUrl(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  static DeviceType getDeviceType(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      return DeviceType.mobile;
    } else if (screenWidth >= 600 && screenWidth <= 1024) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Détermine le nombre de colonnes selon la largeur de l'écran
  static int getCrossAxisCount(double screenWidth) {
    if (screenWidth < 480) {
      return 2; // Mobile petit
    } else if (screenWidth < 768) {
      return 3; // Mobile large / tablette petite
    } else if (screenWidth < 1024) {
      return 4; // Tablette
    } else if (screenWidth < 1440) {
      return 5; // PC moyen
    } else {
      return 6; // PC large
    }
  }

  /// Détermine la hauteur des éléments selon la largeur de l'écran
  static double getMainAxisExtent(double screenWidth) {
    if (screenWidth < 480) {
      return 320; // Mobile petit
    } else if (screenWidth < 768) {
      return 340; // Mobile large / tablette petite
    } else if (screenWidth < 1024) {
      return 340; // Tablette
    } else if (screenWidth < 1440) {
      return 340; // PC moyen
    } else {
      return 360; // PC large
    }
  }

  /// Détermine la hauteur du PromoSlider avec taille maximale
  static double getPromoSliderHeight(double screenWidth, double screenHeight) {
    double baseHeight;

    if (screenWidth < 480) {
      baseHeight = screenHeight * 0.20; // 20% de la hauteur sur mobile
    } else if (screenWidth < 768) {
      baseHeight = screenHeight * 0.25; // 25% sur tablette petite
    } else if (screenWidth < 1024) {
      baseHeight = screenHeight * 0.30; // 30% sur tablette
    } else {
      baseHeight = screenHeight * 0.35; // 35% sur PC
    }

    // Taille maximale à ne pas dépasser
    const double maxHeight = 400.0;
    return baseHeight > maxHeight ? maxHeight : baseHeight;
  }

  /// Détermine le padding horizontal selon la largeur de l'écran
  static double getHorizontalPadding(double screenWidth) {
    if (screenWidth < 480) {
      return 16.0; // Mobile petit
    } else if (screenWidth < 768) {
      return 20.0; // Mobile large
    } else if (screenWidth < 1024) {
      return 32.0; // Tablette
    } else if (screenWidth < 1440) {
      return 48.0; // PC moyen
    } else {
      return 64.0; // PC large
    }
  }

// Add more device utility methods as per your specific requirements.
}

enum DeviceType {
  mobile,
  tablet,
  desktop,
}
