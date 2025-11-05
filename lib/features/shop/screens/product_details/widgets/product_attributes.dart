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
          cartController.obtenirVariationsDansPanierSet(product.id);

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
              // Vérifier si cette variation est dans le panier
              final bool isInCart = variationsInCartSet.contains(sp.size) &&
                  (excludeVariationId == null || sp.size != excludeVariationId);
              
              // Obtenir la quantité de cette variation dans le panier
              final variationQuantity = isInCart
                  ? cartController.obtenirQuantiteVariationDansPanier(product.id, sp.size)
                  : 0;

              return ChoiceChip(
                label: Text(
                  '${sp.size} (${sp.price.toStringAsFixed(2)} DT)${isInCart ? ' ✓ ($variationQuantity)' : ''}',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (dark ? Colors.white70 : Colors.black87),
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: isInCart && !isSelected
                    ? (dark
                        ? Colors.green.shade900.withOpacity(0.3)
                        : Colors.green.shade50)
                    : (dark ? AppColors.darkerGrey : AppColors.lightGrey),
                disabledColor: dark
                    ? Colors.grey.shade800.withOpacity(0.5)
                    : Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                avatar: isInCart && !isSelected
                    ? Icon(Icons.check_circle, size: 16, color: Colors.green.shade600)
                    : null,

                /// --- Permettre la sélection de plusieurs tailles ---
                onSelected: (bool selected) {
                  // Select or deselect variation
                  if (selected) {
                    variationController.selectVariation(sp.size, sp.price);
                    // Si cette variation est déjà dans le panier, on permet quand même de la sélectionner
                    // pour permettre d'ajouter plus de cette taille ou de la modifier
                  } else {
                    // Si on désélectionne, on efface seulement si c'était la taille sélectionnée
                    if (isSelected) {
                      variationController.clearVariation();
                    }
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
