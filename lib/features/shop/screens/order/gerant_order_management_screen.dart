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

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.defaultSpace),
                      itemCount: filteredOrders.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSizes.spaceBtwItems),
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

  // Beautiful Order Card
  Widget _buildOrderCard(OrderModel order, BuildContext context, bool dark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.codeRetrait != null && order.codeRetrait!.isNotEmpty
                              ? 'Commande ${order.codeRetrait}'
                              : 'Commande',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.formattedOrderDate,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(order.status, context),
                ],
              ),

              const SizedBox(height: 16),

              // Order Details
              _buildOrderDetails(order, context),

              // Time Slot
              if (order.pickupDay != null && order.pickupTimeRange != null)
                _buildTimeSlot(order, context),

              // Items Preview
              _buildItemsPreview(order, context),

              const SizedBox(height: 16),

              // Action Buttons
              _buildActionButtons(order, context),
            ],
          ),
        ),
      ),
    );
  }

  // Status Chip
  Widget _buildStatusChip(OrderStatus status, BuildContext context) {
    final statusConfig = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusConfig.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusConfig.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusConfig.icon, size: 14, color: statusConfig.color),
          const SizedBox(width: 4),
          Text(
            statusConfig.text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: statusConfig.color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  // Order Details
  Widget _buildOrderDetails(OrderModel order, BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDetailItem(
            icon: Iconsax.money,
            label: 'Total',
            value: '${order.totalAmount.toStringAsFixed(2)} DT',
          ),
        ),
        Expanded(
          child: _buildDetailItem(
            icon: Iconsax.shopping_bag,
            label: 'Articles',
            value: '${order.items.length}',
          ),
        ),
        Expanded(
          child: FutureBuilder<String?>(
            future: userController.getUserFullName(order.userId),
            builder: (context, snapshot) {
              String clientName;
              if (snapshot.connectionState == ConnectionState.waiting) {
                clientName = 'Chargement...';
              } else if (snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data!.isNotEmpty) {
                clientName = snapshot.data!;
              } else {
                clientName = order.userId.isNotEmpty
                    ? 'Client #${order.userId.substring(0, 8)}'
                    : 'Client inconnu';
              }

              return _buildDetailItem(
                icon: Iconsax.user,
                label: 'Client',
                value: clientName,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(
      {required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Time Slot
  Widget _buildTimeSlot(OrderModel order, BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Iconsax.clock, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Créneau de retrait",
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${order.pickupDay!} • ${order.pickupTimeRange!}",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Items Preview - FIXED: Use item.title instead of item.product.nom
  Widget _buildItemsPreview(OrderModel order, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Articles commandés:',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          ...order.items.take(3).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        // FIXED: Use item.title instead of item.product.nom
                        '${item.quantity}x ${item.title}',
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      // FIXED: Use item.price instead of item.product.prix
                      '${(item.price * item.quantity).toStringAsFixed(2)} DT',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              )),
          if (order.items.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+ ${order.items.length - 3} autres articles...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  // Action Buttons
  Widget _buildActionButtons(OrderModel order, BuildContext context) {
    return Obx(() {
      final isUpdating = orderController.isUpdating.value;

      switch (order.status) {
        case OrderStatus.pending:
          return Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: isUpdating
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Iconsax.tick_circle, size: 18),
                  label: isUpdating
                      ? const Text("Traitement...")
                      : const Text("Accepter"),
                  onPressed: isUpdating ? null : () => _acceptOrder(order),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: isUpdating
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Iconsax.close_circle, size: 18),
                  label: isUpdating
                      ? const Text("Traitement...")
                      : const Text("Refuser"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isUpdating
                      ? null
                      : () => _showRefusalDialog(order, context),
                ),
              ),
            ],
          );

        case OrderStatus.preparing:
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: isUpdating
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Iconsax.box_tick, size: 18),
              label: isUpdating
                  ? const Text("Mise à jour...")
                  : const Text("Marquer comme Prête"),
              onPressed: isUpdating ? null : () => _markAsReady(order),
            ),
          );

        case OrderStatus.ready:
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: isUpdating
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Iconsax.truck_tick, size: 18),
              label: isUpdating
                  ? const Text("Mise à jour...")
                  : const Text("Marquer comme Livrée"),
              onPressed: isUpdating ? null : () => _markAsDelivered(order),
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
