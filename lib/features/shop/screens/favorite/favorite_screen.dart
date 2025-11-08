import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:caferesto/common/widgets/appbar/appbar.dart';
import 'package:caferesto/common/widgets/products/product_cards/product_card_vertical.dart';
import 'package:caferesto/common/widgets/shimmer/vertical_product_shimmer.dart';
import 'package:caferesto/common/widgets/layouts/grid_layout.dart';
import 'package:caferesto/features/shop/controllers/product/favorites_controller.dart';
import 'package:caferesto/features/shop/models/produit_model.dart';
import 'package:caferesto/navigation_menu.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/constants/image_strings.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/device/device_utility.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:caferesto/utils/loaders/animation_loader.dart';
import '../../../../utils/popups/loaders.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = FavoritesController.instance;
    final isDark = THelperFunctions.isDarkMode(context);
    final screenWidth = MediaQuery.of(context).size.width;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.isLoading.value &&
          controller.favoriteProducts.isEmpty &&
          controller.favoriteIds.isNotEmpty) {
        controller.loadFavorites();
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.dark : AppColors.light,
      appBar: _buildAppBar(context, isDark, controller),
      body: RefreshIndicator(
        onRefresh: controller.loadFavorites,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: TDeviceUtils.getHorizontalPadding(screenWidth),
              vertical: AppSizes.defaultSpace,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, controller),
                const SizedBox(height: AppSizes.spaceBtwSections),
                Obx(() => _buildContent(context, controller, screenWidth)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, bool isDark, FavoritesController controller) {
    return TAppBar(
      title: Text(
        'Mes Favoris',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
      ),
      actions: [
        Obx(() => controller.favoriteIds.isNotEmpty
            ? IconButton(
                onPressed: () => _showClearAllBottomSheet(context, controller),
                icon: Icon(Icons.delete_outline_rounded,
                    color:
                        isDark ? Colors.grey.shade300 : Colors.grey.shade700),
              )
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, FavoritesController controller) {
    return Obx(() {
      final count = controller.favoriteIds.length;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Produits favoris ($count)',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          if (count > 0)
            Text('$count ${count > 1 ? 'produits' : 'produit'}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey.shade600)),
        ],
      );
    });
  }

  Widget _buildContent(
      BuildContext context, FavoritesController controller, double screenWidth) {
    if (controller.isLoading.value) {
      return GridLayout(
        itemCount: 6,
        itemBuilder: (_, __) => const TVerticalProductShimmer(),
        crossAxisCount: TDeviceUtils.getCrossAxisCount(screenWidth),
        mainAxisExtent: TDeviceUtils.getMainAxisExtent(screenWidth),
      );
    }

    if (controller.favoriteIds.isEmpty) {
      return _buildEmptyState(context);
    }

    if (controller.favoriteProducts.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!controller.isLoading.value) controller.loadFavorites();
      });
      return SizedBox(
        height: 200,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final products = controller.favoriteProducts;
    return GridLayout(
      itemCount: products.length,
      itemBuilder: (_, index) {
        final ProduitModel p = products[index];
        return ProductCardVertical(
          product: p,
          onFavoriteTap: () => controller.toggleFavoriteProduct(p.id),
        );
      },
      crossAxisCount: TDeviceUtils.getCrossAxisCount(screenWidth),
      mainAxisExtent: TDeviceUtils.getMainAxisExtent(screenWidth),
    );
  }

  /// --- Responsive Empty State ---
  Widget _buildEmptyState(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final screenHeight = MediaQuery.of(context).size.height;
      final availableHeight =
          constraints.maxHeight.isFinite ? constraints.maxHeight : screenHeight;
      final animationHeight =
          max(180.0, min(availableHeight * 0.4, 320.0)); // 180–320px range

      return SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Votre liste de favoris est vide !",
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: animationHeight,
                  width: min(animationHeight * 1.2, 400),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: TAnimationLoaderWidget(
                      text: '',
                      animation: TImages.pencilAnimation,
                      showAction: false,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                _buildPrimaryButton(
                  context,
                  label: "Découvrir des produits",
                  icon: Icons.explore_outlined,
                  onPressed: () => Get.offAll(() => const NavigationMenu()),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// --- Custom Ecommerce Button ---
  Widget _buildPrimaryButton(BuildContext context,
      {required String label,
      required IconData icon,
      required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 6,
        shadowColor: AppColors.primary.withOpacity(0.35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      icon: Icon(icon, size: 22),
      label: Text(label),
      onPressed: onPressed,
    );
  }

  /// --- Modal Bottom Sheet ---
  void _showClearAllBottomSheet(
      BuildContext context, FavoritesController controller) {
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = min(screenHeight * 0.38, 380.0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: FractionallySizedBox(
            heightFactor: sheetHeight / screenHeight,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 6,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const Icon(Icons.delete_sweep_outlined,
                      size: 44, color: Colors.redAccent),
                  const SizedBox(height: 10),
                  Text("Vider les favoris",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(
                    "Supprimer tous vos produits favoris ? Cette action est irréversible.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Get.back(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: const Text("Annuler"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Obx(() {
                          final isBusy = controller.isLoading.value;
                          return ElevatedButton.icon(
                            onPressed: isBusy
                                ? null
                                : () async {
                                    final success =
                                        await controller.clearAllFavorites();
                                    Get.back();
                                    if (success) {
                                      TLoaders.successSnackBar(
                                          title: "Favoris vidés",
                                          message:
                                              "Tous les produits favoris ont été supprimés.");
                                    } else {
                                      TLoaders.errorSnackBar(
                                          title: "Erreur",
                                          message:
                                              "Impossible de vider vos favoris.");
                                    }
                                  },
                            icon: isBusy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.delete_forever_outlined,
                                    size: 18),
                            label:
                                Text(isBusy ? "Suppression..." : "Supprimer"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
