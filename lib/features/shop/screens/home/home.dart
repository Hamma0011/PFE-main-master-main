import 'package:caferesto/common/widgets/products/product_cards/product_card_vertical.dart';
import 'package:caferesto/features/shop/screens/home/widgets/build_empty_state.dart';
import 'package:caferesto/utils/device/device_utility.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../../common/widgets/layouts/grid_layout.dart';
import '../../../../common/widgets/shimmer/vertical_product_shimmer.dart';
import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../common/widgets/custom_shapes/containers/primary_header_container.dart';
import '../../../authentication/screens/home/widgets/home_categories.dart';
import '../../controllers/product/produit_controller.dart';
import '../all_products/all_products.dart';
import 'widgets/home_appbar.dart';
import 'widgets/promo_slider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProduitController());
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// Primary Header Container
            TPrimaryHeaderContainer(
              child: Column(
                children: [
                  /// AppBar
                  const THomeAppBar(),
                  const SizedBox(height: AppSizes.spaceBtwSections),

                  /// Catégories
                  TSectionHeading(
                      title: 'Catégories Populaires',
                      padding: EdgeInsets.all(0),
                      showActionButton: true,
                      whiteTextColor: true),
                  const SizedBox(height: AppSizes.spaceBtwItems),

                  /// Categories List
                  const THomeCategories(),
                  const SizedBox(height: AppSizes.spaceBtwItems),
                ],
              ),
            ),

            /// Corps
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: TDeviceUtils.getHorizontalPadding(screenWidth),
                vertical: AppSizes.defaultSpace,
              ),
              child: Column(
                children: [
                  /// -- PromoSlider avec hauteur responsive
                  TPromoSlider(
                    banners: const [
                      TImages.promoBanner1,
                      TImages.promoBanner2,
                      TImages.promoBanner3
                    ],
                    height: TDeviceUtils.getPromoSliderHeight(
                        screenWidth, screenHeight),
                    autoPlay: true,
                    autoPlayInterval: 5000,
                  ),
                  const SizedBox(height: AppSizes.spaceBtwSections),

                  /// -- En tête
                  TSectionHeading(
                    title: 'Produits Populaires',
                    padding: EdgeInsets.all(0),
                    showActionButton: true,
                    onPressed: () => Get.to(() => AllProducts(
                          title: 'Produits populaires',
                          futureMethod: controller.fetchAllFeaturedProducts(),
                        )),
                  ),
                  const SizedBox(height: AppSizes.spaceBtwItems),

                  /// Popular products avec GridLayout responsive
                  Obx(() {
                    if (controller.isLoading.value) {
                      return const TVerticalProductShimmer();
                    }
                    if (controller.featuredProducts.isEmpty) {
                      return BuildEmptyState();
                    }
                    return GridLayout(
                      itemCount: controller.featuredProducts.length,
                      itemBuilder: (_, index) => ProductCardVertical(
                        product: controller.featuredProducts[index],
                      ),
                      crossAxisCount:
                          TDeviceUtils.getCrossAxisCount(screenWidth),
                      mainAxisExtent:
                          TDeviceUtils.getMainAxisExtent(screenWidth),
                    );
                  })
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
