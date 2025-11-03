import 'package:caferesto/utils/device/device_utility.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/styles/spacing_styles.dart';
import '../../../../common/widgets.login_signup/form_divider.dart';
import '../../../../common/widgets.login_signup/social_buttons.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/constants/text_strings.dart';
import 'widgets/login_form.dart';
import 'widgets/login_header.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _buildAdaptiveLayout(context),
      ),
    );
  }

  Widget _buildAdaptiveLayout(BuildContext context) {
    final deviceType = TDeviceUtils.getDeviceType(context);
    final theme = Theme.of(context);
    final isDark = THelperFunctions.isDarkMode(context);

    // Contenu commun
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TLoginHeader(),
        const TLoginForm(),
        TFormDivider(dividerText: TTexts.orSignInWith.capitalize!),
        const SizedBox(height: AppSizes.spaceBtwSections),
        const TSocialButtons(),
      ],
    );

    switch (deviceType) {
      case DeviceType.mobile:
        return _buildMobileLayout(content);

      case DeviceType.tablet:
        return _buildTabletLayout(content);

      case DeviceType.desktop:
        return _buildDesktopLayout(content, context, isDark, theme);
    }
  }

  Widget _buildMobileLayout(Widget content) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: TSpacingStyle.paddingWithAppBarHeight,
        child: content,
      ),
    );
  }

  Widget _buildTabletLayout(Widget content) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.defaultSpace * 2),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
      Widget content, BuildContext context, bool isDark, ThemeData theme) {
    final Color backgroundTop =
        isDark ? const Color(0xFF121212) : const Color(0xFFF3F4F6);
    final Color backgroundBottom =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5E7EB);

    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color shadowColor =
        isDark ? Colors.black.withOpacity(0.6) : Colors.black.withOpacity(0.15);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [backgroundTop, backgroundBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.defaultSpace * 2,
            horizontal: AppSizes.defaultSpace * 3,
          ),
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Center(
            child: Card(
              color: cardColor,
              elevation: 20,
              shadowColor: shadowColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.defaultSpace * 2),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 480,
                    minWidth: 420,
                  ),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
