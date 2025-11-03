import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/icons/t_circular_icon.dart';
import '../../../../../utils/constants/colors.dart';

class TRatingAndShare extends StatelessWidget {
  const TRatingAndShare({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Iconsax.star5, color: Colors.amber, size: 24),
            const SizedBox(width: AppSizes.spaceBtwItems / 2),
            Text.rich(TextSpan(
              children: [
                TextSpan(
                  text: '4.5',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const TextSpan(
                  text: ' (100)',
                )
              ],
            )),
          ],
        ),

        /// Share button
        IconButton(
          onPressed: () {},
          icon: TCircularIcon(
            icon: Iconsax.share,
            color: AppColors.primary,
            size: AppSizes.iconMd,
          ),
        )
      ],
    );
  }
}
