import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/order/order_repository.dart';
import '../../personalization/controllers/user_controller.dart';
import '../controllers/etablissement_controller.dart';
import '../../../utils/popups/loaders.dart';

class DashboardStats {
  final int totalOrders;
  final int pendingOrders;
  final int activeOrders;
  final int completedOrders;
  final double totalRevenue;
  final double todayRevenue;
  final double monthlyRevenue;
  final int totalProducts;
  final int totalEtablissements;
  final int totalUsers;
  final int lowStockProducts;
  final Map<String, int> ordersByStatus;
  final List<Map<String, dynamic>> topProducts;
  final List<Map<String, dynamic>> recentOrders;
  final double averageOrderValue;
  final int ordersToday;
  final int ordersThisMonth;
  final List<Map<String, dynamic>> ordersByDay; // Jour avec le plus de commandes
  final List<Map<String, dynamic>> pickupHours; // Heures de pickup les plus fréquentes

  DashboardStats({
    required this.totalOrders,
    required this.pendingOrders,
    required this.activeOrders,
    required this.completedOrders,
    required this.totalRevenue,
    required this.todayRevenue,
    required this.monthlyRevenue,
    required this.totalProducts,
    required this.totalEtablissements,
    required this.totalUsers,
    required this.lowStockProducts,
    required this.ordersByStatus,
    required this.topProducts,
    required this.recentOrders,
    required this.averageOrderValue,
    required this.ordersToday,
    required this.ordersThisMonth,
    required this.ordersByDay,
    required this.pickupHours,
  });
}

class DashboardController extends GetxController {
  final _db = Supabase.instance.client;
  final userController = UserController.instance;
  final etablissementController = EtablissementController.instance;
  final orderRepository = OrderRepository.instance;

  final isLoading = false.obs;
  final stats = Rxn<DashboardStats>();
  final selectedPeriod = '30'.obs; // 7, 30, 90 jours

  @override
  void onInit() {
    super.onInit();
    loadDashboardStats();
  }

