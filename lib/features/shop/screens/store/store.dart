import 'package:caferesto/common/widgets/layouts/grid_layout.dart';
import 'package:caferesto/common/widgets/products/cart/cart_menu_icon.dart';
import 'package:caferesto/common/widgets/brands/brand_card.dart';
import 'package:caferesto/common/widgets/shimmer/brands_shimmer.dart';
import 'package:caferesto/common/widgets/texts/section_heading.dart';
import 'package:caferesto/features/shop/controllers/etablissement_controller.dart';
import 'package:caferesto/features/shop/screens/brand/all_brands.dart';
import 'package:caferesto/features/shop/screens/brand/brand_products.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/colors.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final etablissementController = EtablissementController.instance;

  @override
  void initState() {
    super.initState();
    // Charger immédiatement tous les établissements approuvés pour le Store
    // Cette méthode charge indépendamment du rôle de l'utilisateur
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStoreEtablissements();
    });
  }

  Future<void> _loadStoreEtablissements() async {
    try {
      // Utiliser la méthode spécifique pour le Store qui charge tous les établissements approuvés
      // Cette méthode remplace complètement la liste avec tous les établissements approuvés
      await etablissementController.getApprovedEtablissementsForStore();
    } catch (e) {
      print('Erreur chargement établissements Store: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TAppBar(
        showBackArrow: false,
        title: Text(
          'Store',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        actions: [
          TCartCounterIcon(
            iconColor: AppColors.primary,
            counterBgColor: AppColors.primary,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStoreEtablissements,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// -- Établissements approuvés
              TSectionHeading(
                title: 'Nos partenaires',
                onPressed: () => Get.to(() => const AllBrandsScreen()),
              ),
              const SizedBox(
                height: AppSizes.spaceBtwItems,
              ),

            /// -- Grid des établissements approuvés
            Obx(() {
              // Afficher le shimmer pendant le chargement
              if (etablissementController.isLoading.value) {
                return const TbrandsShimmer();
              }

              // La liste etablissements contient déjà uniquement les établissements approuvés
              // car getApprovedEtablissementsForStore() les filtre déjà
              final approved = etablissementController.etablissements.toList();

              if (approved.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.defaultSpace),
                    child: Text(
                      'Aucun établissement approuvé',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              }
              
              // Use responsive grid: 1 column on small screens, 2 on larger screens
              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;
                  final mainAxisExtent = constraints.maxWidth < 400 ? 90.0 : 80.0;
                  
                  return GridLayout(
                    itemCount: approved.length,
                    crossAxisCount: crossAxisCount,
                    mainAxisExtent: mainAxisExtent,
                    itemBuilder: (_, index) {
                      final brand = approved[index];
                      return BrandCard(
                        showBorder: true,
                        brand: brand,
                        onTap: () => Get.to(() => BrandProducts(brand: brand)),
                      );
                    },
                  );
                },
              );
            }),
            ],
          ),
        ),
      ),
    );
  }
}
