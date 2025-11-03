import 'package:caferesto/common/widgets/layouts/grid_layout.dart';
import 'package:caferesto/common/widgets/products/cart/cart_menu_icon.dart';
import 'package:caferesto/common/widgets/brands/brand_card.dart';
import 'package:caferesto/common/widgets/shimmer/brands_shimmer.dart';
import 'package:caferesto/common/widgets/texts/section_heading.dart';
import 'package:caferesto/features/shop/controllers/etablissement_controller.dart';
import 'package:caferesto/features/shop/screens/brand/all_brands.dart';
import 'package:caferesto/features/shop/screens/brand/brand_products.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/appbar/tabbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../controllers/category_controller.dart';
import '../store/widgets/category_tab.dart';
import '../../models/statut_etablissement_model.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final etablissementController = EtablissementController.instance;
    final categoryController = CategoryController.instance;

    // Use Obx to reactively get categories and ensure controller is initialized
    return Obx(() {
      // Safety check: ensure controller is initialized
      if (!Get.isRegistered<CategoryController>()) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      final categories = categoryController.featuredCategories;

      if (categories.isEmpty) {
        return Scaffold(
          appBar: TAppBar(
            showBackArrow: false,
            title: Text(
              'Store',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          body: const Center(
            child: Text('Chargement des catégories...'),
          ),
        );
      }
      return DefaultTabController(
        length: categories.length,
        child: Scaffold(
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
            body: NestedScrollView(

                /// Header
                headerSliverBuilder: (_, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      pinned: true,
                      floating: true,
                      expandedHeight: 380,
                      // Space between appBar and TabBar
                      automaticallyImplyLeading: false,
                      backgroundColor: THelperFunctions.isDarkMode(context)
                          ? AppColors.black
                          : AppColors.white,

                      flexibleSpace: Padding(
                        padding: const EdgeInsets.all(AppSizes.defaultSpace),
                        child: ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            /// -- Établissements approuvés
                            TSectionHeading(
                              title: 'Nos parenaires',
                              onPressed: () =>
                                  Get.to(() => const AllBrandsScreen()),
                            ),
                            const SizedBox(
                              height: AppSizes.spaceBtwItems / 1.5,
                            ),

                            /// -- Grid des établissements approuvés
                            Obx(() {
                              if (etablissementController.isLoading.value) {
                                return const TbrandsShimmer();
                              }

                              final approved = etablissementController
                                  .etablissements
                                  .where((e) =>
                                      e.statut == StatutEtablissement.approuve)
                                  .toList();

                              if (approved.isEmpty) {
                                return Center(
                                    child: Text('Aucun établissement approuvé',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .apply(color: Colors.white)));
                              }
                              return GridLayout(
                                  itemCount: approved.length,
                                  mainAxisExtent: 80,
                                  itemBuilder: (_, index) {
                                    final brand = approved[index];
                                    return BrandCard(
                                        showBorder: true,
                                        brand: brand,
                                        onTap: () => Get.to(
                                            () => BrandProducts(brand: brand)));
                                  });
                            }),
                          ],
                        ),
                      ),

                      /// TABS
                      bottom: Tabbar(
                          tabs: categories
                              .map((category) => Tab(
                                    child: Text(
                                      category.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .apply(color: AppColors.primary),
                                    ),
                                  ))
                              .toList()),
                      /*
                    [

                    ] */
                    )
                  ];
                },
                body: TabBarView(
                  children: categories
                      .map((category) => CategoryTab(category: category))
                      .toList(),
                ))),
      );
    });
  }
}
