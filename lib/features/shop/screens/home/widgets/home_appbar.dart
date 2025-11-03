import 'package:caferesto/features/personalization/controllers/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../common/widgets/products/cart/cart_menu_icon.dart';
import '../../../../../common/widgets/shimmer/shimmer_effect.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../../../utils/constants/text_strings.dart';
import '../../../../notification/controllers/notification_controller.dart';
import '../../../../notification/screens/show_notifications.dart';
import 'search_overlay.dart';

class THomeAppBar extends StatelessWidget {
  const THomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final userController = Get.put(UserController());
    final notifController = Get.put(NotificationController());
    return TAppBar(
      centerTitle: false,
      showBackArrow: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => userController.profileLoading.value
              ? const TShimmerEffect(width: 80, height: 15)
              : Text(TTexts.homeAppbarSubTitle,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium!
                      .apply(color: AppColors.grey))),
          Obx(() => userController.profileLoading.value
              ? const TShimmerEffect(width: 80, height: 15)
              : Text(userController.user.value.fullName,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall!
                      .apply(color: AppColors.grey))),
        ],
      ),
      actions: [
        const NotificationBell(),
        IconButton(
          icon: const Icon(Iconsax.search_normal_1, color: Colors.white),
          onPressed: () {
            Get.to(() => const SearchOverlay(),
                transition: Transition.fadeIn,
                duration: const Duration(milliseconds: 300),
                opaque: false,
                routeName: '/search');
          },
        ),
        TCartCounterIcon(
          counterBgColor: AppColors.black,
          counterTextColor: AppColors.white,
          iconColor: AppColors.white,
        ),
      ],
    );
  }

  void _showNotificationSheet(
      BuildContext context, NotificationController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Obx(() {
          final notifs = controller.notifications;
          if (notifs.isEmpty) {
            return const Center(child: Text('Aucune notification.'));
          }
          return ListView.builder(
            itemCount: notifs.length,
            itemBuilder: (_, index) {
              final notif = notifs[index];
              return ListTile(
                leading: const Icon(Iconsax.notification),
                title: Text(notif.title),
                subtitle: Text(notif.message),
                trailing: notif.read
                    ? null
                    : const Icon(Icons.circle, size: 8, color: Colors.red),
              );
            },
          );
        }),
      ),
    );
  }
}
