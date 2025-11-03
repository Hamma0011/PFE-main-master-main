import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../../personalization/screens/brands/mon_etablissement_screen.dart';
import '../models/notification_model.dart';

class NotificationController extends GetxController {
  final supabase = Supabase.instance.client;
  final notifications = <NotificationModel>[].obs;
  final isLoading = false.obs;
  RealtimeChannel? _channel;

  String get currentUserId => supabase.auth.currentUser?.id ?? '';

  @override
  void onInit() {
    super.onInit();
    _loadNotifications();
    _subscribeRealtime();
  }

  @override
  void onClose() {
    if (_channel != null) supabase.removeChannel(_channel!);
    super.onClose();
  }

  Future<void> _loadNotifications() async {
    isLoading.value = true;
    try {
      final response = await supabase
          .from('notifications')
          .select('*')
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);
      notifications.value = (response as List)
          .map((n) => NotificationModel.fromJson(n))
          .toList();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _subscribeRealtime() {
    _channel = supabase.channel('public:notifications');
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: currentUserId,
      ),
      callback: (payload) {
        final newNotif = NotificationModel.fromJson(payload.newRecord);
        notifications.insert(0, newNotif);
        notifications.refresh();
        Get.snackbar(
          newNotif.title,
          newNotif.message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withOpacity(0.85),
          colorText: Colors.white,
        );
      },
    );
    _channel!.subscribe();
  }

  int get unreadCount =>
      notifications.where((n) => n.read == false).length;

  Future<void> markAsRead(String id) async {
    try {
      await supabase.from('notifications').update({'read': true}).eq('id', id);
      final index = notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(read: true);
        notifications.refresh();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Navigate when clicking a notification
  void handleNotificationTap(NotificationModel n) async {
    await markAsRead(n.id);

    if (n.etablissementId != null) {
      // Navigate directly to MonEtablissementScreen
      Get.to(() => MonEtablissementScreen(),
          arguments: {'etablissementId': n.etablissementId});
    }
  }
}
