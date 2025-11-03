import 'package:caferesto/common/widgets/appbar/appbar.dart';
import 'package:caferesto/common/widgets/brands/brand_card.dart';
import 'package:caferesto/common/widgets/layouts/grid_layout.dart';
import 'package:caferesto/common/widgets/texts/section_heading.dart';
import 'package:caferesto/features/shop/controllers/brand_controller.dart';
import 'package:caferesto/features/shop/controllers/etablissement_controller.dart';
import 'package:caferesto/features/shop/screens/brand/brand_products.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/shimmer/brands_shimmer.dart';

class AllBrandsScreen extends StatelessWidget {
  const AllBrandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final etablissementController = EtablissementController.instance;
    return Scaffold(
        appBar: TAppBar(
          title: Text("Marques"),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(AppSizes.defaultSpace),
            child: Column(
              children: [
                /// En tete
                TSectionHeading(
                  title: 'Marques',
                  showActionButton: false,
                ),
                SizedBox(
                  height: AppSizes.spaceBtwItems,
                ),

                /// Etablissements  Grid
                Obx(() {
                  if (etablissementController.isLoading.value) {
                    return const TbrandsShimmer();
                  }

                  if (etablissementController.allEtablissements.isEmpty) {
                    return Center(
                        child: Text('Aucune marque trouvée',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .apply(color: Colors.white)));
                  }
                  return GridLayout(
                      itemCount:
                          etablissementController.allEtablissements.length,
                      mainAxisExtent: 80,
                      itemBuilder: (_, index) {
                        final brand =
                            etablissementController.allEtablissements[index];
                        return BrandCard(
                            showBorder: true,
                            brand: brand,
                            onTap: () =>
                                Get.to(() => BrandProducts(brand: brand)));
                      });
                }),
              ],
            ),
          ),
        ));
  }
}
