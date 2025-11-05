import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/texts/brand_title_text_with_verified_icon.dart';
import '../../../../../common/widgets/texts/product_title_text.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/product/panier_controller.dart';
import '../../../controllers/product/variation_controller.dart';
import '../../../models/cart_item_model.dart';
import '../../product_details/product_detail.dart';
import 'cart_item_image.dart';
import 'cart_item_quantity_controls.dart';
import 'cart_item_variant_buttons.dart';

class TCartItems extends StatelessWidget {
  const TCartItems({
    super.key,
    this.showDeleteButton = true,
    this.showModifyButton = true,
    this.compactQuantity = false,
    this.isCheckout = false,
  });

  final bool showDeleteButton;
  final bool showModifyButton;
  final bool compactQuantity;
  final bool isCheckout; // If true, hide all buttons and show bill-like format

  @override
  Widget build(BuildContext context) {
    // Get controller once outside Obx to avoid repeated lookups using safe instance getter
    final controller = CartController.instance;
    final dark = THelperFunctions.isDarkMode(context);

    return Obx(() {
      // Safety check: ensure controller is initialized
      if (!Get.isRegistered<CartController>()) {
        return const SizedBox.shrink();
      }
      final items = controller.cartItems;
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppSizes.spaceBtwItems),
        itemBuilder: (_, index) {
          if (index >= items.length) return const SizedBox.shrink();
          final CartItemModel cartItem = items[index];

          return Container(
            padding: const EdgeInsets.all(AppSizes.md),
            margin: const EdgeInsets.only(bottom: AppSizes.spaceBtwItems),
            decoration: BoxDecoration(
              color: dark ? Colors.grey.shade900 : Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
              border: Border.all(
                color: dark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Image
                    CartItemImage(imageUrl: cartItem.image),
                    const SizedBox(width: AppSizes.spaceBtwItems),

                    /// Title & Brand
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BrandTitleWithVerifiedIcon(
                              title: cartItem.brandName ?? ''),

                          const SizedBox(height: 4),
                          TProductTitleText(
                            title: cartItem.title,
                            maxLines: 2,
                          ),

                          /// Current Variation Display
                          if (cartItem.product?.productType == 'variable' && cartItem.selectedVariation != null &&
                              cartItem.selectedVariation!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              cartItem.selectedVariation!.entries
                                  .map((e) => '${e.key}: ${e.value}')
                                  .join(', '),
                              style: TextStyle(
                                fontSize: 12,
                                color: dark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],

                          /// Edit and Add Buttons (only for variable products, hidden in checkout)
                          if (cartItem.product?.productType == 'variable' &&
                              !isCheckout) ...[
                            const SizedBox(height: 8),
                            CartItemVariantButtons(
                              cartItem: cartItem,
                              controller: controller,
                              onEdit: () =>
                                  _navigateToEditVariation(context, cartItem),
                              onAdd: () =>
                                  _navigateToAddVariation(context, cartItem),
                            ),
                          ],
                        ],
                      ),
                    ),

                    /// Delete Button (hidden in checkout)
                    if (!isCheckout)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => controller.dialogRetirerDuPanier(index),
                        icon: Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.red.shade400,
                        ),
                      ),
                  ],
                ),

                /// Quantity Controls & Total Price
                const SizedBox(height: AppSizes.sm),
                if (isCheckout)
                  // Bill-like format for checkout: show quantity x price = total
                  Obx(() {
                    // Get updated cart item from controller
                    final currentItem = controller.cartItems.firstWhereOrNull(
                      (item) =>
                          item.productId == cartItem.productId &&
                          item.variationId == cartItem.variationId,
                    );
                    final item = currentItem ?? cartItem;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Quantity x Price
                        Text(
                          '${item.quantity} x ${item.price.toStringAsFixed(2)} DT',
                          style: TextStyle(
                            fontSize: 14,
                            color: dark ? Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                        ),
                        // Total Price
                        Text(
                          '${(item.price * item.quantity).toStringAsFixed(2)} DT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    );
                  })
                else
                  // Normal format with quantity controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// Quantity Controls
                      CartItemQuantityControls(
                        cartItem: cartItem,
                        dark: dark,
                      ),

                      /// Total Price
                      Obx(() {
                        // Get updated cart item from controller
                        final currentItem = controller.cartItems.firstWhereOrNull(
                          (item) =>
                              item.productId == cartItem.productId &&
                              item.variationId == cartItem.variationId,
                        );
                        final item = currentItem ?? cartItem;
                        return Text(
                          '${(item.price * item.quantity).toStringAsFixed(2)} DT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                          ),
                        );
                      }),
                    ],
                  ),
              ],
            ),
          );
        },
      );
    });
  }

  /// Navigate to product detail for editing the current variation
  void _navigateToEditVariation(BuildContext context, CartItemModel cartItem) {
    final product = cartItem.product;
    if (product == null) {
      Get.snackbar(
        'Erreur',
        'Produit introuvable',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Find the cart item index
    final controller = CartController.instance;
    final cartItemIndex = controller.cartItems.indexWhere(
      (item) =>
          item.productId == cartItem.productId &&
          item.variationId == cartItem.variationId,
    );

    if (cartItemIndex < 0) {
      Get.snackbar(
        'Erreur',
        'Article introuvable dans le panier',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Pre-select the variation and initialize temp quantity BEFORE navigating
    final variationController = VariationController.instance;
    if (cartItem.variationId.isNotEmpty) {
      // Find the size and price for this variation
      final sizePrice = product.sizesPrices.firstWhereOrNull(
        (sp) => sp.size == cartItem.variationId,
      );

      if (sizePrice != null) {
        // Select the variation first
        variationController.selectVariation(sizePrice.size, sizePrice.price);
        
        // Initialiser la quantité temporaire avec la quantité actuelle de l'article du panier
        // Cela garantit que les contrôles de quantité affichent la bonne valeur
        controller.mettreAJourQuantiteTemporaire(product, cartItem.quantity);
      }
    }

    // Navigate to product detail in edit mode
    Get.to(() => ProductDetailScreen(
          product: product,
          isEditMode: true,
          initialVariationId: cartItem.variationId,
          currentCartItemIndex: cartItemIndex,
          onVariationSelected: () {
            // Ce callback sera appelé lorsque l'utilisateur confirme la modification
            controller.modifierVariationPanier(product.id, cartItemIndex);
          },
        ));
  }

  /// Navigate to product detail for adding a new variation
  void _navigateToAddVariation(BuildContext context, CartItemModel cartItem) {
    final product = cartItem.product;
    if (product == null) {
      Get.snackbar(
        'Erreur',
        'Produit introuvable',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Reset variation selection for a fresh start
    final variationController = VariationController.instance;
    variationController.resetSelectedAttributes();

    // Réinitialiser la quantité temporaire pour ce produit lors de l'ajout d'une nouvelle variante
    // Cela garantit que la quantité commence à zéro pour la nouvelle variante
    final controller = CartController.instance;
    controller.reinitialiserQuantiteTemporaireProduit(product.id);

    // Navigate to product detail
    Get.to(() => ProductDetailScreen(product: product));
  }
}
