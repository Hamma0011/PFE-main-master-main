import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../utils/popups/loaders.dart';
import '../../models/order_model.dart';
import '../product/order_controller.dart';

class OrderListController extends GetxController
    with GetTickerProviderStateMixin {
  final orderController = OrderController.instance;

  late TabController tabController;
  final List<String> tabLabels = ['Toutes', 'Actives', 'Terminées'];

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: tabLabels.length, vsync: this);
    loadOrders();
  }

  Future<void> loadOrders() async {
    await orderController.fetchUserOrders();
  }

  List<OrderModel> getFilteredOrders(int index) {
    switch (index) {
      case 1:
        return orderController.activeOrders;
      case 2:
        return orderController.completedOrders;
      default:
        return orderController.orders;
    }
  }

  // Cancel confirmation dialog
  Future<void> showCancelConfirmation(
      BuildContext context, OrderModel order) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text("Annuler la commande"),
        content: const Text(
            "Êtes-vous sûr de vouloir annuler cette commande ? Cette action est irréversible."),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text("Non")),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Oui, annuler"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await orderController.cancelOrder(order.id);
    }
  }

  // ✏️ Edit pickup info dialog
  void showEditDialog(BuildContext context, OrderModel order) {
    final timeController =
        TextEditingController(text: order.pickupTimeRange ?? "");
    final dayController = TextEditingController(text: order.pickupDay ?? "");

    Get.dialog(
      AlertDialog(
        title: const Text("Modifier la commande"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dayController,
              decoration: const InputDecoration(
                labelText: "Jour de retrait",
                hintText: "Ex: Lundi, Mardi...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                labelText: "Plage horaire",
                hintText: "Ex: 14h-15h",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              if (dayController.text.trim().isEmpty ||
                  timeController.text.trim().isEmpty) {
                TLoaders.warningSnackBar(
                  title: "Champs requis",
                  message: "Veuillez remplir tous les champs.",
                );
                return;
              }
              await orderController.updateOrderDetails(
                orderId: order.id,
                pickupDay: dayController.text.trim(),
                pickupTimeRange: timeController.text.trim(),
              );
              Get.back();
              TLoaders.successSnackBar(
                title: "Succès",
                message: "Commande modifiée avec succès",
              );
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }
}
