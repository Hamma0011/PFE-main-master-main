import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../features/authentication/screens/login/login.dart';
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
  bool get hasEtablissement =>
      user.value.establishmentId != null &&
      user.value.establishmentId!.isNotEmpty;

  final profileLoading = false.obs;
  Rx<UserModel> user = UserModel.empty().obs;

  // Lazy access to UserRepository to avoid initialization issues
  UserRepository get userRepository {
    try {
      return Get.find<UserRepository>();
    } catch (e) {
      // If UserRepository is not found, initialize it
      return Get.put(UserRepository(), permanent: true);
    }
  }
  
  RealtimeChannel? _userBanChannel;

  final hidePassword = false.obs;
  final verifyEmail = TextEditingController();
  GlobalKey<FormState> reAuthFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();

    // Charger l'utilisateur immédiatement si une session existe déjà
    final currentSession = Supabase.instance.client.auth.currentSession;
    if (currentSession != null) {
      // Charger les données de manière synchrone au démarrage
      _loadUserDataSync();
      // Démarrer l'écoute Realtime pour les bannissements
      _subscribeToUserBanRealtime();
    }

    // Listener sur l'état de connexion Supabase pour les changements futurs
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        fetchUserRecord();
        // Démarrer l'écoute Realtime quand l'utilisateur se connecte
        _subscribeToUserBanRealtime();
      } else {
        user(UserModel.empty());
        // Arrêter l'écoute Realtime quand l'utilisateur se déconnecte
        _unsubscribeFromUserBanRealtime();
        debugPrint("Utilisateur déconnecté");
      }
    });
  }

  @override
  void onClose() {
    _unsubscribeFromUserBanRealtime();
    super.onClose();
  }

  /// Charger les données utilisateur de manière synchrone au démarrage
  void _loadUserDataSync() {
    // Ne pas initialiser avec empty() si on a une session
    // Attendre que fetchUserRecord() charge les vraies données
    fetchUserRecord();
  }

  /// Charger les infos utilisateur
  Future<void> fetchUserRecord() async {
    try {
      profileLoading.value = true;
      final userData = await userRepository.fetchUserDetails();

      if (userData != null) {
        // Vérifier si l'utilisateur est banni avant de mettre à jour
        if (userData.isBanned) {
          debugPrint(" Utilisateur banni détecté - Déconnexion immédiate");
          await _handleUserBan();
          return;
        }

        // Mettre à jour avec les données de la base de données
        user(userData);
        debugPrint(
            "✅ Utilisateur chargé depuis la base de données - Rôle: ${userData.role}");
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
      if (user.value.id.isEmpty) {
        debugPrint('Impossible de récupérer les données utilisateur');
      }
    } finally {
      profileLoading.value = false;
    }
  }

  /// S'abonner aux changements Realtime sur la table users pour détecter les bannissements
  void _subscribeToUserBanRealtime() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId.isEmpty) {
      debugPrint("Aucun utilisateur connecté - Pas d'écoute Realtime");
      return;
    }

    try {
      // Se désabonner de l'ancien canal s'il existe
      _unsubscribeFromUserBanRealtime();

      // Créer un nouveau canal pour écouter les changements sur l'utilisateur actuel
      _userBanChannel = Supabase.instance.client
          .channel('user_ban_${currentUserId}')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'users',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: currentUserId,
            ),
            callback: (payload) async {
              debugPrint(
                  "🔄 Changement détecté sur l'utilisateur via Realtime");
              final updatedData = payload.newRecord;

              // Vérifier si l'utilisateur a été banni
              final isBanned = updatedData['is_banned'] as bool? ?? false;

              if (isBanned) {
                debugPrint(
                    " Bannissement détecté via Realtime - Déconnexion immédiate");
                await _handleUserBan();
              } else {
                // Mettre à jour les données utilisateur si d'autres champs ont changé
                try {
                  final userData =
                      await userRepository.fetchUserDetails(currentUserId);
                  if (userData != null && !userData.isBanned) {
                    user(userData);
                  }
                } catch (e) {
                  debugPrint(
                      "Erreur lors de la mise à jour des données utilisateur: $e");
                }
              }
            },
          )
          .subscribe((status, [error]) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          debugPrint("Abonné aux changements Realtime pour l'utilisateur");
        } else if (status == RealtimeSubscribeStatus.channelError) {
          debugPrint(" Erreur d'abonnement Realtime: $error");
        }
      });
    } catch (e) {
      debugPrint("Erreur lors de l'abonnement Realtime: $e");
    }
  }

  /// Se désabonner de l'écoute Realtime
  void _unsubscribeFromUserBanRealtime() {
    if (_userBanChannel != null) {
      try {
        Supabase.instance.client.removeChannel(_userBanChannel!);
        _userBanChannel = null;
        debugPrint("✅ Désabonné de l'écoute Realtime");
      } catch (e) {
        debugPrint("Erreur lors de la désinscription Realtime: $e");
      }
    }
  }

  /// Gérer la déconnexion d'un utilisateur banni
  Future<void> _handleUserBan() async {
    try {
      // Arrêter l'écoute Realtime
      _unsubscribeFromUserBanRealtime();

      // Afficher un message à l'utilisateur
      TLoaders.errorSnackBar(
        title: 'Accès refusé',
        message: "Votre compte a été banni. Vous allez être déconnecté.",
      );

      // Attendre un peu pour que l'utilisateur voie le message
      await Future.delayed(const Duration(milliseconds: 1500));

      // Déconnecter l'utilisateur
      await AuthenticationRepository.instance.logout();
    } catch (e) {
      debugPrint("Erreur lors de la gestion du bannissement: $e");
      // Forcer la déconnexion même en cas d'erreur
      try {
        await Supabase.instance.client.auth.signOut();
        Get.offAll(() => const LoginScreen());
      } catch (e2) {
        debugPrint("Erreur critique lors de la déconnexion: $e2");
      }
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
