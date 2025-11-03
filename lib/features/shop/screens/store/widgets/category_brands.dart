import 'package:caferesto/common/widgets/brands/brand_show_case.dart';
import 'package:caferesto/features/shop/controllers/brand_controller.dart';
import 'package:caferesto/features/shop/controllers/etablissement_controller.dart';
import 'package:caferesto/features/shop/models/category_model.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/helpers/cloud_helper_functions.dart';
import 'package:flutter/material.dart';

import '../../../../../common/widgets/shimmer/boxes_shimmer.dart';
import '../../../../../common/widgets/shimmer/list_tile_shimmer.dart';

class CategoryBrands extends StatelessWidget {
  const CategoryBrands({super.key, required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    final controller = EtablissementController.instance;
    return FutureBuilder(
        future: controller.getBrandsForCategory(category.id),
        builder: (context, snapshot) {
          /// Handle loader , No record, Or Error Message
          const loader = Column(
            children: [
              TListTileShimmer(),
              SizedBox(height: AppSizes.spaceBtwItems),
              TBoxesShimmer(),
              SizedBox(height: AppSizes.spaceBtwItems),
            ],
          );
          final widget = TCloudHelperFunctions.checkMultiRecordState(
              snapshot: snapshot, loader: loader);
          if (widget != null) return widget;

          /// Records found
          final brands = snapshot.data!;
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: brands.length,
            itemBuilder: (_, index) {
              final brand = brands[index];
              return FutureBuilder(
                  future: controller.getProduitsEtablissement(
                    etablissementId: brand.id!, /*limit: 3*/
                  ),
                  builder: (context, snapshot) {
                    /// Handle loader , No record, Or Error Message
                    final widget = TCloudHelperFunctions.checkMultiRecordState(
                        snapshot: snapshot, loader: loader);
                    if (widget != null) return widget;

                    /// Records found
                    final products = snapshot.data!;
                    return BrandShowcase(
                        images: products.map((e) => e.imageUrl).toList(),
                        brand: brand);
                  });
            },
          );
        });
  }
}
