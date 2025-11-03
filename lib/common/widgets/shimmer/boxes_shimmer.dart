import 'package:caferesto/common/widgets/shimmer/shimmer_effect.dart';
import 'package:flutter/material.dart';

import '../../../utils/constants/sizes.dart';

class TBoxesShimmer extends StatelessWidget {
  const TBoxesShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(children: [
      Row(
        children: [
          Expanded(child: TShimmerEffect(width: 150, height: 110)),
          SizedBox(width: AppSizes.spaceBtwItems),
          Expanded(child: TShimmerEffect(width: 150, height: 110)),
          SizedBox(width: AppSizes.spaceBtwItems),
          Expanded(child: TShimmerEffect(width: 150, height: 110)),
        ],
      ),
    ]);
  }
}
