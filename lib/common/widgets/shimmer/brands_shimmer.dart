import 'package:caferesto/common/widgets/layouts/grid_layout.dart';
import 'package:caferesto/common/widgets/products/product_cards/widgets/rounded_container.dart';
import 'package:caferesto/common/widgets/shimmer/shimmer_effect.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

class TbrandsShimmer extends StatelessWidget {
  const TbrandsShimmer({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;
        final mainAxisExtent = constraints.maxWidth < 400 ? 90.0 : 80.0;

        return GridLayout(
          itemCount: itemCount,
          crossAxisCount: crossAxisCount,
          mainAxisExtent: mainAxisExtent,
          itemBuilder: (_, __) => TRoundedContainer(
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      /// Nom de l'établissement
                      TShimmerEffect(width: 120, height: 16),
                      const SizedBox(height: 2),

                      /// Nombre de produits
                      TShimmerEffect(width: 80, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
