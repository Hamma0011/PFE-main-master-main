import 'package:caferesto/common/widgets/images/t_rounded_image.dart';
import 'package:caferesto/common/widgets/texts/brand_title_text_with_verified_icon.dart';
import 'package:caferesto/common/widgets/texts/product_title_text.dart';
import 'package:caferesto/features/shop/controllers/product/panier_controller.dart';
import 'package:caferesto/features/shop/models/cart_item_model.dart';
import 'package:caferesto/features/shop/models/produit_model.dart';
import 'package:caferesto/features/shop/screens/product_details/widgets/product_quantity_controls.dart';
import '../../product_details/product_detail.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.index,
    this.showDelete = true,
    this.showModify = true,
  });

  final CartItemModel item;
  final int index;
  final bool showDelete;
  final bool showModify;

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;
    final dark = THelperFunctions.isDarkMode(context);
    final hasImage = item.image != null && item.image!.isNotEmpty;

    final product = item.product ??
        ProduitModel.empty().copyWith(
          id: item.productId,
          name: item.title,
          imageUrl: item.image ?? '',
        );

    return Row(
      children: [
        // Image
        if (hasImage)
          TRoundedImage(
            imageUrl: item.image!,
            width: 72,
            height: 72,
            isNetworkImage: true,
            padding: const EdgeInsets.all(AppSizes.sm),
            backgroundColor: dark ? AppColors.darkerGrey : AppColors.light,
          )
        else
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          ),

        const SizedBox(width: AppSizes.spaceBtwItems),

        // Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrandTitleWithVerifiedIcon(title: item.brandName ?? ''),
              const SizedBox(height: 6),
              TProductTitleText(title: item.title, maxLines: 2),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Price and variation
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.selectedVariation != null &&
                            item.selectedVariation!.isNotEmpty)
                          Text(
                            item.selectedVariation!.entries
                                .map((e) => '${e.key}: ${e.value}')
                                .join(' • '),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          '${item.price.toStringAsFixed(2)} DT',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                        ),
                      ],
                    ),
                  ),

                  // Optional modify button (compact)
                  if (showModify &&
                      (item.product?.productType ?? '') != 'single')
                    IconButton(
                      onPressed: () {
                        if (item.product != null) {
                          Get.to(() =>
                              ProductDetailScreen(product: item.product!));
                        } else {
                          Get.to(() => ProductDetailScreen(product: product));
                        }
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Modifier',
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: AppSizes.spaceBtwItems),

        // Controls column
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ProductQuantityControls(
              product: product,
              dark: dark,
              onDecrement: () {
                if (item.quantity > 1) {
                  controller.retirerUnDuPanier(item);
                } else {
                  controller.dialogRetirerDuPanier(index);
                }
              },
              onIncrement: () => controller.ajouterUnAuPanier(item),
            ),
            const SizedBox(height: 6),
            if (showDelete)
              IconButton(
                onPressed: () => controller.dialogRetirerDuPanier(index),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'Supprimer',
              ),
          ],
        ),
      ],
    );
  }
}
