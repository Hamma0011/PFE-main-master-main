import 'package:cached_network_image/cached_network_image.dart';
import 'package:caferesto/common/widgets/appbar/appbar.dart';
import 'package:caferesto/common/widgets/custom_shapes/curved_edges/curved_edges_widget.dart';
import 'package:caferesto/common/widgets/images/t_rounded_image.dart';
import 'package:caferesto/common/widgets/products/favorite_icon/favorite_icon.dart';
import 'package:caferesto/features/shop/controllers/product/images_controller.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../utils/helpers/helper_functions.dart';
import '../../../models/produit_model.dart';

class TProductImageSlider extends StatelessWidget {
  const TProductImageSlider({
    super.key,
    required this.product,
  });

  final ProduitModel product;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    final controller = Get.put(ImagesController());
    final images = controller.getAllProductImages(product);
    return TCurvedEdgeWidget(
        child: Container(
            color: dark ? AppColors.darkGrey : AppColors.light,
            child: Stack(
              children: [
                /// Main Large Image
                SizedBox(
                    height: 400,
                    child: Padding(
                      padding: EdgeInsets.all(AppSizes.productImageRadius * 2),
                      child: Center(child: Obx(() {
                        final image = controller.selectedProductImage.value;

                        return GestureDetector(
                          onTap: () {
                            controller.showEnlargedImage(image);
                          },
                          child: CachedNetworkImage(
                              imageUrl: image,
                              progressIndicatorBuilder:
                                  (_, __, downloadProgress) => Center(
                                        child: CircularProgressIndicator(
                                          value: downloadProgress.progress,
                                          color: AppColors.primary,
                                        ),
                                      ),
                              errorWidget: (_, __, ___) =>
                                  const Icon(Iconsax.close_circle)),
                        );
                      })),
                    )),

                /// Image slider
                Positioned(
                  right: 0,
                  bottom: 30,
                  left: AppSizes.defaultSpace,
                  child: SizedBox(
                    height: 80,
                    child: ListView.separated(
                      itemCount: images.length,
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemBuilder: (_, index) => Obx(() {
                        final imageSelected =
                            controller.selectedProductImage.value ==
                                images[index];
                        return TRoundedImage(
                          width: 80,
                          isNetworkImage: true,
                          imageUrl: images[index],
                          padding: const EdgeInsets.all(AppSizes.sm),
                          backgroundColor:
                              dark ? AppColors.dark : AppColors.white,
                          onPressed: () {
                            controller.selectedProductImage.value =
                                images[index];
                          },
                          border: Border.all(
                              color: imageSelected
                                  ? AppColors.primary
                                  : Colors.transparent),
                        );
                      }),
                      separatorBuilder: (_, __) => const SizedBox(
                        width: AppSizes.spaceBtwItems,
                      ),
                    ),
                  ),
                ),

                /// Appbar icons
                TAppBar(
                  actions: [
                    /// Favorite Icon
                    FavoriteIcon(
                      productId: product.id,
                    ),
                    const SizedBox(width: AppSizes.defaultSpace),
                  ],
                )
              ],
            )));
  }
}
