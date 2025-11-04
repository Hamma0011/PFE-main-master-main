import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/popups/loaders.dart';
import '../models/user_model.dart';
import 'package:image_picker/image_picker.dart';

class UserController extends GetxController {
  static UserController get instance {
    try {
      return Get.find<UserController>();
    } catch (e) {
      // If not found, create it (shouldn't happen with proper binding)
      return Get.put(UserController(), permanent: true);
    }
  }
  String get userRole => user.value.role;
  String? get currentEtablissementId => user.value.establishmentId;
  bool get hasEtablissement => user.value.establishmentId != null && user.value.establishmentId!.isNotEmpty;

  final profileLoading = false.obs;
  Rx<UserModel> user = UserModel.empty().obs;

  final userRepository = Get.find<UserRepository>();

  final hidePassword = false.obs;
  final verifyEmail = TextEditingController();
  GlobalKey<FormState> reAuthFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    
    // Charger l'utilisateur immédiatement si une session existe déjà
    final currentSession = Supabase.instance.client.auth.currentSession;
    if (currentSession != null) {
      fetchUserRecord();
    }
    
    // Listener sur l'état de connexion Supabase pour les changements futurs
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        fetchUserRecord();
      } else {
        user(UserModel.empty());
        debugPrint("Utilisateur déconnecté");
      }
    });
  }

  /// Charger les infos utilisateur
  Future<void> fetchUserRecord() async {
    try {
      profileLoading.value = true;
      final userData = await userRepository.fetchUserDetails();
      
      if (userData != null) {
        // Ne mettre à jour que si on a réussi à récupérer les données
        this.user(userData);
      } else {
        // Si l'utilisateur n'existe pas en base, ne pas écraser avec un utilisateur vide
        // Garder l'utilisateur actuel si disponible
        debugPrint("Aucune donnée utilisateur trouvée en base de données");
      }
    } catch (e) {
      // Ne pas écraser l'utilisateur existant en cas d'erreur
      // Garder l'utilisateur actuel si disponible
      debugPrint("Erreur lors du chargement de l'utilisateur: $e");
      
      // Seulement afficher un message si l'utilisateur n'était pas déjà chargé
      if (this.user.value.id.isEmpty) {
        debugPrint('Impossible de récupérer les données utilisateur');
      }
    } finally {
      profileLoading.value = false;
    }
  }

  /// Enregistrer les donnnées utilisateur
  Future<void> saveUserRecord(User? supabaseUser) async {
    try {
      if (supabaseUser != null) {
        // Convertir Name en First and Last Name
        final displayName = supabaseUser.userMetadata?['full_name'] ?? '';
        final nameParts = UserModel.nameParts(displayName);
        final username = UserModel.generateUsername(displayName);
        // Map data
        final user = UserModel(
          id: supabaseUser.id,
          email: supabaseUser.email ?? '',
          firstName: nameParts.isNotEmpty ? nameParts[0] : '',
          lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
          username: username,
          phone: supabaseUser.phone ?? '',
          role: 'Client',
          orderIds: [],
          profileImageUrl:
              supabaseUser.userMetadata?['profile_image_url'] ?? '',
        );
        // Sauvegarde (dans Supabase table "users")
        await userRepository.saveUserRecord(user);
      }
    } catch (e) {
      TLoaders.warningSnackBar(
        title: 'Donnés non enregistrés',
        message:
            "Quelque chose s'est mal passé en enregistrant vos informations. Vous pouver réenregistrer vos données dans votre profil.",
      );
    }
  }

  Future<void> updateProfileImage(XFile pickedFile) async {
    try {
      final userId = user.value.id;

      // Upload sur Supabase Storage
      final path =
          'profile_images/$userId-${DateTime.now().millisecondsSinceEpoch}.png';
      final bytes = await pickedFile.readAsBytes();

      await Supabase.instance.client.storage
          .from('profile_images')
          .uploadBinary(path, bytes,
              fileOptions: const FileOptions(contentType: 'image/png'));

      // Récupérer l’URL publique
      final publicUrl = Supabase.instance.client.storage
          .from('profile_images')
          .getPublicUrl(path);

      debugPrint("Image uploaded. Public URL: $publicUrl");

      // Mettre à jour la table users
      await Supabase.instance.client
          .from('users')
          .update({'profile_image_url': publicUrl}).eq('id', userId);

      // Mettre à jour le contrôleur local
      user.update((val) {
        val?.profileImageUrl = publicUrl;
      });

      TLoaders.successSnackBar(message: 'Photo de profil mise à jour !');
    } catch (e) {
      debugPrint("Erreur updateProfileImage: $e");
      TLoaders.warningSnackBar(title: 'Erreur', message: e.toString());
    }
  }

  /// Récupérer le nom complet d'un utilisateur à partir de son ID
  /// Retourne "Prénom Nom" ou null si l'utilisateur n'est pas trouvé
  Future<String?> getUserFullName(String userId) async {
    try {
      if (userId.isEmpty) return null;
      
      final userData = await userRepository.fetchUserDetails(userId);
      if (userData != null) {
        return userData.fullName;
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du nom utilisateur: $e');
      return null;
    }
  }
}
