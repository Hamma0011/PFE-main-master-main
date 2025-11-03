import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'data/repositories/authentication/authentication_repository.dart';
import 'data/repositories/user/user_repository.dart';

Future<void> main() async {
  // Assurer l'initialisation du binding des widgets Flutter
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();

  // Conserver l'écran splash natif jusqu'à la fin de l'initialisation
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialiser GetStorage (stockage local pour GetX)
  await GetStorage.init();

  // Charger les variables d'environnement depuis le fichier .env
  await dotenv.load(fileName: "assets/config/.env");

  // Initialiser le client Supabase avec l'URL et la clé anonyme provenant de l'env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  // Injecter votre repository d'authentification (à remplacer par votre implémentation)
  Get.put(AuthenticationRepository());

  // Utiliser la stratégie d'URL basée sur le chemin pour Flutter web (optionnel)
  usePathUrlStrategy();

  // Lancer le widget principal de l'application
  runApp(App());
}
