/*import 'package:caferesto/data/repositories/authentication/authentication_repository.dart';
import 'package:caferesto/features/authentication/controllers/signup/verify_email_controller.dart';
import 'package:caferesto/utils/constants/image_strings.dart';
import 'package:caferesto/utils/constants/text_strings.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/sizes.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key, this.email, required this.password});
  final String? email;
  final String password;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VerifyEmailController());
    controller.setPassword(password);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => AuthenticationRepository.instance.logout(),
            icon: const Icon(CupertinoIcons.clear),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            children: [
              /// Image
              Image(
                image: const AssetImage(TImages.deliveredEmailIllustration),
                width: THelperFunctions.screenWidth() * 0.6,
              ),
              const SizedBox(height: AppSizes.spaceBtwSections),

              /// Title & SubTitle
              Text(
                TTexts.confirmEmail,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),
              Text(
                email ?? "",
                style: Theme.of(context).textTheme.labelLarge,
                textAlign: TextAlign.center,
              ),
              Text(
                TTexts.confirmEmailSubTitle,
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spaceBtwSections),

              /// Button: Vérifier maintenant
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => controller.checkEmailVerificationStatus(),
                  child: const Text(TTexts.continueFr),
                ),
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),

              /// Button: Renvoyer Email
              Obx(() => SizedBox(
                width: double.infinity,
                    child: TextButton(
                      onPressed: controller.canResendEmail.value
                          ? () => controller.sendEmailVerification()
                          : null,
                      child: const Text(TTexts.resendEmail),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
*/
