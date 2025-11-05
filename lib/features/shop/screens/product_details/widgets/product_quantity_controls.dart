import 'package:caferesto/features/shop/controllers/product/panier_controller.dart';
import 'package:caferesto/features/shop/models/produit_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductQuantityControls extends StatelessWidget {
  const ProductQuantityControls({
    super.key,
    required this.product,
    required this.dark,
    required this.onDecrement,
    required this.onIncrement,
  });

  final ProduitModel product;
  final bool dark;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;

    return Obx(() {
      // Safety check: ensure controller is initialized
      if (!Get.isRegistered<CartController>()) {
        return const SizedBox.shrink();
      }
      // Utiliser obtenirQuantiteTemporaire qui gère correctement les variations et quantités temporaires
      final quantity = controller.obtenirQuantiteTemporaire(product);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: dark
              ? Colors.green.shade900.withOpacity(0.2)
              : Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dark ? Colors.green.shade800 : Colors.green.shade100,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Decrement Button
            GestureDetector(
              onTap: quantity > 0 ? onDecrement : null,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: quantity > 0
                      ? (dark ? Colors.green.shade800 : Colors.green.shade100)
                      : (dark ? Colors.grey.shade800 : Colors.grey.shade100),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.remove_rounded,
                  size: 16,
                  color: quantity > 0
                      ? (dark ? Colors.green.shade200 : Colors.green.shade800)
                      : (dark ? Colors.grey.shade500 : Colors.grey.shade400),
                ),
              ),
            ),

            /// Quantity Display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                quantity.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: dark ? Colors.white : Colors.black,
                ),
              ),
            ),

            /// Increment Button
            GestureDetector(
              onTap: onIncrement,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: dark ? Colors.green.shade800 : Colors.green.shade100,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.green.shade200.withOpacity(dark ? 0.3 : 0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: dark ? Colors.green.shade200 : Colors.green.shade800,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
