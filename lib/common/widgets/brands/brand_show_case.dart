import 'package:cached_network_image/cached_network_image.dart';
import 'package:caferesto/features/shop/models/etablissement_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/colors.dart';
import '../../../features/shop/screens/brand/brand_products.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../products/product_cards/widgets/rounded_container.dart';
import '../shimmer/shimmer_effect.dart';
import 'brand_card.dart';

class BrandShowcase extends StatelessWidget {
  const BrandShowcase({super.key, required this.images, required this.brand});

  final Etablissement brand;
  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.to(() => BrandProducts(brand: brand)),
      child: TRoundedContainer(
        showBorder: true,
        borderColor: AppColors.darkGrey,
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.all(AppSizes.md),
        margin: const EdgeInsets.only(bottom: AppSizes.spaceBtwItems),
        child: Column(
          children: [
            /// Etablissement ave nombre de produits
            BrandCard(showBorder: false, brand: brand),
            const SizedBox(height: AppSizes.spaceBtwItems),

            /// Top 3 images du produits de l'etablissement
            Row(
              children: images
                  .map((image) => brandTopProductImageWidget(image, context))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget brandTopProductImageWidget(String image, context) {
    return Expanded(
      child: TRoundedContainer(
        height: 100,
        backgroundColor: THelperFunctions.isDarkMode(context)
            ? AppColors.darkerGrey
            : AppColors.light,
        margin: const EdgeInsets.only(right: AppSizes.sm),
        padding: const EdgeInsets.all(AppSizes.md),
        child: CachedNetworkImage(
          fit: BoxFit.contain,
          imageUrl: image,
          progressIndicatorBuilder: (context, url, downloadProgress) =>
              const TShimmerEffect(width: 100, height: 100),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
    );
  }
}
