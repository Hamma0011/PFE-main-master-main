import 'package:caferesto/common/widgets/layouts/grid_layout.dart';
import 'package:caferesto/common/widgets/shimmer/shimmer_effect.dart';
import 'package:flutter/material.dart';

class TbrandsShimmer extends StatelessWidget {
  const TbrandsShimmer({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridLayout(
      mainAxisExtent: 80,
      itemCount: itemCount, itemBuilder: (_,__) => const TShimmerEffect(width: 300, height: 80));
  }
}