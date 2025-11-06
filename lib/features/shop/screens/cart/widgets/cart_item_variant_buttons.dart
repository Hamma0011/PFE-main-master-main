import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/product/panier_controller.dart';
import '../../../models/cart_item_model.dart';

class CartItemVariantButtons extends StatelessWidget {
  const CartItemVariantButtons({
    super.key,
    required this.cartItem,
    required this.controller,
    required this.onEdit,
    required this.onAdd,
  });

  final CartItemModel cartItem;
  final CartController controller;
  final VoidCallback onEdit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final product = cartItem.product;
    if (product == null) return const SizedBox.shrink();

    return Obx(() {
      // Safety check: ensure controller is initialized
      if (!Get.isRegistered<CartController>()) {
        return const SizedBox.shrink();
      }
      // Vérifie si la variation actuelle est déjà dans le panier
      final currentVariationInCart = controller.estVariationDansPanier(
        cartItem.productId,
        cartItem.variationId,
      );

      // Vérifie si toutes les variations du produit sont déjà dans le panier
      final allVariationsInCart =
          controller.sontToutesVariationsDansPanier(product);

      return Row(
        children: [
          // Modifier (actif uniquement si la variation actuelle est dans le panier)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: currentVariationInCart ? onEdit : null,
              icon: Icon(
                Icons.edit_outlined,
                size: 16,
                color:
                    currentVariationInCart ? Colors.blue.shade400 : Colors.grey,
              ),
              label: Text(
                'Modifier',
                style: TextStyle(
                  fontSize: 12,
                  color: currentVariationInCart
                      ? Colors.blue.shade400
                      : Colors.grey,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                side: BorderSide(
                  color: currentVariationInCart
                      ? Colors.blue.shade400
                      : Colors.grey.shade300,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Ajouter (désactivé seulement si TOUTES les variations sont déjà en panier)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: allVariationsInCart ? null : onAdd,
              icon: Icon(
                Icons.add_circle_outline,
                size: 16,
                color:
                    allVariationsInCart ? Colors.grey : Colors.green.shade400,
              ),
              label: Text(
                'Ajouter',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      allVariationsInCart ? Colors.grey : Colors.green.shade400,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                side: BorderSide(
                  color: allVariationsInCart
                      ? Colors.grey.shade300
                      : Colors.green.shade400,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}
