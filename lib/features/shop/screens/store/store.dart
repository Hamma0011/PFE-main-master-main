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
import '../../models/statut_etablissement_model.dart';

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
    // S'assurer de charger tous les établissements au chargement de la page Store
    // pour afficher tous les établissements approuvés, peu importe le rôle
    // La page Store doit toujours afficher TOUS les établissements approuvés
    WidgetsBinding.instance.addPostFrameCallback((_) {
      etablissementController.getTousEtablissements();
    });
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.defaultSpace),
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
              if (etablissementController.isLoading.value) {
                return const TbrandsShimmer();
              }

              final approved = etablissementController.etablissements
                  .where((e) => e.statut == StatutEtablissement.approuve)
                  .toList();

              if (approved.isEmpty) {
                return Center(
                  child: Text(
                    'Aucun établissement approuvé',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              return GridLayout(
                itemCount: approved.length,
                mainAxisExtent: 80,
                itemBuilder: (_, index) {
                  final brand = approved[index];
                  return BrandCard(
                    showBorder: true,
                    brand: brand,
                    onTap: () => Get.to(() => BrandProducts(brand: brand)),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