  Future<void> loadDashboardStats() async {
    try {
      isLoading.value = true;
      final userRole = userController.userRole;
      final userId = userController.user.value.id;
      
      if (userRole == 'Admin') {
        await _loadAdminStats();
      } else if (userRole == 'Gérant') {
        await _loadGerantStats(userId);
      }
    } catch (e) {
      TLoaders.errorSnackBar(message: 'Erreur lors du chargement des statistiques: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadAdminStats() async {
    try {
      // Statistiques globales pour Admin
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month, 1);

      // Toutes les commandes
      final allOrdersResponse = await _db
          .from('orders')
          .select('*, etablissement:etablissement_id(*)')
          .order('created_at', ascending: false);

      final allOrders = allOrdersResponse as List;

      // Commandes du jour
      final todayOrdersResponse = await _db
          .from('orders')
          .select('*')
          .gte('created_at', todayStart.toIso8601String());

      // Commandes du mois
      final monthOrdersResponse = await _db
          .from('orders')
          .select('*')
          .gte('created_at', monthStart.toIso8601String());

      final todayOrders = todayOrdersResponse as List;
      final monthOrders = monthOrdersResponse as List;

      // Calculs des statistiques
      final totalOrders = allOrders.length;
      final ordersToday = todayOrders.length;
      final ordersThisMonth = monthOrders.length;

      final pendingOrders = allOrders.where((o) => o['status'] == 'pending').length;
      final activeOrders = allOrders.where((o) => ['preparing', 'ready'].contains(o['status'])).length;
      final completedOrders = allOrders.where((o) => o['status'] == 'delivered').length;

      final totalRevenue = allOrders
          .where((o) => ['delivered', 'ready'].contains(o['status']))
          .fold<double>(0.0, (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0.0));

      final todayRevenue = todayOrders
          .where((o) => ['delivered', 'ready'].contains(o['status']))
          .fold<double>(0.0, (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0.0));

      final monthlyRevenue = monthOrders
          .where((o) => ['delivered', 'ready'].contains(o['status']))
          .fold<double>(0.0, (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0.0));

      final averageOrderValue = completedOrders > 0 ? totalRevenue / completedOrders : 0.0;

      // Statistiques des établissements
      final etablissementsResponse = await _db.from('etablissements').select('id');
      final totalEtablissements = (etablissementsResponse as List).length;

      // Statistiques des produits
      final productsResponse = await _db.from('produits').select('id, quantite_stock, est_stockable');
      final products = productsResponse as List;
      final totalProducts = products.length;
      final lowStockProducts = products.where((p) {
        final isStockable = p['est_stockable'] == true;
        final stockQuantity = (p['quantite_stock'] as num?)?.toInt() ?? 0;
        return isStockable && stockQuantity < 10;
      }).length;

      // Statistiques des utilisateurs
      final usersResponse = await _db.from('users').select('id');
      final totalUsers = (usersResponse as List).length;

      // Produits les plus commandés
      final topProductsRaw = await orderRepository.getMostOrderedProducts(days: int.parse(selectedPeriod.value), limit: 5);
      
      // Enrichir avec les informations des produits (nom et catégorie)
      final topProducts = await _enrichTopProducts(topProductsRaw);

      // Commandes récentes
      final recentOrders = allOrders.take(5).map((o) => {
        'id': o['id'],
        'total_amount': o['total_amount'],
        'status': o['status'],
        'created_at': o['created_at'],
        'etablissement_name': (o['etablissement'] as Map?)?['name'] ?? 'N/A',
      }).toList();

      // Commandes par statut
      final ordersByStatus = <String, int>{};
      for (var order in allOrders) {
        final status = (order['status'] as String?) ?? 'unknown';
        ordersByStatus[status] = (ordersByStatus[status] ?? 0) + 1;
      }

      // Statistiques par jour (jours avec le plus de commandes)
      final ordersByDay = _calculateOrdersByDay(allOrders);

      // Statistiques des heures de pickup
      final pickupHours = _calculatePickupHours(allOrders);

      stats.value = DashboardStats(
        totalOrders: totalOrders,
        pendingOrders: pendingOrders,
        activeOrders: activeOrders,
        completedOrders: completedOrders,
        totalRevenue: totalRevenue,
        todayRevenue: todayRevenue,
        monthlyRevenue: monthlyRevenue,
        totalProducts: totalProducts,
        totalEtablissements: totalEtablissements,
        totalUsers: totalUsers,
        lowStockProducts: lowStockProducts,
        ordersByStatus: ordersByStatus,
        topProducts: topProducts,
        recentOrders: recentOrders,
        averageOrderValue: averageOrderValue,
        ordersToday: ordersToday,
        ordersThisMonth: ordersThisMonth,
        ordersByDay: ordersByDay,
        pickupHours: pickupHours,
      );
    } catch (e) {
      debugPrint('Erreur chargement stats admin: $e');
      rethrow;
    }
  }

  Future<void> _loadGerantStats(String userId) async {
    try {
      // Récupérer l'établissement du gérant
      final etab = await etablissementController.getEtablissementUtilisateurConnecte();
      if (etab == null) {
        throw 'Aucun établissement trouvé pour ce gérant';
      }

      final etablissementId = etab.id;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month, 1);
      final periodStart = now.subtract(Duration(days: int.parse(selectedPeriod.value)));

      // Commandes de l'établissement
      final allOrdersResponse = await _db
          .from('orders')
          .select('*')
          .eq('etablissement_id', etablissementId.toString())
          .order('created_at', ascending: false);

      final allOrders = allOrdersResponse as List;

      // Commandes du jour
      final todayOrdersResponse = await _db
          .from('orders')
          .select('*')
          .eq('etablissement_id', etablissementId.toString())
          .gte('created_at', todayStart.toIso8601String());

      // Commandes du mois
      final monthOrdersResponse = await _db
          .from('orders')
          .select('*')
          .eq('etablissement_id', etablissementId.toString())
          .gte('created_at', monthStart.toIso8601String());

      final todayOrders = todayOrdersResponse as List;
      final monthOrders = monthOrdersResponse as List;

      // Calculs
      final totalOrders = allOrders.length;
      final ordersToday = todayOrders.length;
      final ordersThisMonth = monthOrders.length;

      final pendingOrders = allOrders.where((o) => o['status'] == 'pending').length;
      final activeOrders = allOrders.where((o) => ['preparing', 'ready'].contains(o['status'])).length;
      final completedOrders = allOrders.where((o) => o['status'] == 'delivered').length;

      final totalRevenue = allOrders
          .where((o) => ['delivered', 'ready'].contains(o['status']))
          .fold<double>(0.0, (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0.0));

      final todayRevenue = todayOrders
          .where((o) => ['delivered', 'ready'].contains(o['status']))
          .fold<double>(0.0, (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0.0));

      final monthlyRevenue = monthOrders
          .where((o) => ['delivered', 'ready'].contains(o['status']))
          .fold<double>(0.0, (sum, o) => sum + ((o['total_amount'] as num?)?.toDouble() ?? 0.0));

      final averageOrderValue = completedOrders > 0 ? totalRevenue / completedOrders : 0.0;

      // Produits de l'établissement
      final productsResponse = await _db
          .from('produits')
          .select('id, quantite_stock, est_stockable')
          .eq('etablissement_id', etablissementId.toString());
      
      final products = productsResponse as List;
      final totalProducts = products.length;
      final lowStockProducts = products.where((p) {
        final isStockable = p['est_stockable'] == true;
        final stockQuantity = (p['quantite_stock'] as num?)?.toInt() ?? 0;
        return isStockable && stockQuantity < 10;
      }).length;

      // Produits les plus commandés (pour cet établissement uniquement)
      final periodOrders = await _db
          .from('orders')
          .select('items, created_at, status')
          .eq('etablissement_id', etablissementId.toString())
          .gte('created_at', periodStart.toIso8601String())
          .not('status', 'in', '(cancelled,refused)');

      final Map<String, int> productQuantities = {};
      for (var orderData in periodOrders as List) {
        final items = orderData['items'] as List?;
        if (items == null || items.isEmpty) continue;
        
        for (var item in items) {
          final itemMap = Map<String, dynamic>.from(item);
          final productId = itemMap['productId']?.toString() ?? '';
          final quantity = (itemMap['quantity'] as num?)?.toInt() ?? 0;
          
          if (productId.isEmpty || quantity <= 0) continue;
          productQuantities[productId] = (productQuantities[productId] ?? 0) + quantity;
        }
      }

      final topProductsRaw = productQuantities.entries
          .map((e) => {'productId': e.key, 'totalQuantity': e.value})
          .toList()
        ..sort((a, b) => (b['totalQuantity'] as int).compareTo(a['totalQuantity'] as int));
      
      // Enrichir avec les informations des produits (nom et catégorie)
      final topProducts = await _enrichTopProducts(topProductsRaw.take(5).toList());

      // Commandes récentes
      final recentOrders = allOrders.take(5).map((o) => {
        'id': o['id'],
        'total_amount': o['total_amount'],
        'status': o['status'],
        'created_at': o['created_at'],
      }).toList();

      // Commandes par statut
      final ordersByStatus = <String, int>{};
      for (var order in allOrders) {
        final status = (order['status'] as String?) ?? 'unknown';
        ordersByStatus[status] = (ordersByStatus[status] ?? 0) + 1;
      }

      // Statistiques par jour (jours avec le plus de commandes)
      final ordersByDay = _calculateOrdersByDay(allOrders);

      // Statistiques des heures de pickup
      final pickupHours = _calculatePickupHours(allOrders);

      stats.value = DashboardStats(
        totalOrders: totalOrders,
        pendingOrders: pendingOrders,
        activeOrders: activeOrders,
        completedOrders: completedOrders,
        totalRevenue: totalRevenue,
        todayRevenue: todayRevenue,
        monthlyRevenue: monthlyRevenue,
        totalProducts: totalProducts,
        totalEtablissements: 1, // Un seul établissement pour le gérant
        totalUsers: 0, // Non applicable pour le gérant
        lowStockProducts: lowStockProducts,
        ordersByStatus: ordersByStatus,
        topProducts: topProducts.take(5).toList(),
        recentOrders: recentOrders,
        averageOrderValue: averageOrderValue,
        ordersToday: ordersToday,
        ordersThisMonth: ordersThisMonth,
        ordersByDay: ordersByDay,
        pickupHours: pickupHours,
      );
    } catch (e) {
      debugPrint('Erreur chargement stats gérant: $e');
      rethrow;
    }
  }

