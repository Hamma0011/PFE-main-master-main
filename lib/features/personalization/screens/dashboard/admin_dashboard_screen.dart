import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../shop/controllers/dashboard_controller.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardController());
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: TAppBar(
        title: const Text('Dashboard Admin'),
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

                // Utilisateurs les plus fidèles
                _buildTopUsers(stats, dark),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Déterminer le nombre de colonnes selon la largeur de l'écran
        int crossAxisCount;
        double childAspectRatio;
        double iconSize;
        double valueFontSize;
        double titleFontSize;
        
        if (constraints.maxWidth > 1200) {
          // Desktop large
          crossAxisCount = 4;
          childAspectRatio = 3.5;
          iconSize = 16;
          valueFontSize = 14;
          titleFontSize = 10;
        } else if (constraints.maxWidth > 800) {
          // Desktop moyen / Tablette large
          crossAxisCount = 3;
          childAspectRatio = 2.8;
          iconSize = 16;
          valueFontSize = 14;
          titleFontSize = 10;
        } else if (constraints.maxWidth > 600) {
          // Tablette
          crossAxisCount = 2;
          childAspectRatio = 2.5;
          iconSize = 18;
          valueFontSize = 16;
          titleFontSize = 11;
        } else {
          // Mobile
          crossAxisCount = 1;
          childAspectRatio = 3.0;
          iconSize = 20;
          valueFontSize = 18;
          titleFontSize = 12;
        }
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppSizes.sm,
          mainAxisSpacing: AppSizes.sm,
          childAspectRatio: childAspectRatio,
          children: [
            _buildStatCard(
              'Total Commandes',
              stats.totalOrders.toString(),
              Iconsax.shopping_bag,
              Colors.blue,
              dark,
              iconSize: iconSize,
              valueFontSize: valueFontSize,
              titleFontSize: titleFontSize,
            ),
            _buildStatCard(
              'Revenus Total',
              '${stats.totalRevenue.toStringAsFixed(2)} DT',
              Iconsax.dollar_circle,
              Colors.green,
              dark,
              iconSize: iconSize,
              valueFontSize: valueFontSize,
              titleFontSize: titleFontSize,
            ),
            _buildStatCard(
              'Revenus Aujourd\'hui',
              '${stats.todayRevenue.toStringAsFixed(2)} DT',
              Iconsax.calendar,
              Colors.orange,
              dark,
              iconSize: iconSize,
              valueFontSize: valueFontSize,
              titleFontSize: titleFontSize,
            ),
            _buildStatCard(
              'Revenus Ce Mois',
              '${stats.monthlyRevenue.toStringAsFixed(2)} DT',
              Iconsax.chart,
              Colors.purple,
              dark,
              iconSize: iconSize,
              valueFontSize: valueFontSize,
              titleFontSize: titleFontSize,
            ),
            _buildStatCard(
              'Commandes En Attente',
              stats.pendingOrders.toString(),
              Iconsax.clock,
              Colors.amber,
              dark,
              iconSize: iconSize,
              valueFontSize: valueFontSize,
              titleFontSize: titleFontSize,
            ),
            _buildStatCard(
              'Commandes Actives',
              stats.activeOrders.toString(),
              Iconsax.activity,
              Colors.cyan,
              dark,
              iconSize: iconSize,
              valueFontSize: valueFontSize,
              titleFontSize: titleFontSize,
            ),
            _buildStatCard(
              'Établissements',
              stats.totalEtablissements.toString(),
              Iconsax.shop,
              Colors.indigo,
              dark,
              iconSize: iconSize,
              valueFontSize: valueFontSize,
              titleFontSize: titleFontSize,
            ),
            _buildStatCard(
              'Utilisateurs',
              stats.totalUsers.toString(),
              Iconsax.profile_2user,
              Colors.pink,
              dark,
              iconSize: iconSize,
              valueFontSize: valueFontSize,
              titleFontSize: titleFontSize,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool dark, {
    double iconSize = 16,
    double valueFontSize = 14,
    double titleFontSize = 10,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.xs),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkContainer : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(iconSize * 0.4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),
          const SizedBox(width: AppSizes.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: Theme.of(Get.context!).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: valueFontSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontSize: titleFontSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
          }),
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
            }),
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
            'Statistiques Système',
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

  Widget _buildTopUsers(DashboardStats stats, bool dark) {
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
              Icon(Iconsax.profile_2user, color: AppColors.primary),
              const SizedBox(width: AppSizes.sm),
              Text(
                'Utilisateurs les Plus Fidèles',
                style: Theme.of(Get.context!).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          if (stats.topUsers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Center(
                child: Text(
                  'Aucun utilisateur trouvé',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.topUsers.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = stats.topUsers[index];
                final fullName = user['fullName'] as String;
                final email = user['email'] as String;
                final orderCount = user['orderCount'] as int;
                final totalSpent = user['totalSpent'] as double;
                final profileImageUrl = user['profileImageUrl'] as String?;
                
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.xs,
                  ),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : null,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: profileImageUrl == null || profileImageUrl.isEmpty
                        ? Text(
                            fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  title: Text(
                    fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(email, style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Iconsax.shopping_bag, size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  '$orderCount commande${orderCount > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Iconsax.dollar_circle, size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  '${totalSpent.toStringAsFixed(2)} DT',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
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
            }),
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
            }),
        ],
      ),
    );
  }
}

