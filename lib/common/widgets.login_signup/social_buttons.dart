import 'package:caferesto/features/authentication/controllers/login/login_controller.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/constants/image_strings.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TSocialButtons extends StatelessWidget {
  const TSocialButtons({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey),
              borderRadius: BorderRadius.circular(100)),
          child: IconButton(
              onPressed: () => controller.googleSignIn(),
              icon: const Image(
                  width: AppSizes.iconMd,
                  height: AppSizes.iconMd,
                  image: AssetImage(TImages.google))),
        ),
        const SizedBox(
          width: AppSizes.spaceBtwItems,
        ),
        Container(
          decoration: BoxDecoration(
              border: Border.all(color: AppColors.grey),
              borderRadius: BorderRadius.circular(100)),
          child: IconButton(
              onPressed: () {},
              icon: const Image(
                  width: AppSizes.iconMd,
                  height: AppSizes.iconMd,
                  image: AssetImage(TImages.facebook))),
        )
      ],
    );
  }
}
