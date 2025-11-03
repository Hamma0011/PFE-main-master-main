import 'package:caferesto/common/widgets/texts/product_price_text.dart';
import 'package:caferesto/common/widgets/texts/section_heading.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/products/product_cards/widgets/rounded_container.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../controllers/product/panier_controller.dart';
import '../../../controllers/product/variation_controller.dart';
import '../../../models/produit_model.dart';

class TProductAttributes extends StatelessWidget {
  final ProduitModel product;
  final String? tag;
  final String? excludeVariationId; // Variation to exclude from disabled list (for edit mode)

  const TProductAttributes({
    super.key,
    required this.product,
    this.tag,
    this.excludeVariationId,
  });

  @override
  Widget build(BuildContext context) {
    // Safe access to controllers using instance getters
    final variationController = VariationController.instance;
    final cartController = CartController.instance;
    final dark = THelperFunctions.isDarkMode(context);

    return Obx(() {
      // Safety check: ensure controllers are initialized
      if (!Get.isRegistered<VariationController>() || !Get.isRegistered<CartController>()) {
        return const SizedBox.shrink();
      }
      final selectedSize = variationController.selectedSize.value;

      // ✅ Ensemble des variations déjà ajoutées au panier
      final variationsInCartSet =
          cartController.getVariationsInCartSet(product.id);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const TSectionHeading(
            title: 'Tailles disponibles',
            showActionButton: false,
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),

          /// --- Liste des tailles ---
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: product.sizesPrices.map((sp) {
              final bool isSelected = selectedSize == sp.size;
              // Check if this variation is in cart, but exclude current variation if in edit mode
              final bool isInCart = variationsInCartSet.contains(sp.size) &&
                  (excludeVariationId == null || sp.size != excludeVariationId);

              return ChoiceChip(
                label: Text(
                  '${sp.size} (${sp.price.toStringAsFixed(2)} DT)${isInCart ? ' ✓' : ''}',
                  style: TextStyle(
                    color: isInCart && !isSelected
                        ? Colors.grey.shade500
                        : (isSelected
                            ? Colors.white
                            : (dark ? Colors.white70 : Colors.black87)),
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: isInCart && !isSelected
                    ? (dark
                        ? Colors.grey.shade800.withOpacity(0.5)
                        : Colors.grey.shade300)
                    : (dark ? AppColors.darkerGrey : AppColors.lightGrey),
                disabledColor: dark
                    ? Colors.grey.shade800.withOpacity(0.5)
                    : Colors.grey.shade300,
                labelStyle: TextStyle(
                  decoration: isInCart && !isSelected
                      ? TextDecoration.lineThrough
                      : null,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                avatar: isInCart && !isSelected
                    ? Icon(Icons.lock, size: 16, color: Colors.grey.shade500)
                    : null,

                /// --- Disable variations already in cart (except current one in edit mode) ---
                onSelected: isInCart && !isSelected
                    ? null
                    : (bool selected) {
                        // Prevent selecting variations already in cart
                        if (isInCart) {
                          Get.snackbar(
                            'Déjà ajouté',
                            'Cette variation est déjà dans le panier.',
                            backgroundColor: Colors.orange.shade100,
                            colorText: Colors.black87,
                          );
                          return;
                        }

                        // Select or deselect variation
                        if (selected) {
                          variationController.selectVariation(sp.size, sp.price);
                          // When variation changes, ensure temp quantity reflects existing cart quantity
                          // This is handled automatically by getTempQuantity, which calls getExistingQuantity
                          // No need to update variation in cart here - we're just selecting, not adding
                        } else {
                          variationController.clearVariation();
                        }
                      },
              );
            }).toList(),
          ),

          const SizedBox(height: AppSizes.spaceBtwItems * 1.5),

          /// --- Détails de la variation sélectionnée ---
          if (selectedSize.isNotEmpty)
            TRoundedContainer(
              padding: const EdgeInsets.all(AppSizes.md),
              backgroundColor:
                  dark ? AppColors.darkerGrey : AppColors.grey.withOpacity(0.2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Taille sélectionnée : $selectedSize',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: [
                      const Text(
                        'Prix : ',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      ProductPriceText(
                        price: variationController.selectedPrice.value
                            .toStringAsFixed(2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}
