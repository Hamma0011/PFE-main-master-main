import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../shop/controllers/dashboard_controller.dart';

class GerantDashboardScreen extends StatelessWidget {
  const GerantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: TAppBar(
        title: const Text('Dashboard Gérant'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: () => controller.loadDashboardStats(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.stats.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = controller.stats.value;
        if (stats == null) {
          return const Center(child: Text('Aucune statistique disponible'));
        }

        return RefreshIndicator(
          onRefresh: controller.loadDashboardStats,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.defaultSpace),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filtre de période
                _buildPeriodFilter(controller),
                const SizedBox(height: AppSizes.spaceBtwSections),

                // Cartes de statistiques principales
                _buildMainStatsCards(stats, dark),
                const SizedBox(height: AppSizes.spaceBtwSections),

                // Graphiques et statistiques détaillées
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      // Desktop layout
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildRevenueChart(stats, dark),
                                const SizedBox(height: AppSizes.spaceBtwSections),
                                _buildOrdersByStatusChart(stats, dark),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSizes.spaceBtwItems),
                          Expanded(
                            child: Column(
                              children: [
                                _buildTopProducts(stats, dark),
                                const SizedBox(height: AppSizes.spaceBtwSections),
                                _buildSystemStats(stats, dark),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Mobile layout
                      return Column(
                        children: [
                          _buildRevenueChart(stats, dark),
                          const SizedBox(height: AppSizes.spaceBtwSections),
                          _buildOrdersByStatusChart(stats, dark),
                          const SizedBox(height: AppSizes.spaceBtwSections),
                          _buildTopProducts(stats, dark),
                          const SizedBox(height: AppSizes.spaceBtwSections),
                          _buildSystemStats(stats, dark),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSizes.spaceBtwSections),

                // Statistiques par jour et heures de pickup
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 800) {
                      // Desktop layout
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildOrdersByDay(stats, dark),
                          ),
                          const SizedBox(width: AppSizes.spaceBtwItems),
                          Expanded(
                            child: _buildPickupHours(stats, dark),
                          ),
                        ],
                      );
                    } else {
                      // Mobile layout
                      return Column(
                        children: [
                          _buildOrdersByDay(stats, dark),
                          const SizedBox(height: AppSizes.spaceBtwSections),
                          _buildPickupHours(stats, dark),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: AppSizes.spaceBtwSections),

                // Commandes récentes
                _buildRecentOrders(stats, dark),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPeriodFilter(DashboardController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Iconsax.calendar, size: 16),
          const SizedBox(width: 8),
          const Text('Période: '),
          DropdownButton<String>(
            value: controller.selectedPeriod.value,
            underline: const SizedBox(),
            items: ['7', '30', '90'].map((period) {
              return DropdownMenuItem(
                value: period,
                child: Text('$period jours'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) controller.updatePeriod(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainStatsCards(DashboardStats stats, bool dark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: AppSizes.spaceBtwItems,
      mainAxisSpacing: AppSizes.spaceBtwItems,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Commandes',
          stats.totalOrders.toString(),
          Iconsax.shopping_bag,
          Colors.blue,
          dark,
        ),
        _buildStatCard(
          'Revenus Total',
          '${stats.totalRevenue.toStringAsFixed(2)} DT',
          Iconsax.dollar_circle,
          Colors.green,
          dark,
        ),
        _buildStatCard(
          'Revenus Aujourd\'hui',
          '${stats.todayRevenue.toStringAsFixed(2)} DT',
          Iconsax.calendar,
          Colors.orange,
          dark,
        ),
        _buildStatCard(
          'Revenus Ce Mois',
          '${stats.monthlyRevenue.toStringAsFixed(2)} DT',
          Iconsax.chart,
          Colors.purple,
          dark,
        ),
        _buildStatCard(
          'Commandes En Attente',
          stats.pendingOrders.toString(),
          Iconsax.clock,
          Colors.amber,
          dark,
        ),
        _buildStatCard(
          'Commandes Actives',
          stats.activeOrders.toString(),
          Iconsax.activity,
          Colors.cyan,
          dark,
        ),
        _buildStatCard(
          'Produits',
          stats.totalProducts.toString(),
          Iconsax.box,
          Colors.indigo,
          dark,
        ),
        _buildStatCard(
          'Stock Faible',
          stats.lowStockProducts.toString(),
          Iconsax.warning_2,
          Colors.red,
          dark,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool dark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(Get.context!).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(DashboardStats stats, bool dark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Évolution des Revenus',
            style: Theme.of(Get.context!).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRevenueItem('Aujourd\'hui', stats.todayRevenue, Colors.orange, dark),
              _buildRevenueItem('Ce Mois', stats.monthlyRevenue, Colors.green, dark),
              _buildRevenueItem('Total', stats.totalRevenue, Colors.blue, dark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueItem(String label, double value, Color color, bool dark) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${value.toStringAsFixed(0)} DT',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildOrdersByStatusChart(DashboardStats stats, bool dark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commandes par Statut',
            style: Theme.of(Get.context!).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),
          ...stats.ordersByStatus.entries.map((entry) {
            final status = entry.key;
            final count = entry.value;
            final percentage = stats.totalOrders > 0 
                ? (count / stats.totalOrders * 100) 
                : 0.0;
            
            Color statusColor;
            switch (status) {
              case 'pending':
                statusColor = Colors.amber;
                break;
              case 'preparing':
                statusColor = Colors.blue;
                break;
              case 'ready':
                statusColor = Colors.cyan;
                break;
              case 'delivered':
                statusColor = Colors.green;
                break;
              case 'cancelled':
                statusColor = Colors.red;
                break;
              default:
                statusColor = Colors.grey;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.spaceBtwItems),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_getStatusLabel(status)),
                      Text('$count (${percentage.toStringAsFixed(1)}%)'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: statusColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTopProducts(DashboardStats stats, bool dark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Produits les Plus Vendus',
            style: Theme.of(Get.context!).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),
          if (stats.topProducts.isEmpty)
            const Text('Aucun produit pour le moment')
          else
            ...stats.topProducts.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  product['productName'] as String? ?? 'Produit inconnu',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  product['categoryName'] as String? ?? 'Sans catégorie',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                trailing: Text(
                  '${product['totalQuantity']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildSystemStats(DashboardStats stats, bool dark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques Établissement',
            style: Theme.of(Get.context!).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),
          _buildSystemStatItem('Total Produits', stats.totalProducts.toString(), Iconsax.box),
          _buildSystemStatItem('Produits Stock Faible', stats.lowStockProducts.toString(), Iconsax.warning_2),
          _buildSystemStatItem('Valeur Moyenne Commande', '${stats.averageOrderValue.toStringAsFixed(2)} DT', Iconsax.dollar_circle),
          _buildSystemStatItem('Commandes Aujourd\'hui', stats.ordersToday.toString(), Iconsax.calendar),
          _buildSystemStatItem('Commandes Ce Mois', stats.ordersThisMonth.toString(), Iconsax.chart_2),
        ],
      ),
    );
  }

  Widget _buildSystemStatItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spaceBtwItems),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSizes.spaceBtwItems),
          Expanded(
            child: Text(
              label,
              style: Theme.of(Get.context!).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(Get.context!).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders(DashboardStats stats, bool dark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Commandes Récentes',
            style: Theme.of(Get.context!).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),
          if (stats.recentOrders.isEmpty)
            const Text('Aucune commande récente')
          else
            ...stats.recentOrders.map((order) {
              return Card(
                margin: const EdgeInsets.only(bottom: AppSizes.spaceBtwItems),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(order['status'] as String).withOpacity(0.1),
                    child: Icon(
                      Iconsax.shopping_bag,
                      color: _getStatusColor(order['status'] as String),
                    ),
                  ),
                  title: Text('Commande #${(order['id'] as String).substring(0, 8)}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(order['total_amount'] as num?)?.toDouble().toStringAsFixed(2)} DT',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        _getStatusLabel(order['status'] as String),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(order['status'] as String),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'preparing':
        return 'En préparation';
      case 'ready':
        return 'Prête';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      case 'refused':
        return 'Refusée';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.amber;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.cyan;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'refused':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOrdersByDay(DashboardStats stats, bool dark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.calendar, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Jours avec le Plus de Commandes',
                style: Theme.of(Get.context!).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),
          if (stats.ordersByDay.isEmpty)
            const Text('Aucune donnée disponible')
          else
            ...stats.ordersByDay.asMap().entries.map((entry) {
              final index = entry.key;
              final dayData = entry.value;
              final day = dayData['day'] as String? ?? 'Inconnu';
              final count = dayData['count'] as int? ?? 0;
              final maxCount = stats.ordersByDay.isNotEmpty 
                  ? (stats.ordersByDay[0]['count'] as int? ?? 1)
                  : 1;
              final percentage = maxCount > 0 ? (count / maxCount * 100) : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spaceBtwItems),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              day,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$count commande${count > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 6,
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildPickupHours(DashboardStats stats, bool dark) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.clock, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Heures de Pickup les Plus Fréquentes',
                style: Theme.of(Get.context!).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),
          if (stats.pickupHours.isEmpty)
            const Text('Aucune donnée disponible')
          else
            ...stats.pickupHours.asMap().entries.map((entry) {
              final index = entry.key;
              final hourData = entry.value;
              final hour = hourData['hour'] as String? ?? 'Inconnu';
              final count = hourData['count'] as int? ?? 0;
              final maxCount = stats.pickupHours.isNotEmpty 
                  ? (stats.pickupHours[0]['count'] as int? ?? 1)
                  : 1;
              final percentage = maxCount > 0 ? (count / maxCount * 100) : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spaceBtwItems),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              hour,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$count commande${count > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      minHeight: 6,
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

