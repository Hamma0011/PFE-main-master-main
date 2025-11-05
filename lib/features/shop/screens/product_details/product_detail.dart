import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/device/device_utility.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/product/panier_controller.dart';
import '../../controllers/product/variation_controller.dart';
import '../../models/produit_model.dart';
import 'widgets/product_detail_bottom_bar_wrapper.dart';
import 'widgets/product_detail_desktop_layout.dart';
import 'widgets/product_detail_mobile_layout.dart';

class ProductDetailScreen extends StatelessWidget {
  ProductDetailScreen({
    super.key,
    required this.product,
    this.skipVariationReset = false,
    this.initialVariationId,
    this.onVariationSelected,
    this.currentCartItemIndex,
    this.isEditMode = false,
  }) {
    // Reset variations when screen is opened (unless skipping for edit mode)
    if (!skipVariationReset && !isEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<VariationController>()) {
          final controller = VariationController.instance;
          controller.resetSelectedAttributes();
        }
      });
    } else if (isEditMode && initialVariationId != null) {
      // In edit mode, initialize with the current variation and quantity
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<VariationController>()) {
          final variationController = VariationController.instance;
          final cartController = CartController.instance;
          
          // Find the size and price for this variation
          final sizePrice = product.sizesPrices.firstWhereOrNull(
            (sp) => sp.size == initialVariationId,
          );
          if (sizePrice != null) {
            // Select the variation
            variationController.selectVariation(sizePrice.size, sizePrice.price);
            
            // Initialize temp quantity with the current cart item's quantity if not already set
            // This ensures quantity controls show the correct value
            final currentTempQuantity = cartController.obtenirQuantiteTemporaire(product);
            if (currentTempQuantity == 0) {
              // Obtenir la quantité du panier pour cette variation
              final cartQuantity = cartController.obtenirQuantiteVariationDansPanier(
                product.id,
                initialVariationId!,
              );
              if (cartQuantity > 0) {
                cartController.mettreAJourQuantiteTemporaire(product, cartQuantity);
              }
            }
          }
        }
      });
    }
  }

  final ProduitModel product;
  final bool skipVariationReset;
  final String? initialVariationId;
  final VoidCallback? onVariationSelected;
  final int? currentCartItemIndex; // For edit mode
  final bool isEditMode; // Whether we're editing an existing cart item

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final isDesktop = TDeviceUtils.isDesktop(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 380;

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : AppColors.light,
      bottomNavigationBar: ProductDetailBottomBarWrapper(
        product: product,
        dark: dark,
        isSmallScreen: isSmallScreen,
        onVariationSelected: onVariationSelected,
      ),
      body: SafeArea(
        child: isDesktop
            ? ProductDetailDesktopLayout(
                product: product,
                dark: dark,
                excludeVariationId: isEditMode ? initialVariationId : null,
              )
            : ProductDetailMobileLayout(
                product: product,
                dark: dark,
                excludeVariationId: isEditMode ? initialVariationId : null,
              ),
      ),
    );
  }
}
