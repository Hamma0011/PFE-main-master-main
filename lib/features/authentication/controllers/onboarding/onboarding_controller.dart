import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../screens/login/login.dart';

class OnBoardingController extends GetxController {
  static OnBoardingController get instance => Get.find();

  /// Variables
  final pageController = PageController();
  Rx<int> currentPageIndex = 0.obs;

  /// Mettre a jour index en cas de swipe par doigt
  void updatePageIndicator(index) => currentPageIndex.value = index;

  /// Passer à la page spécifié par points
  void dotNavigationClick(index) {
    currentPageIndex.value = index;
    pageController.jumpToPage(index);
  }

  /// Mettre a jour index et passer à la page suivante
  void nextPage() {
    if (currentPageIndex.value < 2) {
      final nextPage = currentPageIndex.value + 1;
      currentPageIndex.value = nextPage;
      pageController.jumpToPage(nextPage);
      print(nextPage);
    } else {
      Get.to(() => const LoginScreen());
    }
  }

  /// Mettre a jour index et passer à page de connexio
  void skipPage() {
    Get.to(() => const LoginScreen());
  }
}
