import 'package:caferesto/features/authentication/screens/signup.widgets/widgets/terms_condtions_checkbox.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:caferesto/features/authentication/controllers/signup/signup_controller.dart';

import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../../utils/validators/validation.dart';

enum UserRole {
  Client('Client', 'Client'),
  Gerant('Gérant', 'Gérant');

  final String dbValue;
  final String label;
  const UserRole(this.dbValue, this.label);

  static UserRole? fromDb(String? value) {
    if (value == null) return null;
    return UserRole.values.firstWhere(
      (role) => role.dbValue == value,
      orElse: () => UserRole.Client,
    );
  }
}

enum UserGender {
  Homme('Homme', 'Homme'),
  Femme('Femme', 'Femme');

  final String dbValue;
  final String label;
  const UserGender(this.dbValue, this.label);

  static UserGender? fromDb(String? value) {
    if (value == null) return null;
    return UserGender.values.firstWhere(
      (role) => role.dbValue == value,
      orElse: () => UserGender.Homme,
    );
  }
}

class TSignupform extends StatelessWidget {
  const TSignupform({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = SignupController.instance;
    return Form(
      key: controller.signupFormKey,
      child: Column(
        children: [
          /// Prénom & Nom
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller.firstName,
                  validator: (value) =>
                      TValidator.validateEmptyText('First name', value),
                  decoration: const InputDecoration(
                    labelText: TTexts.firstName,
                    prefixIcon: Icon(Iconsax.user),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spaceBtwInputFields),
              Expanded(
                child: TextFormField(
                  controller: controller.lastName,
                  validator: (value) =>
                      TValidator.validateEmptyText('Last name', value),
                  decoration: const InputDecoration(
                    labelText: TTexts.lastName,
                    prefixIcon: Icon(Iconsax.user),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceBtwInputFields),

          /// Nom d'utilisateur
          TextFormField(
            controller: controller.username,
            validator: (value) =>
                TValidator.validateEmptyText('Username', value),
            decoration: const InputDecoration(
              labelText: TTexts.username,
              prefixIcon: Icon(Iconsax.user_edit),
            ),
          ),
          const SizedBox(height: AppSizes.spaceBtwInputFields),

          /// Email
          TextFormField(
            controller: controller.email,
            validator: (value) => TValidator.validateEmail(value),
            decoration: const InputDecoration(
              labelText: TTexts.email,
              prefixIcon: Icon(Iconsax.direct),
            ),
          ),
          const SizedBox(height: AppSizes.spaceBtwInputFields),

          /// Numéro de téléphone
          TextFormField(
            controller: controller.phoneNumber,
            validator: (value) => TValidator.validatePhoneNumber(value),
            decoration: const InputDecoration(
              labelText: TTexts.phoneNo,
              prefixIcon: Icon(Iconsax.call),
            ),
          ),
          const SizedBox(height: AppSizes.spaceBtwInputFields),

          /// Sélection du Rôle
          Obx(
            () => DropdownButtonFormField<UserRole>(
              value: controller.selectedRole.value,
              decoration: const InputDecoration(
                labelText: 'Rôle',
                prefixIcon: Icon(Iconsax.user_octagon),
              ),
              items: UserRole.values
                  .map(
                    (role) => DropdownMenuItem(
                      value: role,
                      child: Text(role.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.selectedRole.value = value;
                }
              },
              validator: (value) {
                if (value == null) {
                  return 'Veuillez sélectionner un rôle';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: AppSizes.spaceBtwInputFields),

          /// Sélection du Sexe
          Obx(
            () => DropdownButtonFormField<UserGender>(
              value: controller.selectedGender.value,
              decoration: const InputDecoration(
                labelText: 'Sexe',
                prefixIcon: Icon(Iconsax.user_octagon),
              ),
              items: UserGender.values
                  .map(
                    (sex) => DropdownMenuItem(
                      value: sex,
                      child: Text(sex.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.selectedGender.value = value;
                }
              },
              validator: (value) {
                if (value == null) {
                  return 'Veuillez sélectionner un sexe';
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: AppSizes.spaceBtwSections),

          /// Case à cocher Conditions d'utilisation
          const TermsAndConditionsCheckbox(),
          const SizedBox(height: AppSizes.spaceBtwInputFields),

          /// Bouton
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => controller.signup(),
              child: const Text(TTexts.createAccount),
            ),
          ),
        ],
      ),
    );
  }
}
