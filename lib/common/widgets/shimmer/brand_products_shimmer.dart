import 'package:caferesto/common/widgets/layouts/grid_layout.dart';
import 'package:caferesto/common/widgets/shimmer/shimmer_effect.dart';
import 'package:caferesto/common/widgets/products/product_cards/widgets/rounded_container.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

/// Shimmer de chargement pour la page BrandProducts
/// Correspond à la structure: BrandCard + Filtres de catégorie + Grille de produits
class TBrandProductsShimmer extends StatelessWidget {
  const TBrandProductsShimmer({super.key, this.itemCount = 4});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSizes.defaultSpace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// BrandCard Shimmer
          TRoundedContainer(
            padding: const EdgeInsets.all(AppSizes.sm),
            showBorder: true,
            backgroundColor: Colors.transparent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// Image circulaire shimmer
                TShimmerEffect(width: 50, height: 50, radius: 50),
                const SizedBox(width: AppSizes.spaceBtwItems / 2),
                /// Texte shimmer
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TShimmerEffect(width: 150, height: 18),
                      const SizedBox(height: AppSizes.spaceBtwItems / 2),
                      TShimmerEffect(width: 100, height: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSizes.spaceBtwSections),

          /// Filtres de catégorie Shimmer (barre horizontale de chips)
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, __) => TShimmerEffect(
                width: 80,
                height: 32,
                radius: 20,
              ),
            ),
          ),
          SizedBox(height: AppSizes.spaceBtwSections),

          /// Grille de produits Shimmer
          GridLayout(
            itemCount: itemCount,
            itemBuilder: (_, __) => const SizedBox(
              width: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Image
                  TShimmerEffect(width: 180, height: 180),
                  SizedBox(height: AppSizes.spaceBtwItems),

                  /// Title
                  TShimmerEffect(width: 160, height: 15),
                  SizedBox(height: AppSizes.spaceBtwItems / 2),
                  TShimmerEffect(width: 110, height: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

