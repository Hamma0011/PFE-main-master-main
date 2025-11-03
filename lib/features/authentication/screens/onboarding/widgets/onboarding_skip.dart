import 'package:caferesto/features/authentication/controllers/onboarding/onboarding_controller.dart';
import 'package:flutter/material.dart';

import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/device/device_utility.dart';

class OnBoardingSkip extends StatelessWidget {
  const OnBoardingSkip({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = OnBoardingController.instance;
    return Positioned(
        top: TDeviceUtils.getAppBarHeight(),
        right: AppSizes.defaultSpace,
        child: TextButton.icon(
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: const Text(
            'Passer',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          onPressed: () => controller.skipPage(),
        ));
  }
}
