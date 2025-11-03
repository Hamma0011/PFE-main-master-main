import 'package:flutter/material.dart';

import '../../../utils/constants/enums.dart';

class BrandTitleText extends StatelessWidget {
  const BrandTitleText({
    super.key,
    this.color,
    this.textAlign = TextAlign.start,
    required this.title,
    this.maxLines = 1,
    this.brandTextSize = TexAppSizes.small,
  });

  final Color? color;
  final TextAlign? textAlign;
  final String title;
  final int maxLines;
  final TexAppSizes brandTextSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: textAlign,
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines,
      style: brandTextSize == TexAppSizes.small
          ? Theme.of(context).textTheme.labelMedium?.apply(color: color)
          : brandTextSize == TexAppSizes.medium
              ? Theme.of(context).textTheme.bodyLarge?.apply(color: color)
              : brandTextSize == TexAppSizes.large
                  ? Theme.of(context).textTheme.titleLarge?.apply(color: color)
                  : Theme.of(context).textTheme.bodyMedium?.apply(color: color),
    );
  }
}
