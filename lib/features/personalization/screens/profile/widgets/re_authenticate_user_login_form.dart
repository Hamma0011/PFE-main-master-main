/*
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/constants/text_strings.dart';
import 'package:caferesto/utils/validators/validation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../controllers/user_controller.dart';
class ReAuthLoginForm extends StatelessWidget {
  const ReAuthLoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = UserController.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Se reconnecter'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          child: Form(
            key: controller.reAuthFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Email
                TextFormField(
                  controller: controller.verifyEmail,
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Iconsax.direct_right),
                      labelText: TTexts.email),
                  validator: TValidator.validateEmail,
                ),
                const SizedBox(height: AppSizes.spaceBtwInputFields),

                /// Password

                Obx(
                  () => TextFormField(
                    obscureText: controller.hidePassword.value,
                    controller: controller.verifyPassword,
                    decoration: InputDecoration(
                        prefixIcon: Icon(Iconsax.password_check),
                        suffixIcon: IconButton(
                            onPressed: () => controller.hidePassword.value =
                                !controller.hidePassword.value,
                            icon: const Icon(Iconsax.eye_slash)),
                        labelText: 'Mot de passe'),
                    validator: (value) =>
                        TValidator.validateEmptyText("Mot de passe", value),
                  ),
                ),
                const SizedBox(height: AppSizes.spaceBtwSections),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        controller.reAuthenticateEmailAndPasswordUser(),
                    child: const Text('Vérifier'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
*/