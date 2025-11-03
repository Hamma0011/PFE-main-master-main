/*import 'package:caferesto/utils/constants/text_strings.dart';
import 'package:caferesto/utils/validators/validation.dart';
import 'package:flutter/material.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:get/get.dart';

import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../controllers/forget_password/forget_password_controller.dart';

class ForgetPassword extends StatelessWidget {
  const ForgetPassword({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ForgetPasswordController());
    return Scaffold(
      appBar: TAppBar(
        showBackArrow: true,
        title: const Text("Mot de passe oublié"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          /// Headings
          children: [
            Text(
              TTexts.forgetPassword,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSizes.spaceBtwItems),
            Text(
              TTexts.forgetPasswordSubTitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSizes.spaceBtwItems * 2),

            /// Champ Email
            Form(
              key: controller.forgetPasswordFormKey,
              child: TextFormField(
                controller: controller.email,
                validator: TValidator.validateEmail,
                decoration: const InputDecoration(
                  labelText: TTexts.email,
                  prefixIcon: Icon(Iconsax.direct_right),
                ),
              ),
            ),

            const SizedBox(height: AppSizes.spaceBtwSections),

            /// Bouton subbmit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => controller.sendPasswordResetEmail(),
                child: const Text(TTexts.submit),
              ),
            )
          ],
        ),
      ),
    );
  }
}
*/