  void updatePeriod(String period) {
    selectedPeriod.value = period;
    loadDashboardStats();
  }

  /// Enrichit les produits les plus vendus avec leurs noms et catégories
  Future<List<Map<String, dynamic>>> _enrichTopProducts(List<Map<String, dynamic>> topProductsRaw) async {
    final enrichedProducts = <Map<String, dynamic>>[];
    
    // Récupérer toutes les catégories pour le mapping
    final categoriesResponse = await _db.from('categories').select('id, name');
    final categoriesMap = <String, String>{};
    for (var cat in categoriesResponse as List) {
      categoriesMap[cat['id']?.toString() ?? ''] = cat['name']?.toString() ?? 'Inconnue';
    }
    
    // Enrichir chaque produit
    for (var product in topProductsRaw) {
      final productId = product['productId'] as String? ?? '';
      if (productId.isEmpty) continue;
      
      try {
        // Récupérer le produit
        final productResponse = await _db
            .from('produits')
            .select('id, nom, categorie_id')
            .eq('id', productId)
            .maybeSingle();
        
        if (productResponse != null) {
          final productName = productResponse['nom']?.toString() ?? 'Produit inconnu';
          final categoryId = productResponse['categorie_id']?.toString() ?? '';
          final categoryName = categoriesMap[categoryId] ?? 'Sans catégorie';
          
          enrichedProducts.add({
            'productId': productId,
            'productName': productName,
            'categoryName': categoryName,
            'totalQuantity': product['totalQuantity'],
          });
        } else {
          // Si le produit n'existe plus, on garde l'ID
          enrichedProducts.add({
            'productId': productId,
            'productName': 'Produit supprimé',
            'categoryName': 'Inconnue',
            'totalQuantity': product['totalQuantity'],
          });
        }
      } catch (e) {
        debugPrint('Erreur enrichissement produit $productId: $e');
        // En cas d'erreur, garder les données de base
        enrichedProducts.add({
          'productId': productId,
          'productName': 'Erreur de chargement',
          'categoryName': 'Inconnue',
          'totalQuantity': product['totalQuantity'],
        });
      }
    }
    
    return enrichedProducts;
  }

