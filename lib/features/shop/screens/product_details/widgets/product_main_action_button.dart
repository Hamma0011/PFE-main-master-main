import 'package:caferesto/features/shop/controllers/product/panier_controller.dart';
import 'package:caferesto/features/shop/models/produit_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductMainActionButton extends StatelessWidget {
  const ProductMainActionButton({
    super.key,
    required this.product,
    required this.isSmallScreen,
    required this.onTap,
  });

  final ProduitModel product;
  final bool isSmallScreen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;

    return Obx(() {
      // Safety check: ensure controller is initialized
      if (!Get.isRegistered<CartController>()) {
        return const SizedBox.shrink();
      }
      
      // Pour les produits variables, vérifier la quantité de la variation sélectionnée
      // Pour les produits simples, vérifier la quantité totale
      int quantity;
      if (product.productType == 'variable') {
        final variationController = controller.variationController;
        final selectedSize = variationController.selectedSize.value;
        if (selectedSize.isNotEmpty) {
          quantity = controller.obtenirQuantiteVariationDansPanier(product.id, selectedSize);
        } else {
          quantity = 0; // Pas de taille sélectionnée = pas dans le panier
        }
      } else {
        quantity = controller.obtenirQuantiteProduitDansPanier(product.id);
      }
      
      final hasItems = quantity > 0;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hasItems
                    ? [Colors.green.shade600, Colors.green.shade800]
                    : [Colors.green, Colors.green.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade300.withOpacity(0.5),
                  blurRadius: hasItems ? 15 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                /// Button Content - Responsive layout
                if (isSmallScreen && hasItems)
                  // Small screen with items - compact layout
                  Icon(
                    Icons.shopping_cart_checkout_rounded,
                    color: Colors.white,
                    size: 20,
                  )
                else if (isSmallScreen)
                  // Small screen without items - compact layout
                  Icon(
                    Icons.add_shopping_cart_rounded,
                    color: Colors.white,
                    size: 20,
                  )
                else
                  // Normal screen - full layout with flexible text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasItems
                            ? Icons.shopping_cart_checkout_rounded
                            : Icons.add_shopping_cart_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            hasItems
                                ? 'Commander'
                                : 'Ajouter au panier',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                /// Badge for small screen when items exist
                if (isSmallScreen && hasItems)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          quantity.toString(),
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

