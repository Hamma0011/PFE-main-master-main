import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../utils/popups/loaders.dart';
import '../../models/order_model.dart';
import '../product/order_controller.dart';
import '../product/panier_controller.dart';
import '../../screens/cart/cart.dart';

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
    await orderController.recupererCommandesUtilisateur();
  }

  List<OrderModel> getFilteredOrders(int index) {
    switch (index) {
      case 1:
        return orderController.commandesActives;
      case 2:
        return orderController.commandesTerminees;
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
      await orderController.annulerCommande(order.id);
    }
  }

  // ✏️ Charger la commande dans le panier pour modification
  void showEditDialog(BuildContext context, OrderModel order) {
    // Vérifier que la commande peut être modifiée
    if (!order.canBeModified) {
      TLoaders.warningSnackBar(
        title: "Commande non modifiable",
        message: "Seules les commandes en attente peuvent être modifiées.",
      );
      return;
    }

    // Charger les articles de la commande dans le panier
    final cartController = CartController.instance;
    cartController.chargerArticlesCommandeDansPanier(order.items, order.id);

    // Naviguer vers le panier
    Get.to(() => const CartScreen());

    TLoaders.successSnackBar(
      title: "Commande chargée",
      message: "La commande a été chargée dans votre panier. Vous pouvez maintenant la modifier.",
    );
  }
}
