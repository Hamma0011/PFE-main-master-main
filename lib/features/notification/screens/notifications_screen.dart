import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';
import '../../../common/widgets/appbar/appbar.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationController());
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : AppColors.light,
      appBar: TAppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications'),
            Obx(() {
              final unreadCount = controller.unreadCount;
              if (unreadCount == 0) {
                return const SizedBox.shrink();
              }
              return Text(
                '$unreadCount non lue${unreadCount > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
              );
            }),
          ],
        ),
        showBackArrow: true,
        actions: [
          // Bouton pour marquer toutes comme lues
          Obx(() {
            final unreadCount = controller.unreadCount;
            if (unreadCount == 0) {
              return const SizedBox.shrink();
            }
            return Tooltip(
              message: 'Marquer toutes comme lues',
              child: IconButton(
                icon: const Icon(Iconsax.tick_circle),
                onPressed: () => controller.markAllAsRead(),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        final notifications = controller.notifications;

        if (notifications.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.defaultSpace * 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: dark
                          ? AppColors.darkContainer
                          : AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.notification_bing,
                      size: 64,
                      color: dark
                          ? Colors.grey.shade600
                          : AppColors.primary.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceBtwSections),
                  Text(
                    'Aucune notification',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: dark ? Colors.white : Colors.black,
                        ),
                  ),
                  const SizedBox(height: AppSizes.spaceBtwItems / 2),
                  Text(
                    'Vous n\'avez pas encore de notifications.\nElles apparaîtront ici lorsqu\'elles arriveront.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.refreshNotifications(),
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.defaultSpace,
                  vertical: AppSizes.spaceBtwItems,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final notification = notifications[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSizes.spaceBtwItems,
                        ),
                        child: _NotificationItem(
                          notification: notification,
                          dark: dark,
                          onTap: () => controller.handleNotificationTap(notification),
                        ),
                      );
                    },
                    childCount: notifications.length,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({
    required this.notification,
    required this.dark,
    required this.onTap,
  });

  final NotificationModel notification;
  final bool dark;
  final VoidCallback onTap;

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('dd MMM yyyy', 'fr').format(dateTime);
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  IconData _getNotificationIcon() {
    final title = notification.title.toLowerCase();
    if (title.contains('établissement') || title.contains('statut')) {
      return Iconsax.buildings;
    } else if (title.contains('commande') || title.contains('order')) {
      return Iconsax.shopping_cart;
    } else if (title.contains('produit')) {
      return Iconsax.box;
    } else if (title.contains('approuvé') || title.contains('accepté')) {
      return Iconsax.tick_circle;
    } else if (title.contains('rejeté') || title.contains('refusé')) {
      return Iconsax.close_circle;
    } else {
      return Iconsax.notification;
    }
  }

  Color _getIconColor() {
    final title = notification.title.toLowerCase();
    if (title.contains('approuvé') || title.contains('accepté')) {
      return AppColors.success;
    } else if (title.contains('rejeté') || title.contains('refusé')) {
      return AppColors.error;
    } else if (title.contains('commande')) {
      return AppColors.primary;
    } else {
      return notification.read
          ? (dark ? Colors.grey.shade600 : Colors.grey.shade400)
          : AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRead = notification.read;
    final iconColor = _getIconColor();
    final icon = _getNotificationIcon();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: dark
                ? (isRead
                    ? AppColors.darkContainer
                    : AppColors.primary.withOpacity(0.15))
                : (isRead ? AppColors.white : AppColors.primary.withOpacity(0.08)),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
            border: Border.all(
              color: isRead
                  ? Colors.transparent
                  : (dark
                      ? AppColors.primary.withOpacity(0.4)
                      : AppColors.primary.withOpacity(0.3)),
              width: isRead ? 0 : 1.5,
            ),
            boxShadow: isRead
                ? []
                : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Indicateur de notification non lue (barre verticale)
                if (!isRead)
                  Container(
                    width: 4,
                    margin: const EdgeInsets.only(right: AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              // Icône de notification avec fond dégradé
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isRead
                        ? [
                            dark
                                ? AppColors.darkContainer
                                : Colors.grey.shade100,
                            dark
                                ? AppColors.darkContainer
                                : Colors.grey.shade50,
                          ]
                        : [
                            AppColors.primary.withOpacity(0.2),
                            AppColors.primary.withOpacity(0.1),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSizes.md),
                // Contenu de la notification
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Titre avec badge "Nouveau" si non lue
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight:
                                      isRead ? FontWeight.w500 : FontWeight.bold,
                                  fontSize: 16,
                                  color: isRead
                                      ? (dark
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade700)
                                      : (dark ? Colors.white : Colors.black87),
                                  height: 1.3,
                                ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Nouveau',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.sm / 2),
                    // Message
                    Text(
                      notification.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            fontSize: 14,
                            height: 1.4,
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizes.sm),
                    // Date avec icône
                    Row(
                      children: [
                        Icon(
                          Iconsax.clock,
                          size: 12,
                          color: dark
                              ? Colors.grey.shade600
                              : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTimeAgo(notification.createdAt),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: dark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade500,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

