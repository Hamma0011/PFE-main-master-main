import 'package:get/get.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/popups/loaders.dart';
import '../models/user_model.dart';
import 'user_controller.dart';

class UserManagementController extends GetxController {
  static UserManagementController get instance {
    try {
      return Get.find<UserManagementController>();
    } catch (e) {
      return Get.put(UserManagementController(), permanent: true);
    }
  }

  final UserRepository _userRepository = UserRepository.instance;
  final UserController _userController = Get.find<UserController>();

  // États réactifs
  final isLoading = false.obs;
  final users = <UserModel>[].obs;
  final searchQuery = ''.obs;
  final selectedRole = Rx<String?>('Tous');
  final selectedBanStatus = Rx<String?>('Tous'); // Tous, Bannis, Non bannis

  @override
  void onInit() {
    super.onInit();
    loadAllUsers();
  }

  /// Charger tous les utilisateurs
  Future<void> loadAllUsers() async {
    try {
      isLoading.value = true;
      final usersList = await _userRepository.getAllUsers();
      users.assignAll(usersList);
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Erreur',
        message: 'Impossible de charger les utilisateurs: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Bannir un utilisateur
  Future<bool> banUser(String userId) async {
    // Vérifier que l'utilisateur actuel est Admin
    if (_userController.userRole != 'Admin') {
      TLoaders.errorSnackBar(
        title: 'Permission refusée',
        message: 'Seuls les administrateurs peuvent bannir des utilisateurs.',
      );
      return false;
    }

    // Ne pas permettre de se bannir soi-même
    if (userId == _userController.user.value.id) {
      TLoaders.errorSnackBar(
        title: 'Action impossible',
        message: 'Vous ne pouvez pas vous bannir vous-même.',
      );
      return false;
    }

    try {
      isLoading.value = true;
      final success = await _userRepository.banUser(userId);
      
      if (success) {
        // Mettre à jour la liste locale
        final index = users.indexWhere((u) => u.id == userId);
        if (index != -1) {
          users[index] = users[index].copyWith(isBanned: true);
        }
        
        TLoaders.successSnackBar(
          title: 'Succès',
          message: 'Utilisateur banni avec succès',
        );
        return true;
      }
      return false;
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Erreur',
        message: 'Impossible de bannir l\'utilisateur: $e',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Débannir un utilisateur
  Future<bool> unbanUser(String userId) async {
    // Vérifier que l'utilisateur actuel est Admin
    if (_userController.userRole != 'Admin') {
      TLoaders.errorSnackBar(
        title: 'Permission refusée',
        message: 'Seuls les administrateurs peuvent débannir des utilisateurs.',
      );
      return false;
    }

    try {
      isLoading.value = true;
      final success = await _userRepository.unbanUser(userId);
      
      if (success) {
        // Mettre à jour la liste locale
        final index = users.indexWhere((u) => u.id == userId);
        if (index != -1) {
          users[index] = users[index].copyWith(isBanned: false);
        }
        
        TLoaders.successSnackBar(
          title: 'Succès',
          message: 'Utilisateur débanni avec succès',
        );
        return true;
      }
      return false;
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Erreur',
        message: 'Impossible de débannir l\'utilisateur: $e',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Utilisateurs filtrés
  List<UserModel> get filteredUsers {
    var filtered = users.toList();

    // Filtre par recherche
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((user) {
        return user.email.toLowerCase().contains(query) ||
            user.firstName.toLowerCase().contains(query) ||
            user.lastName.toLowerCase().contains(query) ||
            user.fullName.toLowerCase().contains(query);
      }).toList();
    }

    // Filtre par rôle
    if (selectedRole.value != null && selectedRole.value != 'Tous') {
      filtered = filtered.where((user) => user.role == selectedRole.value).toList();
    }

    // Filtre par statut de bannissement
    if (selectedBanStatus.value != null && selectedBanStatus.value != 'Tous') {
      if (selectedBanStatus.value == 'Bannis') {
        filtered = filtered.where((user) => user.isBanned).toList();
      } else if (selectedBanStatus.value == 'Non bannis') {
        filtered = filtered.where((user) => !user.isBanned).toList();
      }
    }

    return filtered;
  }

  /// Liste des rôles uniques
  List<String> get uniqueRoles {
    final roles = users.map((u) => u.role).toSet().toList();
    return ['Tous', ...roles];
  }

  /// Vérifier si l'utilisateur actuel est Admin
  bool get isAdmin => _userController.userRole == 'Admin';
}

