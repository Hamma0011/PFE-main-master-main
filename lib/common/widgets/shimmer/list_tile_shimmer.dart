import 'package:caferesto/common/widgets/shimmer/shimmer_effect.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

class TListTileShimmer extends StatelessWidget {
  const TListTileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            TShimmerEffect(
              width: 50,
              height: 50,
              radius: 50,
            ),
            SizedBox(width: AppSizes.spaceBtwItems),
            Column(
              children: [
                TShimmerEffect(
                  width: 100,
                  height: 15,
                ),
                SizedBox(width: AppSizes.spaceBtwItems),
                TShimmerEffect(
                  width: 80,
                  height: 12,
                ),
              ],
            )
          ],
        )
      ],
    );
  }
}
