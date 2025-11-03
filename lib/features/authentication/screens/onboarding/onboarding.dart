import 'package:caferesto/features/authentication/controllers/onboarding/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/animations/depth_transformer.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/text_strings.dart';
import 'widgets/onboarding_dot_navigation.dart';
import 'widgets/onboarding_next_button.dart';
import 'widgets/onboarding_page.dart';
import 'widgets/onboarding_skip.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnBoardingController());
    return Scaffold(
      body: Stack(
        /// Horizontal Scrollable Pages
        children: [
          PageView.custom(
            controller: controller.pageController,
            onPageChanged: controller.updatePageIndicator,
            childrenDelegate: SliverChildBuilderDelegate(
              (context, index) {
                final page = _getPage(index);

                return AnimatedBuilder(
                  animation: controller.pageController,
                  builder: (context, child) {
                    final position =
                        (controller.pageController.page ?? 0) - index;

                    return LiquidPageTransformer().transform(
                        page,
                        TransformInfo(
                          position: position,
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                        ));
                  },
                );
              },
              childCount: 3,
            ),
          ),

          // -- Bouton 'Passer'
          OnBoardingSkip(),

          // -- Navigation par points comme le carousel slider
          OnBoardingDotNavigation(),

          // -- Bouton 'Suivant'
          OnBoardingNextButton(),
        ],
      ),
    );
  }

  Widget _getPage(int index) {
    final pages = [
      const OnBoardingPage(
        image: TImages.onBoardingImage1,
        title: TTexts.onBoardingTitle1,
        subTitle: TTexts.onBoardingSubTitle1,
      ),
      const OnBoardingPage(
        image: TImages.onBoardingImage2,
        title: TTexts.onBoardingTitle2,
        subTitle: TTexts.onBoardingSubTitle2,
      ),
      const OnBoardingPage(
        image: TImages.onBoardingImage3,
        title: TTexts.onBoardingTitle3,
        subTitle: TTexts.onBoardingSubTitle3,
      )
    ];
    return pages[index];
  }
}
