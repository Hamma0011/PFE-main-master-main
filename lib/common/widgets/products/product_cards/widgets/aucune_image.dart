import 'package:flutter/material.dart';

import '../../../../../utils/constants/sizes.dart';

class AucuneImageWidget extends StatelessWidget {
  const AucuneImageWidget(
      {super.key,
      this.width = double.infinity,
      this.height = double.infinity,
      this.iconSize = 24,
      this.textSize = 10});
  final double width;
  final double height;
  final double iconSize;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(AppSizes.productImageRadius),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fastfood, color: Colors.grey, size: iconSize),
          SizedBox(height: 4),
          Text(
            'Aucune image',
            style: TextStyle(color: Colors.grey, fontSize: textSize),
          ),
        ],
      ),
    );
  }
}
