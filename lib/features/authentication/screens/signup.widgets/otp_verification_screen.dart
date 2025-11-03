import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:caferesto/utils/device/device_utility.dart';

import '../../controllers/signup/verify_otp_controller.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/sizes.dart';

class OTPVerificationScreen extends StatelessWidget {
  final String email;
  final Map<String, dynamic> userData;
  final bool isSignupFlow;

  const OTPVerificationScreen({
    super.key,
    required this.email,
    required this.userData,
    this.isSignupFlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OTPVerificationController());
    controller.emailController.text = email;
    controller.initializeFlow(isSignupFlow, userData);
    controller.startTimer();

    return Scaffold(
      appBar: TAppBar(
        title: Text(isSignupFlow
            ? 'Vérification Inscription'
            : 'Vérification Connexion'),
      ),
      body: Center(
        child: _buildAdaptiveLayout(context, controller),
      ),
    );
  }

  Widget _buildAdaptiveLayout(
      BuildContext context, OTPVerificationController controller) {
    final deviceType = TDeviceUtils.getDeviceType(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 🌗 Couleurs adaptatives
    final Color backgroundTop =
        isDark ? const Color(0xFF121212) : const Color(0xFFF3F4F6);
    final Color backgroundBottom =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE5E7EB);
    final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color shadowColor =
        isDark ? Colors.black.withOpacity(0.6) : Colors.black.withOpacity(0.15);

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isSignupFlow ? 'Finalisez votre inscription' : 'Connectez-vous',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        Text(
          'Entrez le code reçu à l\'adresse $email',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        /// CHAMP OTP UNIQUE
        SizedBox(
          width: 200,
          child: TextField(
            controller: controller.singleOtpController,
            maxLength: 6,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              counterText: "",
              hintText: '000000',
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                letterSpacing: 2,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            // EMPÊCHER LA SAISIE DE CARACTÈRES NON NUMÉRIQUES
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            // VALIDER EN TEMPS RÉEL
            onChanged: (value) {
              controller.validateOTPInput(value);
            },
          ),
        ),
        const SizedBox(height: 8),

        // INDICATEUR DE VALIDATION
        Obx(() {
          final length = controller.otpInput.value.length;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              final isFilled = index < length;
              final isValid = controller.isOtpValid.value;

              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled
                      ? (isValid ? Colors.green : Colors.orange)
                      : Colors.grey.shade400,
                ),
              );
            }),
          );
        }),

        const SizedBox(height: 30),

        /// BOUTON VÉRIFICATION AVEC VALIDATION
        Obx(
          () => SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  controller.isOtpValid.value && !controller.isLoading.value
                      ? () => controller.verifyOTP()
                      : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isSignupFlow ? 'Créer le compte' : 'Se connecter',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        /// Resend OTP Section
        Obx(
          () => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Vous n'avez pas reçu le code ?"),
              TextButton(
                onPressed: controller.isResendAvailable.value
                    ? () => controller.resendOTP()
                    : null,
                child: Text(
                  controller.isResendAvailable.value
                      ? 'Renvoyer'
                      : 'Renvoyer (${controller.secondsRemaining.value}s)',
                ),
              ),
            ],
          ),
        ),
      ],
    );

    // Layouts adaptatifs selon le device
    switch (deviceType) {
      case DeviceType.mobile:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          child: content,
        );

      case DeviceType.tablet:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [backgroundTop, backgroundBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.defaultSpace * 2),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Card(
                  color: cardColor,
                  elevation: 12,
                  shadowColor: shadowColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.defaultSpace * 2),
                    child: content,
                  ),
                ),
              ),
            ),
          ),
        );

      case DeviceType.desktop:
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [backgroundTop, backgroundBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              vertical: AppSizes.defaultSpace * 2,
              horizontal: AppSizes.defaultSpace * 3,
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
        );
    }
  }
}
