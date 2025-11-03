import 'package:caferesto/common/widgets/products/ratings/rating_indicator.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/constants/image_strings.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:readmore/readmore.dart';

import '../../../../../common/widgets/products/product_cards/widgets/rounded_container.dart';
import '../../../../../utils/helpers/helper_functions.dart';

class UserReviewCard extends StatelessWidget {
  const UserReviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundImage: AssetImage(TImages.userProfileImage1),
                ),
                const SizedBox(
                  width: AppSizes.spaceBtwItems,
                ),
                Text(
                  'Ali Salem',
                  style: Theme.of(context).textTheme.titleLarge,
                )
              ],
            ),
            IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert))
          ],
        ),
        const SizedBox(
          height: AppSizes.spaceBtwItems,
        ),

        /// Review
        Row(
          children: [
            TRatingBarIndicator(rating: 4),
            const SizedBox(
              width: AppSizes.spaceBtwItems,
            ),
            Text(
              '01 Oct 2023',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(
          height: AppSizes.spaceBtwItems,
        ),
        const ReadMoreText(
          'Une description du produit qui contient plusieurs lignes. ligne 1 ligne 2 ligne 3 ligne 12 packages have newer versions incompatible with dependency constraints.',
          trimLines: 2,
          trimMode: TrimMode.Line,
          trimCollapsedText: 'Voir plus',
          trimExpandedText: 'Moins',
          moreStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary),
          lessStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary),
        ),
        const SizedBox(
          height: AppSizes.spaceBtwItems,
        ),

        // Company Review
        TRoundedContainer(
          backgroundColor: dark ? AppColors.darkerGrey : AppColors.grey,
          child: Padding(
            padding: EdgeInsets.all(AppSizes.md),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Ali Store",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      "02 Nov, 2023",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(
                  height: AppSizes.spaceBtwItems,
                ),
                const ReadMoreText(
                  'Une description du produit qui contient plusieurs lignes. ligne 1 ligne 2 ligne 3 ligne 12 packages have newer versions incompatible with dependency constraints.',
                  trimLines: 2,
                  trimMode: TrimMode.Line,
                  trimCollapsedText: 'Voir plus',
                  trimExpandedText: 'Moins',
                  moreStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                  lessStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: AppSizes.spaceBtwSections,
        ),
      ],
    );
  }
}
