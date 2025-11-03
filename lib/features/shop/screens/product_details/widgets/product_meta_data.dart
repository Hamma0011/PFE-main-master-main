import 'package:caferesto/common/widgets/texts/brand_title_text_with_verified_icon.dart';
import 'package:caferesto/common/widgets/texts/product_title_text.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

import '../../../../../common/widgets/products/product_cards/widgets/rounded_container.dart';
import '../../../../../common/widgets/texts/product_price_text.dart';
import '../../../../../utils/constants/enums.dart';
import '../../../controllers/product/produit_controller.dart';
import '../../../models/produit_model.dart';

class TProductMetaData extends StatelessWidget {
  const TProductMetaData({super.key, required this.product});

  final ProduitModel product;

  @override
  Widget build(BuildContext context) {
    final controller = ProduitController.instance;
    final salePercentage =
        controller.calculateSalePercentage(product.price, product.salePrice);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Price and sale price
        Row(
          children: [
            /// Sale tag
            salePercentage != null
                ? TRoundedContainer(
                    radius: AppSizes.sm,
                    backgroundColor:
                        AppColors.secondary.withAlpha((255 * 0.8).toInt()),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.xs, horizontal: AppSizes.sm),
                    child: Text(
                      'Remise : $salePercentage% !',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge!
                          .apply(color: AppColors.black),
                    ))
                : SizedBox(),
            const SizedBox(width: AppSizes.spaceBtwItems),

            /// Price
            if (product.productType == 'single' && product.salePrice > 0)
              Text(
                '${product.price} DT',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .apply(decoration: TextDecoration.lineThrough),
              ),
            if (product.productType == 'single' && product.salePrice > 0)
              const SizedBox(width: AppSizes.spaceBtwItems),
            ProductPriceText(
              price: controller.getProductPrice(product),
              isLarge: true,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.spaceBtwItems / 2),

        /// Title

        TProductTitleText(title: product.name),
        const SizedBox(height: AppSizes.spaceBtwItems / 2),

        /// Stock status
        Row(
          children: [
            const TProductTitleText(title: "Statut :"),
            const SizedBox(width: AppSizes.spaceBtwItems),
            Text(controller.getProductStockStatus(product.stockQuantity),
                style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: AppSizes.spaceBtwItems / 2),

        /// Brand
        /// Brand Row inside TProductMetaData
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// Safe Circular Image with fallback and layout-safe wrapping
            if (product.etablissementId !=
                null /*&& product.etablissementId!.image.isNotEmpty*/)
              LayoutBuilder(
                builder: (context, constraints) {
                  return ClipOval(
                    child: Image.network(
                      product.etablissement?.imageUrl ?? '', //.image,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 32,
                          height: 32,
                          color: Colors.grey.shade300,
                          child: Icon(Icons.image_not_supported, size: 16),
                        );
                      },
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return SizedBox(
                          width: 32,
                          height: 32,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              )
            else

              /// Fallback when no image is present
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                ),
                child: const Icon(Icons.image_not_supported,
                    size: 16, color: Colors.white),
              ),

            const SizedBox(width: AppSizes.spaceBtwItems),

            /// Brand title with optional verified icon
            Expanded(
              child: BrandTitleWithVerifiedIcon(
                title: product.etablissement?.name ?? 'Inconnu',
                brandTextSize: TexAppSizes.medium,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
