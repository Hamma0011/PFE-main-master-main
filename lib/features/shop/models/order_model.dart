import 'package:caferesto/features/shop/models/cart_item_model.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';

import '../../personalization/models/address_model.dart';
import 'etablissement_model.dart';

enum OrderStatus { pending, cancelled, delivered, preparing, ready, refused }

class OrderModel {
  final String id;
  final String userId;
  final OrderStatus status;
  final double totalAmount;
  final DateTime orderDate;
  final String paymentMethod;
  final AddressModel? address;
  final DateTime? deliveryDate;
  final List<CartItemModel> items;
  final DateTime? pickupDateTime;
  final String? pickupDay;
  final String? pickupTimeRange;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Etablissement? etablissement;
  final String etablissementId;
  final String? refusalReason;
  final int? preparationTime;
  final String? clientArrivalTime; // Format HH:mm:ss
  final String? codeRetrait; // Code de retrait (4 chiffres: 0001-0999)
  OrderModel(
      {required this.id,
      required this.userId,
      required this.status,
      required this.totalAmount,
      required this.orderDate,
      required this.paymentMethod,
      required this.items,
      this.address,
      this.deliveryDate,
      this.pickupDateTime,
      this.pickupDay,
      this.pickupTimeRange,
      this.createdAt,
      this.updatedAt,
      this.etablissement,
      required this.etablissementId,
      this.refusalReason,
      this.preparationTime,
      this.clientArrivalTime,
      this.codeRetrait});

  // -------------------------
  // Computed / helper getters
  // -------------------------
  String get formattedOrderDate => THelperFunctions.getFormattedDate(orderDate);

  String get formattedDeliveryDate => deliveryDate != null
      ? THelperFunctions.getFormattedDate(deliveryDate!)
      : '';

  String get orderStatusText {
    switch (status) {
      case OrderStatus.delivered:
        return 'Livrée';
      case OrderStatus.preparing:
        return 'En préparation';
      case OrderStatus.ready:
        return 'Prête';
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.cancelled:
        return 'Annulée';
      case OrderStatus.refused:
        return 'Refusée';
    }
  }

  // Check if order can be modified by client
  bool get canBeModified => status == OrderStatus.pending;

  // Check if order can be cancelled by client
  bool get canBeCancelled => status == OrderStatus.pending;

  // Check if order is active (not completed)
  bool get isActive =>
      status == OrderStatus.pending ||
      status == OrderStatus.preparing ||
      status == OrderStatus.ready;

  // Check if order is completed
  bool get isCompleted =>
      status == OrderStatus.delivered ||
      status == OrderStatus.cancelled ||
      status == OrderStatus.refused;

  // -------------------------
  // COPYWITH METHOD
  // -------------------------

  OrderModel copyWith({
    String? id,
    String? userId,
    OrderStatus? status,
    double? totalAmount,
    DateTime? orderDate,
    String? paymentMethod,
    AddressModel? address,
    DateTime? deliveryDate,
    List<CartItemModel>? items,
    DateTime? pickupDateTime,
    String? pickupDay,
    String? pickupTimeRange,
    DateTime? createdAt,
    DateTime? updatedAt,
    Etablissement? etablissement,
    String? etablissementId,
    String? refusalReason,
    int? preparationTime,
    String? clientArrivalTime,
    String? codeRetrait,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      orderDate: orderDate ?? this.orderDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      address: address ?? this.address,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      items: items ?? this.items,
      pickupDateTime: pickupDateTime ?? this.pickupDateTime,
      pickupDay: pickupDay ?? this.pickupDay,
      pickupTimeRange: pickupTimeRange ?? this.pickupTimeRange,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      etablissement: etablissement ?? this.etablissement,
      etablissementId: etablissementId ?? this.etablissementId,
      refusalReason: refusalReason ?? this.refusalReason,
      preparationTime: preparationTime ?? this.preparationTime,
      clientArrivalTime: clientArrivalTime ?? this.clientArrivalTime,
      codeRetrait: codeRetrait ?? this.codeRetrait,
    );
  }

