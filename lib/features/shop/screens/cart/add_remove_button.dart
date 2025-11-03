import 'package:caferesto/common/widgets/icons/t_circular_icon.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class TProductQuantityWithAddRemoveButton extends StatelessWidget {
  const TProductQuantityWithAddRemoveButton({
    super.key,
    required this.quantity,
    this.add,
    this.remove,
  });

  final int quantity;
  final VoidCallback? add, remove;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TCircularIcon(
          icon: Iconsax.minus,
          width: 32,
          height: 32,
          size: AppSizes.md,
          color: THelperFunctions.isDarkMode(context)
              ? AppColors.white
              : AppColors.black,
          backgroundColor: THelperFunctions.isDarkMode(context)
              ? AppColors.darkerGrey
              : AppColors.light,
          onPressed: remove,
        ),
        const SizedBox(
          width: AppSizes.spaceBtwItems,
        ),
        Text(
          quantity.toString(),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(
          width: AppSizes.spaceBtwItems,
        ),
        TCircularIcon(
            icon: Iconsax.add,
            width: 32,
            height: 32,
            size: AppSizes.md,
            color: AppColors.white,
            backgroundColor: AppColors.primary,
            onPressed: add),
      ],
    );
  }
}
