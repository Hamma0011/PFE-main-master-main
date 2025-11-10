import 'package:caferesto/common/widgets/shimmer/shimmer_effect.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';

class THorizontalProductShimmer extends StatelessWidget {
  const THorizontalProductShimmer(
      {super.key, this.itemCount = 4, this.cardHeight = 120});
  final int itemCount;
  final double cardHeight;
  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final defaultCardWidth = screenWidth > 1200
        ? 380.0
        : screenWidth > 900
            ? 340.0
            : screenWidth > 600
                ? 300.0
                : 280.0;

    return Container(
        margin: const EdgeInsets.only(bottom: AppSizes.spaceBtwSections),
        height: cardHeight,
        child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSizes.spaceBtwItems),
            itemBuilder: (_, __) => Container(
                  width: defaultCardWidth,
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
                  child: Row(
                    children: [
                      /// Thumbnail Section
                      TShimmerEffect(
                        width: 120,
                        height: 120,
                        radius: 8,
                      ),

                      /// Details Section
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              /// Top Section - Brand and Title
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// Brand
                                  TShimmerEffect(width: 100, height: 12),
                                  const SizedBox(height: AppSizes.spaceBtwItems / 2),

                                  /// Title
                                  TShimmerEffect(width: 120, height: 14),
                                  const SizedBox(height: 4),
                                  TShimmerEffect(width: 90, height: 14),
                                ],
                              ),

                              /// Bottom Section - Price and Add to Cart
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  /// Price
                                  TShimmerEffect(width: 60, height: 16),
                                  /// Cart button
                                  TShimmerEffect(width: 40, height: 40, radius: 8),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )));
  }
}
