
  import 'package:flutter/material.dart';

import '../../../../../utils/constants/sizes.dart';

Widget chargementImageWidget(ImageChunkEvent loadingProgress) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(AppSizes.productImageRadius),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  }