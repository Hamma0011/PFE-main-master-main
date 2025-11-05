import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../../personalization/screens/brands/mon_etablissement_screen.dart';
import '../../personalization/controllers/user_controller.dart';
import '../../shop/screens/order/gerant_order_management_screen.dart';
import '../../shop/screens/order/order.dart';
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

  /// Exposer la méthode pour le rafraîchissement
  Future<void> refreshNotifications() async {
    await _loadNotifications();
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

    // Vérifier si c'est une notification de commande
    final titleLower = n.title.toLowerCase();
    final messageLower = n.message.toLowerCase();
    final isOrderNotification = titleLower.contains('commande') || 
                                titleLower.contains('order') ||
                                messageLower.contains('commande') ||
                                messageLower.contains('order');

    if (isOrderNotification) {
      // Récupérer le rôle de l'utilisateur
      final userController = UserController.instance;
      final userRole = userController.userRole;

      // Rediriger selon le rôle de l'utilisateur
      if (userRole == 'Client') {
        // Rediriger vers "Mes commandes" pour les clients
        Get.to(() => const OrderScreen());
      } else {
        // Rediriger vers la page de gestion des commandes pour les gérants et admins
        Get.to(() => const GerantOrderManagementScreen());
      }
    } else if (n.etablissementId != null) {
      // Pour les autres notifications liées à un établissement,
      // naviguer vers MonEtablissementScreen
      Get.to(() => MonEtablissementScreen(),
          arguments: {'etablissementId': n.etablissementId});
    }
  }

  /// Marquer toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    try {
      final unreadIds = notifications
          .where((n) => !n.read)
          .map((n) => n.id)
          .toList();

      if (unreadIds.isEmpty) return;

      await supabase
          .from('notifications')
          .update({'read': true})
          .inFilter('id', unreadIds);

      // Mettre à jour localement
      for (var i = 0; i < notifications.length; i++) {
        if (!notifications[i].read) {
          notifications[i] = notifications[i].copyWith(read: true);
        }
      }
      notifications.refresh();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
}
