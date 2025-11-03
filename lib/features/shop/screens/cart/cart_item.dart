import 'package:caferesto/common/widgets/images/t_rounded_image.dart';
import 'package:caferesto/common/widgets/texts/brand_title_text_with_verified_icon.dart';
import 'package:caferesto/common/widgets/texts/product_title_text.dart';
import 'package:caferesto/features/shop/models/cart_item_model.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';

class TCartItem extends StatelessWidget {
  const TCartItem({
    super.key,
    required this.cartItem,
  });

  final CartItemModel cartItem;

  @override
  Widget build(BuildContext context) {
    final hasImage = cartItem.image != null && cartItem.image!.isNotEmpty;
    final isDark = THelperFunctions.isDarkMode(context);

    return Row(
      children: [
        // Product image or placeholder
        if (hasImage)
          TRoundedImage(
            imageUrl: cartItem.image!,
            width: 60,
            height: 60,
            isNetworkImage: true,
            padding: const EdgeInsets.all(AppSizes.sm),
            backgroundColor: isDark ? AppColors.darkerGrey : AppColors.light,
          )
        else
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.image_not_supported,
              color: Colors.grey,
              size: 30,
            ),
          ),

        const SizedBox(width: AppSizes.spaceBtwItems),

        // Product details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrandTitleWithVerifiedIcon(title: cartItem.brandName ?? ''),
              const SizedBox(height: 4),
              TProductTitleText(
                title: cartItem.title,
                maxLines: 2,
              ),
              const SizedBox(height: 4),

              // Variation attributes
              if (cartItem.selectedVariation != null &&
                  cartItem.selectedVariation!.isNotEmpty)
                Text(
                  cartItem.selectedVariation!.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join(' • '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 4),

              // Unit price
              Text(
                '${cartItem.price.toStringAsFixed(2)} DT',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
