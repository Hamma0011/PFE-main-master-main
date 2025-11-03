/*import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../common/widgets/success_screen/success_screen.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../utils/constants/image_strings.dart';

class VerifyEmailController extends GetxController {
  static VerifyEmailController get instance => Get.find();

  final RxBool isEmailVerified = false.obs;
  final RxInt remainingSeconds = 60.obs;
  Timer? _timer;
  final RxBool canResendEmail = true.obs;

  /// Stocker le password utilisé à l'inscription
  late String userPassword;
  @override
  void onInit() {
    super.onInit();
    startVerificationTimer();
  }

  void setPassword(String password) {
    userPassword = password;
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<User?> _getCurrentUser() async {
    try {
      // Essayer de rafraîchir la session
      final res = await Supabase.instance.client.auth.refreshSession();
      return res.user;
    } catch (_) {
      // Si refresh échoue, essayer de se reconnecter automatiquement
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await Supabase.instance.client.auth.signInWithPassword(
            email: user.email!,
            password: userPassword, // Utiliser le mot de passe stocké
          );
          return Supabase.instance.client.auth.currentUser;
        }
      } catch (_) {}
      return null;
    }
  }

  /// Envoyer (ou renvoyer) email de vérification
  Future<void> sendEmailVerification() async {
    if (!canResendEmail.value) {
      Get.snackbar(
        'Patientez',
        'Veuillez attendre avant de renvoyer un autre email.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF57C00),
        colorText: const Color(0xFFFFFFFF),
      );
      return;
    }

    final user = await _getCurrentUser();
    if (user == null) {
      Get.snackbar(
        'Erreur',
        'Aucun utilisateur connecté. Veuillez vous reconnecter.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD32F2F),
        colorText: const Color(0xFFFFFFFF),
      );
      return;
    }

    try {
      final response = await Supabase.instance.client
          .rpc('resend_verification_email', params: {
        'p_email': user.email,
      });

      if (response.error != null) {
        throw response.error!;
      }
      Get.snackbar(
        'Email envoyé',
        'Un email de vérification a été renvoyé.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF388E3C),
        colorText: const Color(0xFFFFFFFF),
      );

      canResendEmail.value = false;
      Timer(const Duration(seconds: 60), () {
        canResendEmail.value = true;
      });
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de renvoyer l\'email : $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD32F2F),
        colorText: const Color(0xFFFFFFFF),
      );
    }
  }

  /// Vérifier la validation de l'email périodiquement
  void startVerificationTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final user = await _getCurrentUser();

      if (user?.emailConfirmedAt != null) {
        isEmailVerified.value = true;
        timer.cancel();
        navigateToSuccessScreen();
      }
    });
  }

  /// Vérification manuelle (bouton)
  Future<void> checkEmailVerificationStatus() async {
    final user = await _getCurrentUser();

    if (user?.emailConfirmedAt != null) {
      navigateToSuccessScreen();
    } else {
      Get.snackbar(
        'Non vérifié',
        'Votre email n\'est pas encore vérifié.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF57C00),
        colorText: const Color(0xFFFFFFFF),
      );
    }
  }

  void navigateToSuccessScreen() {
    Get.offAll(
      () => SuccessScreen(
        image: TImages.successfullyRegisterAnimation,
        title: 'Compte créé avec succès',
        subTitle: 'Votre compte a été vérifié',
        onPressed: () => AuthenticationRepository.instance.screenRedirect(),
      ),
    );
  }
}*/
