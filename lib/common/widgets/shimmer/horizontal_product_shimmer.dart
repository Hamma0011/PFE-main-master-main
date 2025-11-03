import 'package:caferesto/common/widgets/shimmer/shimmer_effect.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

class THorizontalProductShimmer extends StatelessWidget {
  const THorizontalProductShimmer(
      {super.key, this.itemCount = 4, this.cardHeight = 120});
  final int itemCount;
  final double cardHeight;
  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(bottom: AppSizes.spaceBtwSections),
        height: cardHeight,
        child: ListView.separated(
            itemCount: itemCount,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSizes.spaceBtwItems),
            itemBuilder: (_, __) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TShimmerEffect(width: 120, height: cardHeight),
                    SizedBox(height: AppSizes.spaceBtwItems),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: AppSizes.spaceBtwItems / 2),
                      ],
                    )
                  ],
                )));
  }
}