  /// Calcule les jours avec le plus de commandes
  List<Map<String, dynamic>> _calculateOrdersByDay(List allOrders) {
    final dayCounts = <String, int>{};
    
    for (var order in allOrders) {
      // Utiliser pickup_day si disponible, sinon utiliser created_at
      String dayKey;
      if (order['pickup_day'] != null && order['pickup_day'].toString().isNotEmpty) {
        dayKey = order['pickup_day'].toString();
      } else if (order['pickup_date_time'] != null) {
        try {
          final pickupDate = DateTime.parse(order['pickup_date_time'].toString());
          final weekday = pickupDate.weekday;
          dayKey = _weekdayToFrenchDay(weekday);
        } catch (e) {
          // Si erreur de parsing, utiliser created_at
          try {
            final createdDate = DateTime.parse(order['created_at'].toString());
            final weekday = createdDate.weekday;
            dayKey = _weekdayToFrenchDay(weekday);
          } catch (e2) {
            continue;
          }
        }
      } else if (order['created_at'] != null) {
        try {
          final createdDate = DateTime.parse(order['created_at'].toString());
          final weekday = createdDate.weekday;
          dayKey = _weekdayToFrenchDay(weekday);
        } catch (e) {
          continue;
        }
      } else {
        continue;
      }
      
      dayCounts[dayKey] = (dayCounts[dayKey] ?? 0) + 1;
    }
    
    // Trier par nombre de commandes décroissant et prendre le top 7
    final sortedDays = dayCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedDays.take(7).map((entry) => {
      'day': entry.key,
      'count': entry.value,
    }).toList();
  }

  /// Calcule les heures de pickup les plus fréquentes
  List<Map<String, dynamic>> _calculatePickupHours(List allOrders) {
    final hourCounts = <String, int>{};
    
    for (var order in allOrders) {
      String? hourKey;
      
      // Essayer d'abord pickup_time_range (format "HH:MM - HH:MM")
      if (order['pickup_time_range'] != null && order['pickup_time_range'].toString().isNotEmpty) {
        final timeRange = order['pickup_time_range'].toString();
        // Extraire l'heure de début (avant le "-")
        final parts = timeRange.split(' - ');
        if (parts.isNotEmpty) {
          final timeStr = parts[0].trim();
          // Extraire l'heure (avant les ":")
          final hourParts = timeStr.split(':');
          if (hourParts.isNotEmpty) {
            final hour = int.tryParse(hourParts[0]) ?? 0;
            hourKey = '${hour.toString().padLeft(2, '0')}:00';
          }
        }
      }
      
      // Si pas de pickup_time_range, utiliser pickup_date_time
      if (hourKey == null && order['pickup_date_time'] != null) {
        try {
          final pickupDate = DateTime.parse(order['pickup_date_time'].toString());
          hourKey = '${pickupDate.hour.toString().padLeft(2, '0')}:00';
        } catch (e) {
          continue;
        }
      }
      
      if (hourKey != null) {
        hourCounts[hourKey] = (hourCounts[hourKey] ?? 0) + 1;
      }
    }
    
    // Trier par nombre de commandes décroissant et prendre le top 10
    final sortedHours = hourCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedHours.take(10).map((entry) => {
      'hour': entry.key,
      'count': entry.value,
    }).toList();
  }

  /// Convertit le numéro de jour de la semaine (1-7) en nom français
  String _weekdayToFrenchDay(int weekday) {
    switch (weekday) {
      case 1:
        return 'Lundi';
      case 2:
        return 'Mardi';
      case 3:
        return 'Mercredi';
      case 4:
        return 'Jeudi';
      case 5:
        return 'Vendredi';
      case 6:
        return 'Samedi';
      case 7:
        return 'Dimanche';
      default:
        return 'Inconnu';
    }
  }
}

