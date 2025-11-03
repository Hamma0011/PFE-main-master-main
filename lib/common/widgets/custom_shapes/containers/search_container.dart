import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/device/device_utility.dart';
import '../../../../utils/helpers/helper_functions.dart';

class TSearchContainer extends StatelessWidget {
  const TSearchContainer({
    super.key,
    required this.text,
    this.icon = Iconsax.search_normal,
    this.showBackground = true,
    this.showBorder = true,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSizes.defaultSpace,
    ),
    this.controller,
    this.onChanged,
    this.readOnly = false,
  });

  final String text;
  final IconData? icon;
  final bool showBackground, showBorder;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    if (controller != null) {
      return Padding(
          padding: padding,
          child: Container(
              width: TDeviceUtils.getScreenWidth(context),
              decoration: BoxDecoration(
                color: showBackground
                    ? dark
                        ? AppColors.eerieBlack
                        : AppColors.light
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
                border: showBorder ? Border.all(color: AppColors.grey) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: dark ? AppColors.darkerGrey : AppColors.grey,
                  ),
                  const SizedBox(
                    width: AppSizes.spaceBtwItems,
                  ),
                  Expanded(
                      child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    readOnly: readOnly,
                    decoration: InputDecoration(
                      hintText: text,
                      border: InputBorder.none,
                      hintStyle: Theme.of(context).textTheme.bodySmall,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ))
                ],
              )));
    }
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: Container(
          width: TDeviceUtils.getScreenWidth(context),
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: showBackground
                ? dark
                    ? AppColors.eerieBlack
                    : AppColors.light
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
            border: showBorder ? Border.all(color: AppColors.grey) : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: dark ? AppColors.darkerGrey : AppColors.grey,
              ),
              const SizedBox(width: AppSizes.spaceBtwItems),
              Expanded(
                child: Text(text,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
