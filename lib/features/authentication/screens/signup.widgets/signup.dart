import 'package:caferesto/common/widgets.login_signup/form_divider.dart';
import 'package:caferesto/common/widgets.login_signup/social_buttons.dart';
import 'package:caferesto/common/widgets/appbar/appbar.dart';
import 'package:caferesto/features/authentication/screens/signup.widgets/widgets/signup_form.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Titre
              Text(
                TTexts.signupTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSizes.spaceBtwSections),

              /// Formulaire
              TSignupform(),
              const SizedBox(height: AppSizes.spaceBtwSections),

              /// Divider
              TFormDivider(dividerText: TTexts.orSignUpWith.capitalize!),
              const SizedBox(height: AppSizes.spaceBtwSections),

              /// Social Buttons
              const TSocialButtons(),
            ],
          ),
        ),
      ),
    );
  }
}
