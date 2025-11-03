import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/device/device_utility.dart';
import '../../../utils/helpers/helper_functions.dart';

class TAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TAppBar(
      {super.key,
      this.title,
      this.showBackArrow = true,
      this.leadingIcon,
      this.actions,
      this.leadingOnPressed,
      this.customBackNavigation,
      this.doubleAppBarHeight = false,
      this.bottomWidget,
      this.centerTitle = true});

  final Widget? title;
  final PreferredSizeWidget? bottomWidget;
  final bool showBackArrow;
  final IconData? leadingIcon;
  final List<Widget>? actions;
  final VoidCallback? leadingOnPressed;
  final VoidCallback? customBackNavigation;
  final bool doubleAppBarHeight;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.md),
      child: AppBar(
        bottom: bottomWidget,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: showBackArrow
            ? IconButton(
                onPressed: () {
                  if (customBackNavigation != null) {
                    customBackNavigation!();
                  } else {
                    Get.back();
                  }
                },
                icon: Icon(
                  Iconsax.arrow_left,
                  color: dark ? AppColors.white : AppColors.dark,
                ),
              )
            : leadingIcon != null
                ? IconButton(
                    onPressed: leadingOnPressed, icon: Icon(leadingIcon))
                : null,
        title: title,
        actions: actions,
        centerTitle: centerTitle,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
      doubleAppBarHeight == false ? TDeviceUtils.getAppBarHeight() : 140);
}
