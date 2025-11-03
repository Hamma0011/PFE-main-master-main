import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';

import '../../../utils/constants/sizes.dart';

class TSectionHeading extends StatelessWidget {
  const TSectionHeading(
      {super.key,
      required this.title,
      this.showActionButton = false,
      this.buttonTitle = 'Voir tout',
      this.onPressed,
      this.padding,
      this.whiteTextColor = false});

  final String title;
  final bool showActionButton;
  final bool whiteTextColor;
  final String buttonTitle;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(horizontal: AppSizes.defaultSpace),
      child: SizedBox(
        width: double.infinity, // Contrainte de largeur
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                    color: whiteTextColor
                        ? Colors.white
                        : dark
                            ? AppColors.white
                            : AppColors.eerieBlack),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showActionButton)
              TextButton(
                onPressed: onPressed,
                child: Text(buttonTitle),
              ),
          ],
        ),
      ),
    );
  }
}
