import 'package:caferesto/common/widgets/appbar/appbar.dart';
import 'package:caferesto/common/widgets/custom_shapes/containers/primary_header_container.dart';
import 'package:caferesto/common/widgets/texts/section_heading.dart';
import 'package:caferesto/features/personalization/screens/profile/profile.dart';
import 'package:caferesto/features/shop/screens/cart/cart.dart';
import 'package:caferesto/features/shop/screens/order/gerant_order_management_screen.dart';
import 'package:caferesto/features/shop/screens/order/order.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../common/widgets/list_tiles/settings_menu_tile.dart';
import '../../../../common/widgets/list_tiles/user_profile_tile.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../notification/screens/notifications_screen.dart';
import '../../../shop/screens/product_reviews/list_produit_screen.dart';
import '../../controllers/user_controller.dart';
import '../address/address.dart';
import '../brands/mon_etablissement_screen.dart';
import '../categories/category_manager_screen.dart';
import '../dashboard/admin_dashboard_screen.dart';
import '../dashboard/gerant_dashboard_screen.dart';
import '../../../shop/controllers/etablissement_controller.dart';
import '../../../../utils/popups/loaders.dart';
import '../../../shop/models/statut_etablissement_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.put(UserController());

    bool isAdminOnly() {
      final role = userController.user.value.role;
      return role == 'Admin';
    }

    bool isAdminGerant() {
      final role = userController.user.value.role;
      return role == 'Gérant' || role == 'Admin';
    }

    return Scaffold(
      body: Obx(() {
        // Attendre que les données utilisateur soient chargées
        if (userController.profileLoading.value && userController.user.value.id.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = userController.user.value;
        
        // Si l'utilisateur n'est pas encore chargé, ne pas afficher
        if (user.id.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
            child: Column(
          children: [
            /// En tete
            TPrimaryHeaderContainer(
              child: Column(
                children: [
                  TAppBar(
                      showBackArrow: false,
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Compte',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium!
                                  .apply(color: AppColors.white)),
                          Text(
                            userController.user.value.role,
                            style: Theme.of(
                              context,
                            )
                                .textTheme
                                .headlineSmall!
                                .apply(color: AppColors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      )),

                  /// Carte du profil avec nom et email
                  TUserProfileTile(
                      onPressed: () => Get.to(() => const ProfileScreen())),
                  const SizedBox(height: AppSizes.spaceBtwSections),
                ],
              ),
            ),

            Padding(
                padding: EdgeInsets.all(AppSizes.defaultSpace),
                child: Column(children: [
                  /// Paramètres du compte
                  TSectionHeading(
                    title: "Réglages du compte",
                    showActionButton: false,
                  ),
                  SizedBox(height: AppSizes.spaceBtwItems),

                  TSettingsMenuTile(
                      title: "Mes Adresses",
                      subTitle: "Mes adresses de livraison",
                      icon: Iconsax.safe_home,
                      onTap: () => Get.to(() => const UserAddressScreen())),
                  TSettingsMenuTile(
                      title: "Mon Panier",
                      subTitle: "Ajouter, modifier ou supprimer des articles",
                      icon: Iconsax.shopping_cart,
                      onTap: () => Get.to(() => const CartScreen())),
                  TSettingsMenuTile(
                      title: "Mes Commandes",
                      subTitle: "Commandes passées et en cours",
                      icon: Iconsax.bag_tick,
                      onTap: () => Get.to(() => const OrderScreen())),
                  TSettingsMenuTile(
                      title: "Notifications",
                      subTitle: "Notifications de l'application",
                      icon: Iconsax.notification,
                      onTap: () => Get.to(() => const NotificationsScreen())),
                  // TSettingsMenuTile(
                  //     title: "Sécurité du Compte",
                  //     subTitle: "Sécuriser mon compte",
                  //     icon: Iconsax.security_card,
                  //     onTap: () {}),

                  /// Développeur , upload
                  if (isAdminGerant()) ...[
                    SizedBox(height: AppSizes.spaceBtwSections),
                    TSectionHeading(title: "Gestion", showActionButton: false),
                    SizedBox(height: AppSizes.spaceBtwItems),
                  ],

                  // Dashboard
                  if (isAdminOnly())
                    TSettingsMenuTile(
                      icon: Iconsax.chart_2,
                      title: "Dashboard Admin",
                      subTitle: "Statistiques et analyses détaillées",
                      onTap: () => Get.to(() => const AdminDashboardScreen()),
                    ),
                  if (userController.user.value.role == 'Gérant')
                    TSettingsMenuTile(
                      icon: Iconsax.chart_2,
                      title: "Dashboard Gérant",
                      subTitle: "Statistiques de mon établissement",
                      onTap: () => Get.to(() => const GerantDashboardScreen()),
                    ),

                  if (isAdminGerant())
                    TSettingsMenuTile(
                      icon: Iconsax.category,
                      title: "Gérer commandes",
                      subTitle:
                          "Consulter, ajouter, modifier ou supprimer une catégorie",
                      onTap: () async {
                        final role = userController.user.value.role;
                        if (role == 'Gérant') {
                          final etab = await EtablissementController.instance
                              .getEtablissementUtilisateurConnecte();
                          if (etab == null ||
                              etab.statut != StatutEtablissement.approuve) {
                            TLoaders.errorSnackBar(
                                message:
                                    'Accès désactivé tant que votre établissement n\'est pas approuvé.');
                            return;
                          }
                        }
                        final result =
                            await Get.to(() => GerantOrderManagementScreen());
                        if (result == true) {
                          print("Écran fermé et formulaire réinitialisé");
                        }
                      },
                    ),
                  if (isAdminOnly())
                    TSettingsMenuTile(
                      icon: Iconsax.category,
                      title: "Gérer catégorie",
                      subTitle:
                          "Consulter, ajouter, modifier ou supprimer une catégorie",
                      onTap: () async {
                        final result =
                            await Get.to(() => CategoryManagementPage());
                        if (result == true) {
                          // Le formulaire a été réinitialisé
                          print("Écran fermé et formulaire réinitialisé");
                        }
                      },
                    ),
                  SizedBox(height: AppSizes.spaceBtwItems),
                  if (isAdminGerant())
                    TSettingsMenuTile(
                      icon: Iconsax.home,
                      title: "Gérer  établissement",
                      subTitle:
                          "Consulter, ajouter, modifier ou supprimer un établissement",
                      onTap: () => Get.to(() => MonEtablissementScreen()),
                    ),
                  SizedBox(
                    height: AppSizes.spaceBtwItems,
                  ),

                  if (isAdminGerant())
                    TSettingsMenuTile(
                      icon: Iconsax.bag_tick_2,
                      title: "Gérer produit",
                      subTitle:
                          "Consulter, ajouter, modifier ou supprimer un produit",
                      onTap: () async {
                        final role = userController.user.value.role;
                        if (role == 'Gérant') {
                          final etab = await EtablissementController.instance
                              .getEtablissementUtilisateurConnecte();
                          if (etab == null ||
                              etab.statut != StatutEtablissement.approuve) {
                            TLoaders.errorSnackBar(
                                message:
                                    'Accès désactivé tant que votre établissement n\'est pas approuvé.');
                            return;
                          }
                        }
                        Get.to(() => ListProduitScreen());
                      },
                    ),
                  SizedBox(
                    height: AppSizes.spaceBtwSections,
                  ),
                  SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                          onPressed: () =>
                              AuthenticationRepository.instance.logout(),
                          child: Text("Logout")))
                ]))
          ],
        ));
      }),
    );
  }
}
