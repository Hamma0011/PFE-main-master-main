import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../navigation_menu.dart';
import '../../../../../utils/loaders/animation_loader.dart';
import '../../../controllers/commandes/order_list_controller.dart';
import '../../../models/order_model.dart';
import '../order_tracking_screen.dart';

class TOrderListItems extends StatelessWidget {
  const TOrderListItems({super.key});

  @override
  Widget build(BuildContext context) {
    final listController = Get.put(OrderListController());
    final orderController = listController.orderController;
    final dark = THelperFunctions.isDarkMode(context);
    // final AddressController contro = Get.find();

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: dark ? AppColors.darkGrey : AppColors.light,
            borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
          ),
          child: TabBar(
            controller: listController.tabController,
            tabs: listController.tabLabels.map((e) => Tab(text: e)).toList(),
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
              color: AppColors.primary,
            ),
            labelColor: Colors.white,
            unselectedLabelColor: dark ? Colors.white70 : Colors.black54,
            indicatorSize: TabBarIndicatorSize.tab,
          ),
        ),
        const SizedBox(height: AppSizes.spaceBtwSections),

        // Orders List
        Expanded(
          child: RefreshIndicator(
            onRefresh: listController.loadOrders,
            child: Obx(() {
              if (orderController.isLoading.value) {
                return _buildShimmer();
              }

              if (orderController.orders.isEmpty) {
                return _buildEmpty(context);
              }

              return TabBarView(
                controller: listController.tabController,
                children:
                    List.generate(listController.tabLabels.length, (index) {
                  final orders = listController.getFilteredOrders(index);
                  if (orders.isEmpty) {
                    return _buildEmptyTab(
                        context, listController.tabLabels[index]);
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.spaceBtwItems),
                    itemBuilder: (_, i) => _buildOrderCard(
                        context, orders[i], dark, listController),
                  );
                }),
              );
            }),
          ),
        ),
      ],
    );
  }

  // Shimmer loader
  Widget _buildShimmer() {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.all(AppSizes.sm),
      itemBuilder: (_, __) => Shimmer.fromColors(
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
      ),
    );
  }

  // Empty state
  Widget _buildEmpty(BuildContext context) => TAnimationLoaderWidget(
        text: "Aucune commande",
        animation: 'assets/animations/empty_order.json',
        showAction: true,
        actionText: 'Faire des courses',
        onActionPressed: () => Get.offAll(() => const NavigationMenu()),
      );

  Widget _buildEmptyTab(BuildContext context, String label) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.receipt_search, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Aucune commande ${label.toLowerCase()}',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Les commandes apparaîtront ici',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );

  // Order card
  Widget _buildOrderCard(BuildContext context, OrderModel order, bool dark,
      OrderListController listController) {
    final orderController = listController.orderController;
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        onTap: () => Get.to(() => OrderTrackingScreen(order: order)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context, order),
              const SizedBox(height: 16),
              _summary(context, order),
              if (order.pickupDay != null) _timeSlot(context, order),
              if (order.status == OrderStatus.refused &&
                  order.refusalReason != null)
                _refusal(context, order),
              if (order.status == OrderStatus.pending)
                Obx(() => _actions(context, orderController.isUpdating.value,
                    order, listController)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, OrderModel order) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 8,
      children: [
        Flexible(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              order.codeRetrait != null && order.codeRetrait!.isNotEmpty
                  ? 'Commande ${order.codeRetrait}'
                  : 'Commande',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(order.formattedOrderDate,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey.shade600)),
          ]),
        ),
        _statusChip(context, order.status),
      ],
    );
  }

  Widget _summary(BuildContext context, OrderModel order) => Row(
        children: [
          _summaryItem(context, Iconsax.money, 'Total',
              '${order.totalAmount.toStringAsFixed(2)} DT'),
          _summaryItem(context, Iconsax.shopping_bag, 'Articles',
              '${order.items.length}'),
          _summaryItem(context, Iconsax.shop, 'Établissement',
              order.establishmentNameFromItems),
        ],
      );

  Widget _summaryItem(
          BuildContext context, IconData icon, String label, String value) =>
      Expanded(
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.grey.shade600)),
            const SizedBox(height: 2),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ],
        ),
      );

  Widget _statusChip(BuildContext context, OrderStatus status) {
    final config = _status(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.color),
          const SizedBox(width: 4),
          Text(config.text,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: config.color,
                    fontWeight: FontWeight.bold,
                  )),
        ],
      ),
    );
  }

  Widget _timeSlot(BuildContext context, OrderModel order) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
        ),
        child: Row(children: [
          Icon(Iconsax.clock, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Créneau de retrait",
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    )),
            const SizedBox(height: 2),
            Text("${order.pickupDay!} • ${order.pickupTimeRange!}",
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ]),
        ]),
      );

  Widget _refusal(BuildContext context, OrderModel order) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppSizes.cardRadiusMd),
        ),
        child: Row(children: [
          Icon(Iconsax.info_circle, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Commande refusée",
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    )),
            const SizedBox(height: 2),
            Text(order.refusalReason!,
                style: Theme.of(context).textTheme.bodyMedium),
          ]),
        ]),
      );

  Widget _actions(BuildContext context, bool isUpdating, OrderModel order,
      OrderListController controller) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: isUpdating
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Iconsax.edit, size: 18),
              label: Text(isUpdating ? "Modification..." : "Modifier"),
              onPressed: isUpdating
                  ? null
                  : () => controller.showEditDialog(context, order),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              icon: isUpdating
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Iconsax.close_circle, size: 18),
              label: Text(isUpdating ? "Annulation..." : "Annuler"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: isUpdating
                  ? null
                  : () => controller.showCancelConfirmation(context, order),
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _status(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return _StatusConfig(Colors.orange, Iconsax.clock, 'En attente');
      case OrderStatus.preparing:
        return _StatusConfig(Colors.blue, Iconsax.cpu, 'En préparation');
      case OrderStatus.ready:
        return _StatusConfig(Colors.green, Iconsax.box_tick, 'Prête');
      case OrderStatus.delivered:
        return _StatusConfig(Colors.purple, Iconsax.truck_tick, 'Livrée');
      case OrderStatus.cancelled:
        return _StatusConfig(Colors.red, Iconsax.close_circle, 'Annulée');
      case OrderStatus.refused:
        return _StatusConfig(Colors.red, Iconsax.info_circle, 'Refusée');
    }
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;
  final String text;
  _StatusConfig(this.color, this.icon, this.text);
}
