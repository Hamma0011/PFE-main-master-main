import 'package:caferesto/common/widgets/shimmer/shimmer_effect.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

class TCategoryShimmer extends StatelessWidget {
  const TCategoryShimmer({
    super.key,
    this.itemCount = 6,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: itemCount,
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppSizes.spaceBtwItems),
        itemBuilder: (_, index) {
          return Padding(
            padding: const EdgeInsets.only(left: AppSizes.spaceBtwItems),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TShimmerEffect(width: 70, height: 70, radius: 100),
                SizedBox(height: AppSizes.spaceBtwItems / 2),
                TShimmerEffect(width: 60, height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
