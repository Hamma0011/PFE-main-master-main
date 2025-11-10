import 'package:caferesto/common/widgets/layouts/grid_layout.dart';
import 'package:caferesto/common/widgets/shimmer/shimmer_effect.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';

class TVerticalProductShimmer extends StatelessWidget {
  const TVerticalProductShimmer({super.key, this.itemCount = 4});
  final int itemCount;
  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return GridLayout(
        itemCount: itemCount,
        itemBuilder: (_, __) => Container(
            width: 170,
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: dark ? AppColors.eerieBlack : AppColors.white,
              borderRadius: BorderRadius.circular(AppSizes.defaultSpace),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Image
                TShimmerEffect(
                  width: double.infinity,
                  height: 150,
                  radius: 24,
                ),
                const SizedBox(height: AppSizes.spaceBtwItems / 2),

                /// Product info
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Brand
                      TShimmerEffect(width: 80, height: 12),
                      const SizedBox(height: AppSizes.spaceBtwItems / 2),

                      /// Title
                      TShimmerEffect(width: 140, height: 14),
                    ],
                  ),
                ),

                /// Price and cart button
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// Price
                      TShimmerEffect(width: 60, height: 16),
                      /// Cart button
                      TShimmerEffect(width: 40, height: 40, radius: 8),
                    ],
                  ),
                ),
              ],
            )));
  }
}
