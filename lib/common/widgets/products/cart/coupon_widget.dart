// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../product_cards/widgets/rounded_container.dart';

class TCouponCode extends StatelessWidget {
  const TCouponCode({super.key, required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return TRoundedContainer(
      showBorder: true,
      backgroundColor: dark ? AppColors.dark : AppColors.white,
      padding: const EdgeInsets.only(
        top: AppSizes.sm,
        bottom: AppSizes.sm,
        right: AppSizes.sm,
        left: AppSizes.md,
      ),
      child: Row(
        children: [
          Flexible(
            child: TextFormField(
              decoration: const InputDecoration(
                hintText: "Avez-vous un code promo ? Entrez ici",
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
            ),
          ),

          /// Bouton
          SizedBox(
            width: 80,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                foregroundColor: dark
                    ? AppColors.white.withAlpha(128)
                    : AppColors.dark.withAlpha(128),
                backgroundColor: Colors.grey.withAlpha((255 * 0.2).toInt()),
                side: BorderSide(
                  color: Colors.grey.withAlpha((255 * 0.1).toInt()),
                ),
              ),
              child: Text('Appliquer'),
            ),
          ),
        ],
      ),
    );
  }
}
