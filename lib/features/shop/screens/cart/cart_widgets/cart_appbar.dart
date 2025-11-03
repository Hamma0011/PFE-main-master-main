import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../controllers/product/panier_controller.dart';

class CartAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onDeletePressed;
  const CartAppBar({super.key, required this.onDeletePressed});

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;
    return TAppBar(
      title: Text('Panier', style: Theme.of(context).textTheme.headlineSmall),
      showBackArrow: true,
      actions: [
        Obx(() {
          // Safety check: ensure controller is initialized
          if (!Get.isRegistered<CartController>()) {
            return const SizedBox.shrink();
          }
          if (controller.cartItems.isEmpty) return const SizedBox.shrink();
          return IconButton(
            icon: const Icon(Iconsax.trash),
            tooltip: 'Vider le panier',
            onPressed: onDeletePressed,
          );
        }),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
