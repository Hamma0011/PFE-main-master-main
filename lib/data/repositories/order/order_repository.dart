import 'package:caferesto/utils/popups/loaders.dart';
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
}
