import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/custom_shapes/containers/search_container.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../../utils/popups/loaders.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../controllers/etablissement_controller.dart';
import '../../controllers/product/order_controller.dart';
import '../../models/order_model.dart';

class GerantOrderManagementScreen extends StatefulWidget {
  const GerantOrderManagementScreen({super.key});

  @override
  State<GerantOrderManagementScreen> createState() =>
      _GerantOrderManagementScreenState();
}

class _GerantOrderManagementScreenState
    extends State<GerantOrderManagementScreen>
    with SingleTickerProviderStateMixin {
  final OrderController orderController = OrderController.instance;
  final UserController userController = Get.find<UserController>();
  final EtablissementController etablissementController =
      EtablissementController.instance;

  String? _currentEtablissementId;

  late TabController _tabController;
  final List<String> _tabLabels = [
    'Toutes',
    'En attente',
    'En cours',
    'Terminées'
  ];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGerantOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGerantOrders() async {
    try {
      // Vérifier le rôle de l'utilisateur
      if (userController.userRole != 'Gérant') {
        Future.delayed(Duration.zero, () {
          TLoaders.errorSnackBar(
            title: "Erreur d'accès",
            message: "Seuls les gérants peuvent accéder à cette page.",
          );
        });
        return;
      }

      // Récupérer l'établissement de l'utilisateur connecté
      final etablissement =
          await etablissementController.getEtablissementUtilisateurConnecte();

      if (etablissement == null ||
          etablissement.id == null ||
          etablissement.id!.isEmpty) {
        Future.delayed(Duration.zero, () {
          TLoaders.errorSnackBar(
            title: "Erreur d'accès",
            message: "Aucun établissement associé à votre compte.",
          );
        });
        return;
      }

      final etablissementId = etablissement.id!;
      _currentEtablissementId = etablissementId;
      debugPrint('🔄 Loading orders for establishment: $etablissementId');
      await orderController.recupererCommandesGerant(etablissementId);
    } catch (e) {
      debugPrint('Error in _loadGerantOrders: $e');
      Future.delayed(Duration.zero, () {
        TLoaders.errorSnackBar(
          title: "Erreur",
          message: "Impossible de charger les commandes: $e",
        );
      });
    }
  }

  List<OrderModel> _getFilteredOrders(int tabIndex) {
    List<OrderModel> filteredOrders;

    // S'assurer que seules les commandes de l'établissement du gérant sont affichées
    List<OrderModel> ordersToFilter = orderController.orders;

    // Filtrer par établissement si on a un ID d'établissement
    if (_currentEtablissementId != null &&
        _currentEtablissementId!.isNotEmpty) {
      ordersToFilter = ordersToFilter
          .where((order) => order.etablissementId == _currentEtablissementId)
          .toList();
    }

    switch (tabIndex) {
      case 0:
        filteredOrders = ordersToFilter;
        break;
      case 1:
        filteredOrders = ordersToFilter
            .where((order) => order.status == OrderStatus.pending)
            .toList();
        break;
      case 2:
        filteredOrders = ordersToFilter
            .where((order) =>
                order.status == OrderStatus.preparing ||
                order.status == OrderStatus.ready)
            .toList();
        break;
      case 3:
        filteredOrders = ordersToFilter
            .where((order) =>
                order.status == OrderStatus.delivered ||
                order.status == OrderStatus.cancelled ||
                order.status == OrderStatus.refused)
            .toList();
        break;
      default:
        filteredOrders = ordersToFilter;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredOrders = filteredOrders
          .where((order) =>
              order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              order.totalAmount.toString().contains(_searchQuery))
          .toList();
    }

    return filteredOrders;
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    // Vérification supplémentaire : seul le gérant peut voir cette page
    if (userController.userRole != 'Gérant') {
      return Scaffold(
        appBar: TAppBar(
          title: Text(
            'Gestion des Commandes',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Iconsax.lock, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Accès restreint',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Seuls les gérants peuvent accéder à cette page.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: TAppBar(
        title: Text(
          'Gestion des Commandes',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _loadGerantOrders,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppSizes.defaultSpace),
            // FIXED: Use the enhanced TSearchContainer with controller
            child: TSearchContainer(
              text: 'Rechercher une commande...',
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Stats Overview
          _buildStatsOverview(),

          // Tab Bar
          Container(
            margin:
                const EdgeInsets.symmetric(horizontal: AppSizes.defaultSpace),
            decoration: BoxDecoration(
              color: dark ? AppColors.dark : AppColors.light,
              borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
                color: AppColors.primary,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: dark ? Colors.white70 : Colors.black54,
              indicatorSize: TabBarIndicatorSize.tab,
            ),
          ),

          const SizedBox(height: AppSizes.spaceBtwItems),

          // Orders List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadGerantOrders,
              child: Obx(() {
                if (orderController.isLoading.value) {
                  return _buildShimmerLoader();
                }

                return TabBarView(
                  controller: _tabController,
                  children: List.generate(_tabLabels.length, (index) {
                    final filteredOrders = _getFilteredOrders(index);

                    if (filteredOrders.isEmpty) {
                      return _buildEmptyState(context, _tabLabels[index]);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.defaultSpace),
                      itemCount: filteredOrders.length,
                      itemBuilder: (_, index) {
                        final order = filteredOrders[index];
                        return _buildOrderCard(order, context, dark);
                      },
                    );
                  }),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // Stats Overview Widget
  Widget _buildStatsOverview() {
    return Obx(() {
      final totalOrders = orderController.orders.length;
      final pendingCount = orderController.commandesEnAttente.length;
      final activeCount = orderController.commandesActives.length;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSizes.defaultSpace),
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
          border: Border.all(color: AppColors.primary.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
                'Total', totalOrders.toString(), Iconsax.shopping_bag),
            _buildStatItem(
                'En attente', pendingCount.toString(), Iconsax.clock),
            _buildStatItem(
                'En cours', activeCount.toString(), Iconsax.activity),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // Shimmer Loading Effect
  Widget _buildShimmerLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.defaultSpace),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 180,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
            ),
          ),
        );
      },
    );
  }

  // Empty State
  Widget _buildEmptyState(BuildContext context, String tabLabel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.receipt_search,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune commande ${tabLabel.toLowerCase()}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Les commandes apparaîtront ici',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
            onPressed: _loadGerantOrders,
          ),
        ],
      ),
    );
  }

  // Beautiful Order Card - Compact
  Widget _buildOrderCard(OrderModel order, BuildContext context, bool dark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
        child: Card(
        elevation: 1,
        margin: const EdgeInsets.only(bottom: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header avec statut et code - Compact
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          order.codeRetrait != null && order.codeRetrait!.isNotEmpty
                              ? '#${order.codeRetrait}'
                              : '#${order.id.substring(0, 8)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          order.formattedOrderDate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                              ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(order.status, context),
                ],
              ),

              const SizedBox(height: 6),

              // Order Details compactes sur une ligne
              _buildOrderDetailsCompact(order, context),

              // Articles commandés - Compact
              _buildItemsPreviewCompact(order, context),

              // Time Slot avec heure d'arrivée estimée
              if (order.pickupDay != null && order.pickupTimeRange != null)
                _buildTimeSlotCompact(order, context),

              const SizedBox(height: 6),

              // Action Buttons
              _buildActionButtons(order, context),
            ],
          ),
        ),
      ),
    );
  }

  // Status Chip - Compact
  Widget _buildStatusChip(OrderStatus status, BuildContext context) {
    final statusConfig = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusConfig.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusConfig.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusConfig.icon, size: 12, color: statusConfig.color),
          const SizedBox(width: 4),
          Text(
            statusConfig.text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: statusConfig.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }

  // Order Details - Compact sur une ligne
  Widget _buildOrderDetailsCompact(OrderModel order, BuildContext context) {
    return FutureBuilder<String?>(
      future: userController.getUserFullName(order.userId),
      builder: (context, snapshot) {
        String clientName;
        if (snapshot.connectionState == ConnectionState.waiting) {
          clientName = '...';
        } else if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty) {
          // Raccourcir le nom si trop long
          final fullName = snapshot.data!;
          clientName = fullName.length > 15 
              ? '${fullName.substring(0, 15)}...' 
              : fullName;
        } else {
          clientName = order.userId.isNotEmpty
              ? 'Client #${order.userId.substring(0, 6)}'
              : 'Client';
        }

        return Row(
          children: [
            // Total
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.money, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  '${order.totalAmount.toStringAsFixed(2)} DT',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Articles
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.shopping_bag, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  '${order.items.length} art.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Client
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.user, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      clientName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Items Preview - Compact
  Widget _buildItemsPreviewCompact(OrderModel order, BuildContext context) {
    if (order.items.isEmpty) {
      return const SizedBox.shrink();
    }

    // Afficher les 2 premiers articles + compteur si plus
    final displayItems = order.items.take(2).toList();
    final remainingCount = order.items.length > 2 ? order.items.length - 2 : 0;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Iconsax.shopping_bag, size: 12, color: Colors.grey.shade700),
              const SizedBox(width: 4),
              Text(
                'Articles:',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      color: Colors.grey.shade700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...displayItems.map((item) {
            // Extraire la taille de la variation si elle existe
            String? taille;
            if (item.selectedVariation != null) {
              taille = item.selectedVariation!['taille'] ?? 
                       item.selectedVariation!['size'] ?? 
                       (item.variationId.isNotEmpty ? item.variationId : null);
            } else if (item.variationId.isNotEmpty) {
              taille = item.variationId;
            }

            // Construire le texte avec ou sans taille
            String itemText = '${item.quantity}x ${item.title}';
            if (taille != null && taille.isNotEmpty) {
              itemText += ' ($taille)';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      itemText,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade800,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  Text(
                    '${(item.price * item.quantity).toStringAsFixed(2)} DT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (remainingCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '+ $remainingCount autre${remainingCount > 1 ? 's' : ''} article${remainingCount > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Time Slot avec heure d'arrivée estimée - Compact
  Widget _buildTimeSlotCompact(OrderModel order, BuildContext context) {
    // Formater l'heure d'arrivée si elle existe (HH:mm:ss -> HH:mm)
    String? formattedArrivalTime;
    if (order.clientArrivalTime != null && order.clientArrivalTime!.isNotEmpty) {
      formattedArrivalTime = order.clientArrivalTime!;
      if (formattedArrivalTime.contains(':')) {
        final timeParts = formattedArrivalTime.split(':');
        if (timeParts.length >= 2) {
          formattedArrivalTime = '${timeParts[0]}:${timeParts[1]}';
        }
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusSm),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Créneau de retrait à gauche
          Icon(Iconsax.clock, color: AppColors.primary, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              "${order.pickupDay!} • ${order.pickupTimeRange!}",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
            ),
          ),
          // Heure d'arrivée estimée à droite sur la même ligne
          if (formattedArrivalTime != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.timer, color: Colors.green.shade700, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    formattedArrivalTime,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }


  // Action Buttons - Compact
  Widget _buildActionButtons(OrderModel order, BuildContext context) {
    return Obx(() {
      final isUpdating = orderController.isUpdating.value;

      switch (order.status) {
        case OrderStatus.pending:
          return Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 36),
                  ),
                  onPressed: isUpdating ? null : () => _acceptOrder(order),
                  child: isUpdating
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.tick_circle, size: 16),
                            const SizedBox(width: 4),
                            const Text("Accepter", style: TextStyle(fontSize: 12)),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 36),
                  ),
                  onPressed: isUpdating
                      ? null
                      : () => _showRefusalDialog(order, context),
                  child: isUpdating
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.close_circle, size: 16),
                            const SizedBox(width: 4),
                            const Text("Refuser", style: TextStyle(fontSize: 12)),
                          ],
                        ),
                ),
              ),
            ],
          );

        case OrderStatus.preparing:
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: const Size(0, 36),
              ),
              onPressed: isUpdating ? null : () => _markAsReady(order),
              child: isUpdating
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.box_tick, size: 16),
                        const SizedBox(width: 4),
                        const Text("Marquer Prête", style: TextStyle(fontSize: 12)),
                      ],
                    ),
            ),
          );

        case OrderStatus.ready:
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: const Size(0, 36),
              ),
              onPressed: isUpdating ? null : () => _markAsDelivered(order),
              child: isUpdating
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.truck_tick, size: 16),
                        const SizedBox(width: 4),
                        const Text("Marquer Livrée", style: TextStyle(fontSize: 12)),
                      ],
                    ),
            ),
          );

        default:
          return const SizedBox.shrink();
      }
    });
  }

  // Status Configuration
  _StatusConfig _getStatusConfig(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return _StatusConfig(
          color: Colors.orange,
          icon: Iconsax.clock,
          text: 'En attente',
        );
      case OrderStatus.preparing:
        return _StatusConfig(
          color: Colors.blue,
          icon: Iconsax.cpu,
          text: 'En préparation',
        );
      case OrderStatus.ready:
        return _StatusConfig(
          color: Colors.green,
          icon: Iconsax.box_tick,
          text: 'Prête',
        );
      case OrderStatus.delivered:
        return _StatusConfig(
          color: Colors.purple,
          icon: Iconsax.truck_tick,
          text: 'Livrée',
        );
      case OrderStatus.cancelled:
        return _StatusConfig(
          color: Colors.red,
          icon: Iconsax.close_circle,
          text: 'Annulée',
        );
      case OrderStatus.refused:
        return _StatusConfig(
          color: Colors.red,
          icon: Iconsax.info_circle,
          text: 'Refusée',
        );
    }
  }

  // Actions
  void _acceptOrder(OrderModel order) {
    orderController.mettreAJourStatutCommande(
      orderId: order.id,
      newStatus: OrderStatus.preparing,
    );
  }

  void _markAsReady(OrderModel order) {
    orderController.mettreAJourStatutCommande(
      orderId: order.id,
      newStatus: OrderStatus.ready,
    );
  }

  void _markAsDelivered(OrderModel order) {
    orderController.mettreAJourStatutCommande(
      orderId: order.id,
      newStatus: OrderStatus.delivered,
    );
  }

  void _showRefusalDialog(OrderModel order, BuildContext context) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser la commande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Veuillez indiquer la raison du refus:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: '...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                TLoaders.warningSnackBar(
                  title: 'Raison requise',
                  message: 'Veuillez indiquer la raison du refus.',
                );
                return;
              }

              orderController.mettreAJourStatutCommande(
                orderId: order.id,
                newStatus: OrderStatus.refused,
                refusalReason: reasonController.text.trim(),
              );
              Get.back();
            },
            child: const Text('Confirmer le refus'),
          ),
        ],
      ),
    );
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  final String text;

  _StatusConfig({
    required this.color,
    required this.icon,
    required this.text,
  });
}
