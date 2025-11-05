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

  const TProductAttributes({super.key, required this.product, this.tag});

  @override
  Widget build(BuildContext context) {
    final variationController = Get.find<VariationController>(tag: tag);
    final dark = THelperFunctions.isDarkMode(context);

    return Obx(() {
      final selectedSize = variationController.selectedSize.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TSectionHeading(
              title: 'Tailles disponibles', showActionButton: false),
          const SizedBox(height: AppSizes.spaceBtwItems),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: product.sizesPrices.map((sp) {
              final bool isSelected = selectedSize == sp.size;
              return ChoiceChip(
                label: Text(
                  '${sp.size} (${sp.price.toStringAsFixed(2)} DT)',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (dark ? Colors.white70 : Colors.black87),
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor:
                    dark ? AppColors.darkerGrey : AppColors.lightGrey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (bool selected) {
                  if (selected) {
                    variationController.selectVariation(sp.size, sp.price);
                    CartController.instance.mettreAJourVariation(
                      product.id,
                      variationController.selectedSize.value,
                      variationController.selectedPrice.value,
                    );
                  } else {
                    variationController.clearVariation();
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppSizes.spaceBtwItems * 1.5),
          if (selectedSize.isNotEmpty)
            TRoundedContainer(
              padding: const EdgeInsets.all(AppSizes.md),
              backgroundColor: dark ? AppColors.darkerGrey : AppColors.grey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Taille sélectionnée : $selectedSize',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: [
                      const Text('Prix : ',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
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
