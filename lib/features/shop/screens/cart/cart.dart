import 'package:caferesto/features/shop/controllers/product/panier_controller.dart';
import 'package:caferesto/features/shop/screens/checkout/checkout.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'cart_widgets/cart_appbar.dart';
import 'cart_widgets/cart_bottom_section.dart';
import 'cart_widgets/cart_header.dart';
import 'cart_widgets/delete_cart_bottomsheet.dart';
import 'cart_widgets/empty_cart_view.dart';

import 'widgets/cart_items.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;

    return Scaffold(
        appBar: CartAppBar(onDeletePressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => DeleteAllBottomSheet(controller: controller),
          );
        }),
        body: Obx(() {
          // Safety check: ensure controller is initialized
          if (!Get.isRegistered<CartController>()) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.cartItems.isEmpty) {
            return const EmptyCartView();
          }
          return Column(
            children: [
              const CartHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.defaultSpace),
                  child: const TCartItems(),
                ),
              ),
            ],
          );
        }),
        bottomNavigationBar: Obx(() {
          // Safety check: ensure controller is initialized
          if (!Get.isRegistered<CartController>()) {
            return const SizedBox.shrink();
          }
          if (controller.cartItems.isEmpty) return const SizedBox.shrink();
          return CartBottomSection(onCheckoutPressed: () {
            Get.to(() => const CheckoutScreen());
          });
        }),
      );
  }
}
