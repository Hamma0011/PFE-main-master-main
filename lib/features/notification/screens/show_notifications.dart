import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/notification_controller.dart';
import 'notifications_screen.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final notifController = Get.put(NotificationController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = notifController.unreadCount;
      return IconButton(
        onPressed: () {
          // Naviguer vers la page de notifications dédiée
          Get.to(() => const NotificationsScreen());
        },
        icon: badges.Badge(
          showBadge: count > 0,
          badgeContent: Text(
            '$count',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          position: badges.BadgePosition.topEnd(top: -4, end: -4),
          child: const Icon(Iconsax.notification, color: Colors.white),
        ),
      );
    });
  }
}
