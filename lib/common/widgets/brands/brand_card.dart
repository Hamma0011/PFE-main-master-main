import 'package:caferesto/features/shop/models/etablissement_model.dart';
import 'package:flutter/material.dart';

import '../../../utils/constants/enums.dart';
import '../../../utils/constants/sizes.dart';
import '../images/circular_image.dart';
import '../products/product_cards/widgets/rounded_container.dart';
import '../texts/brand_title_text_with_verified_icon.dart';

class BrandCard extends StatelessWidget {
  const BrandCard({
    super.key,
    required this.showBorder,
    this.onTap,
    required this.brand,
  });

  final Etablissement brand;
  final bool showBorder;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TRoundedContainer(
        padding: const EdgeInsets.all(AppSizes.sm),
        showBorder: showBorder,
        backgroundColor: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// Icone
            CircularImage(
              isNetworkImage: true,
              image: brand.imageUrl ?? '',
              backgroundColor: Colors.transparent,
              width: 50,
              height: 50,
              padding: 2,
              // overlayColor: THelperFunctions.isDarkMode(context)
              //     ? AppColors.white
              //     : AppColors.black,
            ),
            const SizedBox(width: AppSizes.spaceBtwItems / 2),

            /// Texte
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Use smaller text size on small screens to prevent overflow
                      final screenWidth = MediaQuery.of(context).size.width;
                      final textSize = screenWidth < 400
                          ? TexAppSizes.small
                          : screenWidth < 600
                              ? TexAppSizes.medium
                              : TexAppSizes.large;

                      return SizedBox(
                        width: constraints.maxWidth,
                        child: BrandTitleWithVerifiedIcon(
                          title: brand.name,
                          brandTextSize: textSize,
                          maxLines: 2,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  // Nombre de Produits
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final nbProduits = brand.nbProduits ?? 0;
                      final nbProduitsInt = nbProduits.toInt();
                      return SizedBox(
                        width: constraints.maxWidth,
                        child: Text(
                          '$nbProduitsInt produits',
                          style: Theme.of(context).textTheme.labelMedium,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
