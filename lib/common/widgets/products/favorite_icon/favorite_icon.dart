import 'package:caferesto/common/widgets/icons/t_circular_icon.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../features/shop/controllers/product/favorites_controller.dart';

class FavoriteIcon extends StatelessWidget {
  const FavoriteIcon({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final controller = FavoritesController.instance;
    return Obx(() => TCircularIcon(
        icon:
            controller.isFavourite(productId) ? Iconsax.heart5 : Iconsax.heart,
        color: controller.isFavourite(productId) ? AppColors.error : null,
        onPressed: () => controller.toggleFavoriteProduct(productId)));
  }
}
