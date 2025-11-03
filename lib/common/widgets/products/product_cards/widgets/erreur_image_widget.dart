
  import 'package:flutter/material.dart';

import '../../../../../utils/constants/sizes.dart';

Widget imageErreurWidget() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(AppSizes.productImageRadius),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.grey, size: 24),
          SizedBox(height: 4),
          Text(
            'Erreur',
            style: TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }