import 'package:caferesto/common/widgets/images/t_rounded_image.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';

class CartItemImage extends StatelessWidget {
  const CartItemImage({
    super.key,
    required this.imageUrl,
    this.width = 60,
    this.height = 60,
  });

  final String? imageUrl;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    if (!hasImage) {
      // Reuse the placeholder from product_detail
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? [Colors.grey.shade800, Colors.grey.shade900]
                : [Colors.grey.shade100, Colors.grey.shade200],
          ),
          borderRadius: BorderRadius.circular(AppSizes.productImageRadius),
        ),
        child: Icon(
          Icons.photo_camera_rounded,
          size: width * 0.4,
          color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      );
    }

    return TRoundedImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      isNetworkImage: true,
      padding: const EdgeInsets.all(AppSizes.sm),
      backgroundColor: dark ? AppColors.darkerGrey : AppColors.light,
    );
  }
}