  // -------------------------
  // Serialization
  // -------------------------

  /// Converts Dart model → JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status.name,
      'total_amount': totalAmount,
      'order_date': orderDate.toIso8601String(),
      'delivery_date': deliveryDate?.toIso8601String(),
      'payment_method': paymentMethod,
      'address': address?.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'pickup_date_time': pickupDateTime?.toIso8601String(),
      'pickup_day': pickupDay,
      'pickup_time_range': pickupTimeRange,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'etablissement_id': etablissementId,
      'refusal_reason': refusalReason,
      'preparation_time': preparationTime,
      'client_arrival_time': clientArrivalTime,
      'code_retrait': codeRetrait,
    };
  }

  /// Converts Supabase JSON → Dart model
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: _parseStatus(json['status']),
      totalAmount: (json['total_amount'] as num).toDouble(),
      orderDate: DateTime.parse(json['order_date'] as String),
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'] as String)
          : null,
      paymentMethod: json['payment_method'] as String,
      address: json['address'] != null
          ? AddressModel.fromJson(Map<String, dynamic>.from(json['address']))
          : null,
      items: (json['items'] as List)
          .map((e) => CartItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      pickupDateTime: json['pickup_date_time'] != null
          ? DateTime.parse(json['pickup_date_time'] as String)
          : null,
      pickupDay: json['pickup_day'] as String?,
      pickupTimeRange: json['pickup_time_range'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      etablissement: json['etablissement'] != null
          ? Etablissement.fromJson(json['etablissement'])
          : null,
      etablissementId: json['etablissement_id'] ?? '',
      refusalReason: json['refusal_reason'] as String?,
      preparationTime: json['preparation_time'] != null
          ? (json['preparation_time'] as num).toInt()
          : null,
      clientArrivalTime: json['client_arrival_time'] as String?,
      codeRetrait: json['code_retrait'] as String?,
    );
  }

  static OrderStatus _parseStatus(String? statusStr) {
    switch (statusStr) {
      case 'delivered':
        return OrderStatus.delivered;
      case 'ready':
        return OrderStatus.ready;
      case 'preparing':
        return OrderStatus.preparing;
      case 'refused':
        return OrderStatus.refused;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  factory OrderModel.empty() {
    return OrderModel(
      id: '',
      userId: '',
      status: OrderStatus.pending,
      totalAmount: 0.0,
      orderDate: DateTime.now(),
      paymentMethod: '',
      items: [],
      etablissementId: '',
      clientArrivalTime: null,
    );
  }

  // Helper method to check if order belongs to user
  bool belongsToUser(String userId) {
    return this.userId == userId;
  }

  // Helper method to check if order belongs to establishment
  bool belongsToEstablishment(String etablissementId) {
    return this.etablissementId == etablissementId;
  }

  // Get item count
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  // Get formatted total amount
  String get formattedTotalAmount => '${totalAmount.toStringAsFixed(2)} DT';

  /// Obtenir le nom de l'établissement à partir des produits de la commande
  /// Retourne le nom de l'établissement le plus fréquent parmi les items
  String get establishmentNameFromItems {
    if (items.isEmpty) {
      return etablissement?.name ?? 'LiteWait';
    }

    // Compter les occurrences de chaque nom d'établissement
    final Map<String, int> establishmentCounts = {};
    for (final item in items) {
      final name = item.brandName ?? 'Inconnu';
      establishmentCounts[name] = (establishmentCounts[name] ?? 0) + 1;
    }

    // Retourner le nom le plus fréquent
    if (establishmentCounts.isEmpty) {
      return etablissement?.name ?? 'LiteWait';
    }

    final mostFrequent = establishmentCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    return mostFrequent.key;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'OrderModel(id: $id, status: $status, totalAmount: $totalAmount, items: ${items.length})';
  }
}
