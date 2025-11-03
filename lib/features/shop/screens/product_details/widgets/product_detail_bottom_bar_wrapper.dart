import 'package:caferesto/features/shop/controllers/product/panier_controller.dart';
import 'package:caferesto/features/shop/models/produit_model.dart';
import 'package:caferesto/features/shop/screens/cart/cart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'product_bottom_bar.dart';

class ProductDetailBottomBarWrapper extends StatelessWidget {
  const ProductDetailBottomBarWrapper({
    super.key,
    required this.product,
    required this.dark,
    required this.isSmallScreen,
    this.onVariationSelected,
  });

  final ProduitModel product;
  final bool dark;
  final bool isSmallScreen;
  final VoidCallback? onVariationSelected;

  void _handleMainAction(CartController controller) {
    if (!controller.canAddProduct(product)) return;

    if (product.productType == 'variable') {
      final hasSelectedVariant = controller.hasSelectedVariant();
      if (!hasSelectedVariant) {
        Get.snackbar(
          'Sélection requise',
          'Veuillez choisir une variante avant de continuer',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // If this is a modification (edit mode), call the callback
      if (onVariationSelected != null) {
        onVariationSelected!();
        return;
      }

      // Check if the SPECIFIC variation is in cart (for add mode)
      final selectedSize = controller.variationController.selectedSize.value;
      if (selectedSize.isNotEmpty) {
        final variationQuantity =
            controller.getVariationQuantityInCart(product.id, selectedSize);
        if (variationQuantity > 0) {
          // This specific variation is already in cart, navigate to cart
          Get.to(() => const CartScreen());
          return;
        }
      }
    } else {
      // For single products, check if product is in cart
      final quantity = controller.getProductQuantityInCart(product.id);
      if (quantity > 0) {
        Get.to(() => const CartScreen());
        return;
      }
    }

    // Add new item (either new variation or new product)
    // Use addToCart which handles the logic properly
    controller.addToCart(product);
  }

  void _handleIncrement(CartController controller) {
    if (!controller.canAddProduct(product)) return;
    if (product.productType == 'single' || controller.hasSelectedVariant()) {
      // Get current temp quantity and increment it
      final currentQuantity = controller.getTempQuantity(product);
      controller.updateTempQuantity(product, currentQuantity + 1);
    }
  }

  void _handleDecrement(CartController controller) {
    if (product.productType == 'single' || controller.hasSelectedVariant()) {
      // Get current temp quantity and decrement it
      final currentQuantity = controller.getTempQuantity(product);
      if (currentQuantity > 0) {
        controller.updateTempQuantity(product, currentQuantity - 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use safe instance getter
    final controller = CartController.instance;

    return ProductBottomBar(
      product: product,
      dark: dark,
      isSmallScreen: isSmallScreen,
      onIncrement: () => _handleIncrement(controller),
      onDecrement: () => _handleDecrement(controller),
      onMainAction: () => _handleMainAction(controller),
    );
  }
}
