import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/notification_controller.dart';

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final notifController = Get.put(NotificationController());
  final GlobalKey _menuKey = GlobalKey();

  OverlayEntry? _overlayEntry;

  void _toggleMenu() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    }
    setState(() {});
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        top: offset.dy + size.height + 6,
        right: 16,
        width: 320,
        child: Material(
          color: Colors.blue,
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Obx(() {
            final list = notifController.notifications;
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucune notification'),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(8),
              shrinkWrap: true,
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final n = list[index];
                return ListTile(
                  dense: true,
                  tileColor: n.read ? Colors.blueGrey : Colors.transparent,
                  title: Text(
                    n.title,
                    style: TextStyle(
                        fontWeight:
                            n.read ? FontWeight.normal : FontWeight.bold),
                  ),
                  subtitle: Text(
                    n.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    _toggleMenu();
                    notifController.handleNotificationTap(n);
                  },
                );
              },
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = notifController.unreadCount;
      return IconButton(
        key: _menuKey,
        onPressed: _toggleMenu,
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
