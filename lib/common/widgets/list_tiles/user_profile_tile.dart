import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../features/personalization/controllers/user_controller.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/image_strings.dart';
import '../images/circular_image.dart';
import 'package:get/get.dart';

class TUserProfileTile extends StatelessWidget {
  const TUserProfileTile({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final controller = UserController.instance;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Obx(
        () => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            CircularImage(
              isNetworkImage: true,
              image: controller.user.value.profileImageUrl?.isNotEmpty == true
                  ? controller.user.value.profileImageUrl!
                  : controller.user.value.sex == 'Homme'
                      ? TImages.userMale
                      : TImages.userFemale,
              width: 80,
              height: 80,
            ),
            const SizedBox(width: 16),

            // infos utilisateur
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom complet
                  Text(
                    controller.user.value.fullName,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall!
                        .apply(color: AppColors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Email
                  Text(
                    controller.user.value.email,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .apply(color: AppColors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Bouton modifier
            IconButton(
              onPressed: onPressed,
              icon: const Icon(Iconsax.edit, color: AppColors.white),
            ),
          ],
        ),
      ),
    );
  }
}
