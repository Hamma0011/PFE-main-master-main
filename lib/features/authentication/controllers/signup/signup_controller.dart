import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/helpers/network_manager.dart';
import '../../../../utils/popups/full_screen_loader.dart';
import '../../../../utils/popups/loaders.dart';
import '../../screens/signup.widgets/otp_verification_screen.dart';
import '../../screens/signup.widgets/widgets/signup_form.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();

  final privacyPolicy = true.obs;
  final email = TextEditingController();
  final lastName = TextEditingController();
  final firstName = TextEditingController();
  final username = TextEditingController();
  final phoneNumber = TextEditingController();
  final Rx<UserRole> selectedRole = UserRole.Client.obs;
  final Rx<UserGender> selectedGender = UserGender.Homme.obs;

  GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  bool _isProcessing = false;

  final RxMap<String, dynamic> _userData = <String, dynamic>{}.obs;

  Map<String, dynamic> get userData => _userData;

  /// -- SIGNUP
  void signup() async {
    if (_isProcessing) return;
    _isProcessing = true;
    TFullScreenLoader.openLoadingDialog(
      "Nous sommes en train de traiter vos informations...",
      TImages.docerAnimation,
    );

    try {
      TFullScreenLoader.openLoadingDialog(
        "Création du compte...",
        TImages.docerAnimation,
      );
      // Check internet connection
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        TLoaders.warningSnackBar(
          title: 'Pas de connexion',
          message: 'Veuillez vérifier votre connexion internet.',
        );
        return;
      }

      // Valider formulaire
      if (!signupFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // vérfier privacy policy
      if (!privacyPolicy.value) {
        TFullScreenLoader.stopLoading();
        TLoaders.warningSnackBar(
          title: 'Politique de confidentialité',
          message: 'Veuillez accepter la politique de confidentialité.',
        );
        return;
      }

      // Enregistrer les donnés utilisateurs dans la table Supabase
      final userData = {
        'first_name': firstName.text.trim(),
        'last_name': lastName.text.trim(),
        'username': username.text.trim(),
        'phone': phoneNumber.text.trim(),
        'sex': selectedGender.value.dbValue,
        'role': selectedRole.value.dbValue,
        'profile_image_url': '',
      };

      // Send OTP to email
      await AuthenticationRepository.instance.signUpWithEmailOTP(
        email.text.trim(),
        userData,
      );

      TFullScreenLoader.stopLoading();
      TLoaders.successSnackBar(
        title: "OTP envoyé!",
        message: "Un code de vérification a été envoyé à votre adresse email.",
      );

      // Naviger vers OTP verification screen
      Get.off(() => OTPVerificationScreen(
            email: email.text.trim(),
            userData: userData,
            isSignupFlow :true,
          ));
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(
        title: 'Erreur',
        message: e.toString(),
      );
    } finally {
      _isProcessing = false;
    }
  }
}
