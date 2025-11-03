import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/sizes.dart';
import 'brand_title_text.dart';

class BrandTitleWithVerifiedIcon extends StatelessWidget {
  const BrandTitleWithVerifiedIcon({
    super.key,
    required this.title,
    this.maxLines = 1,
    this.textColor,
    this.iconColor = AppColors.primary,
    this.textAlign = TextAlign.start,
    this.brandTextSize = TexAppSizes.small,
  });

  final String title;
  final int maxLines;
  final Color? textColor, iconColor;
  final TextAlign? textAlign;
  final TexAppSizes brandTextSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BrandTitleText(
          title: title,
          textAlign: textAlign,
          maxLines: maxLines,
          color: textColor,
          brandTextSize: brandTextSize,
        ),
        const SizedBox(
          width: AppSizes.xs,
        ),
        Icon(
          Iconsax.verify5,
          size: AppSizes.iconXs,
          color: iconColor,
        ),
      ],
    );
  }
}
