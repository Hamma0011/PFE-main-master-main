import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../login/login.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/image_strings.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  _checkAndNavigate() async {
    // Attendre 3 secondes pour afficher le splash screen
    await Future.delayed(const Duration(seconds: 3));

    // Vérifier si l'utilisateur est connecté
    // Si screenRedirect() a déjà redirigé, cette redirection ne sera pas exécutée
    // Si l'utilisateur n'est pas connecté, rediriger vers login
    if (mounted) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        // Si aucun utilisateur connecté, rediriger vers login
        Get.offAll(() => const LoginScreen());
      }
      // Si l'utilisateur est connecté, screenRedirect() a déjà géré la redirection
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de l'application
            Image(
              height: 200,
              image: AssetImage(TImages.lightAppLogo),
            ),
            const SizedBox(height: 24),
            // Indicateur de chargement
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
