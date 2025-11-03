import 'package:caferesto/common/widgets/images/circular_image.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:flutter/material.dart';

import '../../../utils/constants/sizes.dart';

class TVerticalImageText extends StatelessWidget {
  const TVerticalImageText({
    super.key,
    required this.image,
    required this.title,
    this.textColor = AppColors.white,
    // this.backgroundColor,
    this.onTap,
    this.isNetworkImage = true,
  });

  final String image, title;
  final Color textColor;
  // final Color? backgroundColor;
  final void Function()? onTap;
  final bool isNetworkImage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: AppSizes.spaceBtwItems),
        child: Column(
          children: [
            /// Icone circulaire
            CircularImage(
              image: image,
              fit: BoxFit.fitWidth,
              isNetworkImage: isNetworkImage,
            ),

            /// Texte
            const SizedBox(height: AppSizes.spaceBtwItems / 2),
            SizedBox(
              width: 80,
              child: Center(
                child: Text(
                  textAlign: TextAlign.center,
                  title,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: textColor,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
