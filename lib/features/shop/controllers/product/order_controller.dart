import 'package:caferesto/features/personalization/controllers/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../common/widgets/success_screen/success_screen.dart';
import '../../../../data/repositories/authentication/authentication_repository.dart';
import '../../../../data/repositories/order/order_repository.dart';
import '../../../../data/repositories/product/produit_repository.dart';
import '../../../../navigation_menu.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/popups/full_screen_loader.dart';
import '../../../../utils/popups/loaders.dart';
import '../../../personalization/controllers/address_controller.dart';
import '../../models/cart_item_model.dart';
import '../../models/order_model.dart';
import 'panier_controller.dart';
import 'checkout_controller.dart';

class OrderController extends GetxController {
  static OrderController get instance {
    try {
      return Get.find<OrderController>();
    } catch (e) {
      // If not found, create it (shouldn't happen if GeneralBinding is used)
      return Get.put(OrderController());
    }
  }

  final orderRepository = Get.put(OrderRepository());
  final produitRepository = ProduitRepository.instance;
  final cartController = CartController.instance;
  final userController = UserController.instance;
  final _db = Supabase.instance.client;
  final addressController = AddressController.instance;
  final checkoutController = CheckoutController.instance;

  final orders = <OrderModel>[].obs;
  final isLoading = false.obs;
  final isUpdating = false.obs;
  RealtimeChannel? _ordersChannel;
  final Rxn<Map<String, dynamic>> selectedAddress = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    _subscribeToOrdersRealtime();
    listenToUserOrders(); // 👈 Start real-time listener
  }

  @override
  void onClose() {
    if (_ordersChannel != null) _db.removeChannel(_ordersChannel!);
    super.onClose();
  }

  void listenToUserOrders() {
    final userId = userController.user.value.id;
    if (userId.isEmpty) return;

    isLoading.value = true;

    /// Listen to changes in the `orders` table
    _db
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .listen((data) {
          orders.value = data.map((row) => OrderModel.fromJson(row)).toList();
          isLoading.value = false;
        });
  }

  Future<List<OrderModel>> fetchGerantOrders(String etablissementId) async {
    try {
      isLoading.value = true;
      debugPrint(' Chargement commandes gérant pour: $etablissementId');

      // FIX: Use the repository method
      final gerantOrders =
          await orderRepository.fetchOrdersByEtablissement(etablissementId);

      orders.value = gerantOrders;
      debugPrint('${gerantOrders.length} commandes gérant chargées');
      return gerantOrders;
    } catch (e) {
      debugPrint('Erreur fetchGerantOrders: $e');
      // FIX: Don't show snackbar here - let the screen handle it
      rethrow; // Re-throw to let caller handle the error
    } finally {
      isLoading.value = false;
    }
  }

  //  Update order status with notification
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? refusalReason,
  }) async {
    try {
      isUpdating.value = true;

      final orderIndex = orders.indexWhere((o) => o.id == orderId);
      if (orderIndex == -1) throw 'Commande non trouvée';

      final order = orders[orderIndex];
      final oldStatus = order.status;

      // Gérer le stock selon le changement de statut
      // Si on refuse ou annule, restaurer le stock
      if ((newStatus == OrderStatus.refused || newStatus == OrderStatus.cancelled) &&
          oldStatus == OrderStatus.pending) {
        try {
          debugPrint('🔄 Début de la restauration du stock pour le changement de statut (${oldStatus.name} -> ${newStatus.name})');
          await _increaseStockForOrder(order.items);
          debugPrint('✅ Stock restauré avec succès');
        } catch (e, stackTrace) {
          debugPrint('❌ Erreur lors de la restauration du stock: $e');
          debugPrint('Stack trace: $stackTrace');
          // Continuer même si la restauration du stock échoue
        }
      }

      // Prepare update data
      final updates = {
        'status': newStatus.name,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (refusalReason != null) {
        updates['refusal_reason'] = refusalReason;
      }

      await orderRepository.updateOrder(orderId, updates);

      // Send notification to client
      await _sendStatusNotification(order, newStatus, refusalReason);

      TLoaders.successSnackBar(
        title: "Succès",
        message: "Statut mis à jour",
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: "Erreur",
        message: "Impossible de mettre à jour: $e",
      );
    } finally {
      isUpdating.value = false;
    }
  }

  //  Send notification for status changes
  Future<void> _sendStatusNotification(
    OrderModel order,
    OrderStatus newStatus,
    String? refusalReason,
  ) async {
    try {
      String title = "";
      String message = "";

      switch (newStatus) {
        case OrderStatus.preparing:
          title = "Commande en préparation";
          message =
              "Votre commande #${order.id.substring(0, 8)} est en cours de préparation.";
          break;
        case OrderStatus.ready:
          title = "Commande prête";
          message =
              "Votre commande #${order.id.substring(0, 8)} est prête pour retrait.";
          break;
        case OrderStatus.delivered:
          title = "Commande livrée";
          message = "Votre commande #${order.id.substring(0, 8)} a été livrée.";
          break;
        case OrderStatus.refused:
          title = "Commande refusée";
          message =
              "Votre commande #${order.id.substring(0, 8)} a été refusée. Raison: $refusalReason";
          break;
        default:
          return;
      }

      await _db.from('notifications').insert({
        'user_id': order.userId,
        'title': title,
        'message': message,
        'read': false,
        'etablissement_id': order.etablissementId,
        'receiver_role': 'client',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Erreur notification: $e');
    }
  }

  //  Real-time subscription
  void _subscribeToOrdersRealtime() {
    try {
      _ordersChannel = _db.channel('public:orders');

      _ordersChannel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'orders',
        callback: (payload) {
          try {
            final eventType = payload.eventType;
            // Only process INSERT and UPDATE events (DELETE events don't have newRecord)
            if (eventType != PostgresChangeEvent.insert &&
                eventType != PostgresChangeEvent.update) {
              return;
            }

            final updatedOrder = OrderModel.fromJson(payload.newRecord);
            final index = orders.indexWhere((o) => o.id == updatedOrder.id);

            if (index != -1) {
              orders[index] = updatedOrder;
              orders.refresh();
            } else {
              // Check if this new order belongs to current gérant
              final currentEtabId = userController.currentEtablissementId;
              if (currentEtabId != null &&
                  updatedOrder.etablissementId == currentEtabId) {
                orders.insert(0, updatedOrder);
                orders.refresh();
              }
            }
          } catch (e) {
            debugPrint('Erreur temps réel: $e');
          }
        },
      );

      _ordersChannel!.subscribe(
        (status, [_]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            debugPrint('Abonnement temps réel activé pour les commandes');
          }
        },
      );
    } catch (e) {
      debugPrint('Erreur abonnement temps réel: $e');
    }
  }

  //  Filter orders by status
  List<OrderModel> get pendingOrders =>
      orders.where((o) => o.status == OrderStatus.pending).toList();
  List<OrderModel> get activeOrders => orders
      .where((o) =>
          o.status == OrderStatus.preparing || o.status == OrderStatus.ready)
      .toList();
  List<OrderModel> get completedOrders => orders
      .where((o) =>
          o.status == OrderStatus.delivered ||
          o.status == OrderStatus.cancelled ||
          o.status == OrderStatus.refused)
      .toList();

  final RxnString selectedDay = RxnString();
  final RxnString selectedSlot = RxnString();

  void setSelectedSlot(String day, String slot) {
    selectedDay.value = day;
    selectedSlot.value = slot;
  }

  void clearSelectedSlot() {
    selectedDay.value = null;
    selectedSlot.value = null;
  }

  void setSelectedAddress(Map<String, dynamic> address) {
    selectedAddress.value = address;
  }

  String getEtsId(OrderModel order) {
    return order.etablissementId;
  }

  Future<List<OrderModel>> fetchUserOrders() async {
    try {
      isLoading.value = true;

      final userOrders = await orderRepository.fetchUserOrders();
      return userOrders;
    } catch (e) {
      TLoaders.warningSnackBar(title: 'Erreur', message: e.toString());
      return [];
    }
  }

  Future<void> processOrder({
    required double totalAmount,
    required String etablissementId,
    DateTime? pickupDateTime,
    String? pickupDay,
    String? pickupTimeRange,
    String? addressId,
  }) async {
    try {
      TFullScreenLoader.openLoadingDialog(
          'En cours d\'enrgistrer votre commande...', TImages.pencilAnimation);

      final user = AuthenticationRepository.instance.authUser;
      if (user == null || user.id.isEmpty) {
        TFullScreenLoader.stopLoading();
        TLoaders.errorSnackBar(
          title: 'Erreur utilisateur',
          message: 'Impossible de récupérer vos informations utilisateur.',
        );
        return;
      }

      // Ensure we have a selected address
      final selectedAddress = addressController.selectedAddress.value;
      if (selectedAddress.id.isEmpty) {
        TFullScreenLoader.stopLoading();
        TLoaders.warningSnackBar(
          title: 'Adresse manquante',
          message: 'Veuillez sélectionner une adresse de livraison.',
        );
        return;
      }

      // Vérifier si on modifie une commande existante
      final editingOrderId = cartController.editingOrderId.value;
      if (editingOrderId.isNotEmpty) {
        // Mettre à jour la commande existante
        await updateExistingOrder(
          orderId: editingOrderId,
          newItems: cartController.cartItems.toList(),
          totalAmount: totalAmount,
          pickupDay: pickupDay ?? '',
          pickupTimeRange: pickupTimeRange ?? '',
          pickupDateTime: pickupDateTime ?? DateTime.now(),
        );
      } else {
        // Créer une nouvelle commande
        final order = OrderModel(
          id: '', // Let database generate UUID
          userId: user.id,
          etablissementId: etablissementId,
          status: OrderStatus.pending,
          totalAmount: totalAmount,
          orderDate: DateTime.now(),
          paymentMethod: checkoutController.selectedPaymentMethod.value.name,
          address: selectedAddress,
          deliveryDate: null, // Should be null initially
          items: cartController.cartItems.toList(),
          pickupDateTime: pickupDateTime,
          pickupDay: pickupDay,
          pickupTimeRange: pickupTimeRange,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        // Diminuer le stock des produits stockables commandés AVANT de sauvegarder la commande
        try {
          debugPrint('🔄 Début de la mise à jour du stock avant sauvegarde de la commande');
          await _decreaseStockForOrder(order.items);
          debugPrint('✅ Stock mis à jour avec succès');
        } catch (e, stackTrace) {
          debugPrint('❌ Erreur lors de la mise à jour du stock: $e');
          debugPrint('Stack trace: $stackTrace');
          TFullScreenLoader.stopLoading();
          TLoaders.errorSnackBar(
            title: 'Erreur de stock',
            message: 'Erreur lors de la mise à jour du stock: $e',
          );
          return; // Ne pas continuer si la mise à jour du stock échoue
        }
        
        await orderRepository.saveOrder(order, user.id);

        // Envoyer une notification au gérant de l'établissement
        try {
          await _notifyGerantOfNewOrder(etablissementId, order);
        } catch (e) {
          debugPrint('Erreur lors de l\'envoi de la notification au gérant: $e');
          // Ne pas bloquer le processus si la notification échoue
        }
      }

      cartController.clearCart();
      TFullScreenLoader.stopLoading();

      final isEditing = cartController.editingOrderId.value.isNotEmpty;
      Get.offAll(() => SuccessScreen(
          image: TImages.orderCompletedAnimation,
          title: isEditing ? 'Commande modifiée !' : 'Produit(s) commandé(s) !',
          subTitle: isEditing 
              ? 'Votre commande a été modifiée avec succès'
              : 'Votre commande est en cours de traitement',
          onPressed: () => Get.offAll(() => const NavigationMenu())));
    } catch (e) {
      TFullScreenLoader.stopLoading();

      TLoaders.warningSnackBar(title: 'Erreur', message: e.toString());
    }
  }

  /// Mettre à jour une commande existante
  Future<void> updateExistingOrder({
    required String orderId,
    required List<CartItemModel> newItems,
    required double totalAmount,
    required String pickupDay,
    required String pickupTimeRange,
    required DateTime pickupDateTime,
  }) async {
    try {
      final orderIndex = orders.indexWhere((o) => o.id == orderId);
      if (orderIndex == -1) {
        throw 'Commande non trouvée';
      }

      final order = orders[orderIndex];

      // Vérifier que la commande peut être modifiée (seulement en attente)
      if (order.status != OrderStatus.pending) {
        throw 'Seules les commandes en attente peuvent être modifiées.';
      }

      // 1. Restaurer le stock des anciens articles
      try {
        debugPrint('🔄 Restauration du stock pour les anciens articles');
        await _increaseStockForOrder(order.items);
        debugPrint('✅ Stock restauré avec succès');
      } catch (e, stackTrace) {
        debugPrint('❌ Erreur lors de la restauration du stock: $e');
        debugPrint('Stack trace: $stackTrace');
      }

      // 2. Diminuer le stock des nouveaux articles
      try {
        debugPrint('🔄 Mise à jour du stock pour les nouveaux articles');
        await _decreaseStockForOrder(newItems);
        debugPrint('✅ Stock mis à jour avec succès');
      } catch (e, stackTrace) {
        debugPrint('❌ Erreur lors de la mise à jour du stock: $e');
        debugPrint('Stack trace: $stackTrace');
        // Restaurer le stock précédent en cas d'erreur
        try {
          await _increaseStockForOrder(order.items);
        } catch (_) {
          // Si cela échoue aussi, on continue quand même
        }
        throw 'Erreur lors de la mise à jour du stock';
      }

      // 3. Préparer les données de mise à jour
      final updates = {
        'items': newItems.map((item) => item.toJson()).toList(),
        'total_amount': totalAmount,
        'pickup_day': pickupDay,
        'pickup_time_range': pickupTimeRange,
        'pickup_date_time': pickupDateTime.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // 4. Mettre à jour dans la base de données
      await orderRepository.updateOrder(orderId, updates);

      // 5. Récupérer l'ID du gérant pour la notification
      final etablissementResponse = await _db
          .from('etablissements')
          .select('id_owner, name')
          .eq('id', order.etablissementId)
          .maybeSingle();

      if (etablissementResponse != null) {
        final gerantId = etablissementResponse['id_owner']?.toString() ?? '';
        if (gerantId.isNotEmpty) {
          // Notifier le gérant
          await _db.from('notifications').insert({
            'user_id': gerantId,
            'title': 'Commande modifiée',
            'message':
                'Le client a modifié la commande #${orderId.substring(0, 8)}. Nouveau total: ${totalAmount.toStringAsFixed(2)} DT',
            'read': false,
            'etablissement_id': order.etablissementId,
            'receiver_role': 'gérant',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      // 6. Recharger les commandes
      await fetchUserOrders();
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la commande: $e');
      rethrow;
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      isUpdating.value = true;

      final orderIndex = orders.indexWhere((o) => o.id == orderId);
      if (orderIndex == -1) {
        throw 'Commande non trouvée';
      }

      final order = orders[orderIndex];

      // Check if order can be cancelled (only pending orders)
      if (order.status != OrderStatus.pending) {
        TLoaders.errorSnackBar(
          title: "Impossible d'annuler",
          message: "Seules les commandes en attente peuvent être annulées.",
        );
        return;
      }

      // Restaurer le stock des produits si la commande était en attente
      try {
        debugPrint('🔄 Début de la restauration du stock pour l\'annulation de la commande ${orderId}');
        await _increaseStockForOrder(order.items);
        debugPrint('✅ Stock restauré avec succès');
      } catch (e, stackTrace) {
        debugPrint('❌ Erreur lors de la restauration du stock: $e');
        debugPrint('Stack trace: $stackTrace');
        // Continuer même si la restauration du stock échoue
        // Ne pas bloquer l'annulation de la commande
      }

      // Update locally first for immediate UI feedback
      orders[orderIndex] = order.copyWith(status: OrderStatus.cancelled);
      orders.refresh();

      // Update in database
      await orderRepository.updateOrder(orderId, {
        'status': 'cancelled',
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Send notification to establishment
      await _sendNotification(
        userId: order.etablissementId, // This goes to the establishment
        title: "Commande annulée",
        message: "Le client a annulé la commande #${orderId.substring(0, 8)}",
        etablissementId: order.etablissementId,
        receiverRole: 'gérant',
      );

      TLoaders.successSnackBar(
        title: "Succès",
        message: "Votre commande a été annulée.",
      );
    } catch (e) {
      // Revert local changes on error
      fetchUserOrders(); // Reload to get correct state
      TLoaders.errorSnackBar(
        title: "Erreur",
        message: "Impossible d'annuler la commande: $e",
      );
    } finally {
      isUpdating.value = false;
    }
  }

  /// Diminuer le stock des produits stockables lors de la création d'une commande
  Future<void> _decreaseStockForOrder(List<CartItemModel> items) async {
    debugPrint('📦 Début de la diminution du stock pour ${items.length} items');
    
    for (final item in items) {
      try {
        debugPrint('📦 Traitement du produit: ${item.productId}, quantité: ${item.quantity}');
        
        // Récupérer le produit pour vérifier s'il est stockable
        final productResponse = await _db
            .from('produits')
            .select('est_stockable, quantite_stock, product_type, tailles_prix')
            .eq('id', item.productId)
            .single();

        final isStockable = productResponse['est_stockable'] as bool? ?? false;
        debugPrint('📦 Produit ${item.productId} est stockable: $isStockable');
        
        if (!isStockable) {
          debugPrint('📦 Produit ${item.productId} non stockable, ignoré');
          continue; // Produit non stockable, passer au suivant
        }

        // Pour tous les produits stockables (simples et variables), le stock est dans quantite_stock
        final currentStock = (productResponse['quantite_stock'] as num?)?.toInt() ?? 0;
        debugPrint('📦 Stock actuel: $currentStock, quantité à soustraire: ${item.quantity}');
        
        await produitRepository.updateProductStock(item.productId, -item.quantity);
        debugPrint('✅ Stock mis à jour pour produit ${item.productId}');
      } catch (e, stackTrace) {
        debugPrint('❌ Erreur lors de la diminution du stock pour ${item.productId}: $e');
        debugPrint('Stack trace: $stackTrace');
        // Ne pas lancer l'erreur, continuer avec les autres produits
        // mais loguer l'erreur pour le débogage
      }
    }
    
    debugPrint('📦 Fin de la diminution du stock');
  }

  /// Restaurer le stock des produits stockables lors de l'annulation/refus d'une commande
  Future<void> _increaseStockForOrder(List<CartItemModel> items) async {
    debugPrint('📦 Début de la restauration du stock pour ${items.length} items');
    
    for (final item in items) {
      try {
        debugPrint('📦 Restauration du stock pour produit: ${item.productId}, quantité: ${item.quantity}');
        
        // Récupérer le produit pour vérifier s'il est stockable
        final productResponse = await _db
            .from('produits')
            .select('est_stockable, quantite_stock, product_type, tailles_prix')
            .eq('id', item.productId)
            .single();

        final isStockable = productResponse['est_stockable'] as bool? ?? false;
        debugPrint('📦 Produit ${item.productId} est stockable: $isStockable');
        
        if (!isStockable) {
          debugPrint('📦 Produit ${item.productId} non stockable, ignoré');
          continue; // Produit non stockable, passer au suivant
        }

        // Pour tous les produits stockables (simples et variables), le stock est dans quantite_stock
        final currentStock = (productResponse['quantite_stock'] as num?)?.toInt() ?? 0;
        debugPrint('📦 Stock actuel: $currentStock, quantité à ajouter: ${item.quantity}');
        
        await produitRepository.updateProductStock(item.productId, item.quantity);
        debugPrint('✅ Stock restauré pour produit ${item.productId}');
      } catch (e, stackTrace) {
        debugPrint('❌ Erreur lors de la restauration du stock pour ${item.productId}: $e');
        debugPrint('Stack trace: $stackTrace');
        // Continuer avec les autres produits même en cas d'erreur
      }
    }
    
    debugPrint('📦 Fin de la restauration du stock');
  }

  Future<void> updateOrderDetails({
    required String orderId,
    required String pickupDay,
    required String pickupTimeRange,
  }) async {
    try {
      isUpdating.value = true;

      final orderIndex = orders.indexWhere((o) => o.id == orderId);
      if (orderIndex == -1) {
        throw 'Commande non trouvée';
      }

      final order = orders[orderIndex];

      // Check if order can be modified (only pending orders)
      if (order.status != OrderStatus.pending) {
        TLoaders.errorSnackBar(
          title: "Impossible de modifier",
          message: "Seules les commandes en attente peuvent être modifiées.",
        );
        return;
      }

      // Update in database
      await orderRepository.updateOrder(orderId, {
        'pickup_day': pickupDay,
        'pickup_time_range': pickupTimeRange,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Send notification to establishment
      await _sendNotification(
        userId: order.etablissementId,
        title: "Commande modifiée",
        message:
            "Le client a modifié le créneau de retrait pour la commande #${orderId.substring(0, 8)}",
        etablissementId: order.etablissementId,
        receiverRole: 'gérant',
      );

      // Reload orders to get updated data
      await fetchUserOrders();

      TLoaders.successSnackBar(
        title: "Succès",
        message: "Commande modifiée avec succès",
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: "Erreur",
        message: "Impossible de modifier la commande: $e",
      );
    } finally {
      isUpdating.value = false;
    }
  }

// Helper method for notifications
  Future<void> _sendNotification({
    required String userId,
    required String title,
    required String message,
    required String etablissementId,
    required String receiverRole,
  }) async {
    try {
      await _db.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'read': false,
        'etablissement_id': etablissementId,
        'receiver_role': receiverRole,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('Notification envoyée à $receiverRole: $title');
    } catch (e) {
      debugPrint('Erreur envoi notification: $e');
    }
  }

  /// Notifier le gérant lorsqu'une nouvelle commande est reçue
  Future<void> _notifyGerantOfNewOrder(String etablissementId, OrderModel order) async {
    try {
      debugPrint('🔔 Début de la notification au gérant pour l\'établissement: $etablissementId');
      
      // Récupérer directement l'ID du gérant depuis la base de données
      final etablissementResponse = await _db
          .from('etablissements')
          .select('id_owner, name')
          .eq('id', etablissementId)
          .maybeSingle();
      
      if (etablissementResponse == null) {
        debugPrint('⚠️ Établissement non trouvé: $etablissementId');
        return;
      }

      final gerantId = etablissementResponse['id_owner']?.toString() ?? '';
      final etablissementName = etablissementResponse['name']?.toString() ?? 'l\'établissement';
      
      if (gerantId.isEmpty) {
        debugPrint('⚠️ Aucun gérant trouvé pour l\'établissement: $etablissementId');
        return;
      }

      // Calculer le nombre total d'articles
      final totalItems = order.items.fold<int>(0, (sum, item) => sum + item.quantity);
      
      // Créer le message de notification avec le nom de l'établissement
      final message = 'Nouvelle commande reçue pour $etablissementName : ${totalItems} article${totalItems > 1 ? 's' : ''} pour un montant total de ${order.totalAmount.toStringAsFixed(2)} DT';

      // Envoyer la notification au gérant
      await _db.from('notifications').insert({
        'user_id': gerantId,
        'title': 'Nouvelle commande reçue',
        'message': message,
        'read': false,
        'etablissement_id': etablissementId,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Notification envoyée au gérant $gerantId pour la commande');
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de la notification au gérant: $e');
      debugPrint('Stack trace: $stackTrace');
      // Ne pas lancer l'erreur pour ne pas bloquer le processus de commande
    }
  }
}
