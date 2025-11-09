import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../../utils/popups/loaders.dart';
import '../../controllers/user_management_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/user_model.dart';

class AdminUserManagementScreen extends StatelessWidget {
  const AdminUserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserManagementController());
    final dark = THelperFunctions.isDarkMode(context);

    // Vérifier que l'utilisateur est Admin
    if (!controller.isAdmin) {
      return Scaffold(
        appBar: TAppBar(
          title: const Text('Gestion des Utilisateurs'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.lock, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Accès refusé',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Seuls les administrateurs peuvent accéder à cette page.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: TAppBar(
        title: const Text('Gestion des Utilisateurs'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: () => controller.loadAllUsers(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.users.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Barre de recherche et filtres
            _buildSearchAndFilters(controller, dark),

            // Liste des utilisateurs
            Expanded(
              child: controller.filteredUsers.isEmpty
                  ? _buildEmptyState(dark)
                  : _buildUsersList(controller, dark),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSearchAndFilters(
      UserManagementController controller, bool dark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.defaultSpace),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkContainer : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: dark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un utilisateur...',
              prefixIcon: const Icon(Iconsax.search_normal),
              suffixIcon: controller.searchQuery.value.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Iconsax.close_circle),
                      onPressed: () => controller.searchQuery.value = '',
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
              ),
            ),
            onChanged: (value) => controller.searchQuery.value = value,
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),

          // Filtres
          Row(
            children: [
              // Filtre par rôle
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                      value: controller.selectedRole.value,
                      decoration: InputDecoration(
                        labelText: 'Rôle',
                        prefixIcon: const Icon(Iconsax.profile_2user),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.cardRadiusMd),
                        ),
                      ),
                      items: controller.uniqueRoles.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          controller.selectedRole.value = value,
                    )),
              ),
              const SizedBox(width: AppSizes.spaceBtwItems),

              // Filtre par statut de bannissement
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                      value: controller.selectedBanStatus.value,
                      decoration: InputDecoration(
                        labelText: 'Statut',
                        prefixIcon: const Icon(Iconsax.shield),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.cardRadiusMd),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Tous', child: Text('Tous')),
                        DropdownMenuItem(
                            value: 'Non bannis', child: Text('Non bannis')),
                        DropdownMenuItem(
                            value: 'Bannis', child: Text('Bannis')),
                      ],
                      onChanged: (value) =>
                          controller.selectedBanStatus.value = value,
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool dark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.profile_2user,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun utilisateur trouvé',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(UserManagementController controller, bool dark) {
    return RefreshIndicator(
      onRefresh: () => controller.loadAllUsers(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.defaultSpace),
        itemCount: controller.filteredUsers.length,
        itemBuilder: (context, index) {
          final user = controller.filteredUsers[index];
          return _buildUserCard(user, controller, dark);
        },
      ),
    );
  }

  Widget _buildUserCard(
    UserModel user,
    UserManagementController controller,
    bool dark,
  ) {
    final userController = Get.find<UserController>();
    final isCurrentUser = user.id == userController.user.value.id;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spaceBtwItems),
      color: user.isBanned
          ? (dark ? Colors.red.withOpacity(0.1) : Colors.red.shade50)
          : null,
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSizes.md),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: user.isBanned
              ? Colors.red.withOpacity(0.2)
              : AppColors.primary.withOpacity(0.1),
          backgroundImage:
              user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
          child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
              ? Text(
                  user.fullName.isNotEmpty
                      ? user.fullName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: user.isBanned ? Colors.red : AppColors.primary,
                  ),
                )
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.fullName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: user.isBanned ? Colors.red : null,
                ),
              ),
            ),
            if (user.isBanned)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'BANNI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.role,
                    style: TextStyle(
                      color: _getRoleColor(user.role),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Vous',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (user.createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Inscrit le ${_formatDate(user.createdAt!)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
        trailing: isCurrentUser
            ? IconButton(
                icon: const Icon(Iconsax.info_circle),
                onPressed: () {
                  TLoaders.infoSnackBar(
                    title: 'Information',
                    message: 'Vous ne pouvez pas modifier votre propre statut.',
                  );
                },
                tooltip: 'Vous ne pouvez pas vous bannir',
              )
            : IconButton(
                icon: Icon(
                  user.isBanned ? Iconsax.unlock : Iconsax.lock,
                  color: user.isBanned ? Colors.green : Colors.red,
                ),
                onPressed: () => _showBanDialog(user, controller, dark),
                tooltip: user.isBanned ? 'Débannir' : 'Bannir',
              ),
      ),
    );
  }

  void _showBanDialog(
    UserModel user,
    UserManagementController controller,
    bool dark,
  ) {
    final isBanned = user.isBanned;

    Get.dialog(
      AlertDialog(
        title: Text(
            isBanned ? 'Débannir l\'utilisateur' : 'Bannir l\'utilisateur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBanned
                  ? 'Êtes-vous sûr de vouloir débannir cet utilisateur ?'
                  : 'Êtes-vous sûr de vouloir bannir cet utilisateur ?',
            ),
            const SizedBox(height: 16),
            Text(
              'Utilisateur: ${user.fullName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Email: ${user.email}'),
            Text('Rôle: ${user.role}'),
            if (!isBanned) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ L\'utilisateur sera déconnecté immédiatement et ne pourra plus se connecter.',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success = isBanned
                  ? await controller.unbanUser(user.id)
                  : await controller.banUser(user.id);

              if (success) {
                await controller.loadAllUsers();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isBanned ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isBanned ? 'Débannir' : 'Bannir'),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin':
        return Colors.red;
      case 'Gérant':
        return Colors.blue;
      case 'Client':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
