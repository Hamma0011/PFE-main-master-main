import 'package:caferesto/utils/popups/loaders.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../features/shop/models/order_model.dart';
import '../authentication/authentication_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderRepository extends GetxController {
  static OrderRepository get instance => Get.find();

  final _db = Supabase.instance.client;

  /// Fetch all orders belonging to the current user
  Future<List<OrderModel>> fetchUserOrders() async {
    try {
      final user = AuthenticationRepository.instance.authUser;
      if (user == null || user.id.isEmpty) {
        throw 'Unable to find user information, try again later';
      }

      final response = await _db
          .from('orders')
          .select('*, etablissement:etablissement_id(*)')
          .eq('user_id', user.id)
          .order('order_date', ascending: false);

      return (response as List)
          .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching orders: $e');
      throw 'Something went wrong while fetching order information, try again later';
    }
  }

  /// Save a new order for a specific user
  Future<void> saveOrder(OrderModel order, String userId) async {
    try {
      if (order.etablissementId.isEmpty) {
        throw 'Etablissement ID is missing for this order.';
      }

      // Générer le code de retrait si non fourni
      String? codeRetrait = order.codeRetrait;
      if (codeRetrait == null || codeRetrait.isEmpty) {
        codeRetrait = await generateCodeRetrait(order.etablissementId);
      }

      // Convert to JSON and add user/etablissement IDs
      await _db.from('orders').insert({
        'user_id': order.userId,
        'etablissement_id': order.etablissementId,
        'status': order.status.name,
        'total_amount': order.totalAmount,
        'payment_method': order.paymentMethod,
        'address': order.address,
        'items': order.items.map((e) => e.toJson()).toList(),
        'pickup_date_time': order.pickupDateTime?.toIso8601String(),
        'pickup_day': order.pickupDay,
        'pickup_time_range': order.pickupTimeRange,
        'created_at': order.createdAt?.toIso8601String(),
        'updated_at': order.updatedAt?.toIso8601String(),
        'preparation_time': order.preparationTime,
        'client_arrival_time': order.clientArrivalTime,
        'code_retrait': codeRetrait,
      }).select();
    } on PostgrestException catch (e) {
      print('Postgres error: ${e.message}');
      rethrow;
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Erreur', message: e.toString());
    }
  }

  Future<void> updateOrder(String orderId, Map<String, dynamic> updates) async {
    try {
      await _db.from('orders').update(updates).eq('id', orderId);
    } catch (e) {
      throw 'Erreur lors de la mise à jour: $e';
    }
  }

  Future<List<OrderModel>> fetchOrdersByEtablissement(
      String etablissementId) async {
    try {
      final response = await _db
          .from('orders')
          .select('*, etablissement:etablissements(*)')
          .eq('etablissement_id', etablissementId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      throw 'Erreur lors du chargement des commandes: $e';
    }
  }

  /// Générer un nouveau code de retrait pour un établissement
  /// Le code est composé de 4 chiffres (0001, 0002, etc.)
  /// Chaque établissement a sa propre série
  /// Cycle : 0001 à 0999, puis retour à 0001
  Future<String> generateCodeRetrait(String etablissementId) async {
    try {
      // Récupérer le dernier code de retrait pour cet établissement
      // Exclure les commandes annulées/refusées du comptage
      final response = await _db
          .from('orders')
          .select('code_retrait')
          .eq('etablissement_id', etablissementId)
          .not('code_retrait', 'is', null)
          .not('status', 'in', '(cancelled,refused)')
          .order('created_at', ascending: false)
          .limit(1);

      final responseList = response as List;
      if (responseList.isEmpty) {
        // Premier code pour cet établissement
        return '0001';
      }

      final lastOrder = responseList[0] as Map<String, dynamic>;
      final lastCode = lastOrder['code_retrait'] as String;

      if (lastCode.isEmpty) {
        // Code vide, commencer à 0001
        return '0001';
      }

      // Convertir le dernier code en nombre
      final lastNumber = int.tryParse(lastCode) ?? 0;
      
      // Incrémenter de 1
      var nextNumber = lastNumber + 1;
      
      // Si on arrive à 1000, revenir à 1 (cycle 0001-0999)
      if (nextNumber >= 1000) {
        nextNumber = 1;
      }
      
      // Formater en 4 chiffres avec padding à gauche
      return nextNumber.toString().padLeft(4, '0');
    } catch (e) {
      debugPrint('Erreur lors de la génération du code de retrait: $e');
      // En cas d'erreur, générer un code basé sur le timestamp (fallback)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fallbackCode = (timestamp % 999) + 1; // Entre 1 et 999
      return fallbackCode.toString().padLeft(4, '0');
    }
  }

  /// Récupérer les IDs des produits les plus commandés avec leurs quantités
  /// [days] : nombre de jours à prendre en compte (par défaut 30)
  /// [limit] : nombre de produits à retourner (par défaut 10)
  Future<List<Map<String, dynamic>>> getMostOrderedProducts({
    int days = 30,
    int limit = 10,
  }) async {
    try {
      // Date limite (30 jours en arrière)
      final dateLimit = DateTime.now().subtract(Duration(days: days));
      
      // Récupérer toutes les commandes des 30 derniers jours (sauf annulées/refusées)
      final ordersResponse = await _db
          .from('orders')
          .select('items, created_at, status')
          .gte('created_at', dateLimit.toIso8601String())
          .not('status', 'in', '(cancelled,refused)'); // Exclure les annulées/refusées
      
      if ((ordersResponse as List).isEmpty) {
        return [];
      }
      
      // Map pour agréger les quantités par produit
      final Map<String, int> productQuantities = {};
      
      // Parcourir toutes les commandes
      for (final orderData in ordersResponse as List) {
        final items = orderData['items'] as List?;
        if (items == null || items.isEmpty) continue;
        
        // Parcourir tous les items de chaque commande
        for (final item in items) {
          final itemMap = Map<String, dynamic>.from(item);
          final productId = itemMap['productId']?.toString() ?? '';
          final quantity = (itemMap['quantity'] as num?)?.toInt() ?? 0;
          
          if (productId.isEmpty || quantity <= 0) continue;
          
          // Ajouter la quantité au total
          productQuantities[productId] = (productQuantities[productId] ?? 0) + quantity;
        }
      }
      
      // Créer la liste des résultats avec les quantités totales
      final results = productQuantities.entries.map((entry) {
        return {
          'productId': entry.key,
          'totalQuantity': entry.value,
        };
      }).toList();
      
      // Trier par quantité décroissante et limiter
      results.sort((a, b) => (b['totalQuantity'] as int).compareTo(a['totalQuantity'] as int));
      
      return results.take(limit).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des produits les plus commandés: $e');
      throw 'Erreur lors de la récupération des produits les plus commandés: $e';
    }
  }
}
