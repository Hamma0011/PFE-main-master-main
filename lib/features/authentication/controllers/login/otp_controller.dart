/*import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/helpers/network_manager.dart';
import '../../../../utils/popups/full_screen_loader.dart';
import '../../../../utils/popups/loaders.dart';

class OtpController extends GetxController {
  final otpCode = TextEditingController();

  /// Vérifier OTP
  void verifyOtp(String email) async {
    try {
      TFullScreenLoader.openLoadingDialog(
        "Vérification du code...",
        TImages.docerAnimation,
      );

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      await AuthenticationRepository.instance.verifyOtp(
        email: email,
        otp: otpCode.text.trim(),
      );

      TFullScreenLoader.stopLoading();

      // Redirige vers la bonne page après connexion
      AuthenticationRepository.instance.screenRedirect();

    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: 'Erreur !', message: e.toString());
    }
  }
}
*/
