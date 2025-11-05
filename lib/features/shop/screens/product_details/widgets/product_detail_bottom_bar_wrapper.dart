import 'package:caferesto/features/shop/controllers/product/panier_controller.dart';
import 'package:caferesto/features/shop/models/produit_model.dart';
import 'package:caferesto/features/shop/screens/cart/cart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'product_bottom_bar.dart';

class ProductDetailBottomBarWrapper extends StatelessWidget {
  const ProductDetailBottomBarWrapper({
    super.key,
    required this.product,
    required this.dark,
    required this.isSmallScreen,
    this.onVariationSelected,
  });

  final ProduitModel product;
  final bool dark;
  final bool isSmallScreen;
  final VoidCallback? onVariationSelected;

  void _handleMainAction(CartController controller) {
    if (!controller.peutAjouterProduit(product)) return;

    if (product.productType == 'variable') {
      final hasSelectedVariant = controller.aVarianteSelectionnee();
      if (!hasSelectedVariant) {
        Get.snackbar(
          'Sélection requise',
          'Veuillez choisir une variante avant de continuer',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Si c'est une modification (mode édition), appeler le callback
      if (onVariationSelected != null) {
        onVariationSelected!();
        return;
      }

      // Vérifier si la variation SPÉCIFIQUE est dans le panier (pour le mode ajout)
      final selectedSize = controller.variationController.selectedSize.value;
      if (selectedSize.isNotEmpty) {
        final variationQuantity =
            controller.obtenirQuantiteVariationDansPanier(product.id, selectedSize);
        if (variationQuantity > 0) {
          // Cette variation spécifique est déjà dans le panier, naviguer vers le panier
          Get.to(() => const CartScreen());
          return;
        }
      }
    } else {
      // Pour les produits simples, vérifier si le produit est dans le panier
      final quantity = controller.obtenirQuantiteProduitDansPanier(product.id);
      if (quantity > 0) {
        Get.to(() => const CartScreen());
        return;
      }
    }

    // Ajouter un nouvel article (soit une nouvelle variation soit un nouveau produit)
    // Utiliser ajouterAuPanier qui gère la logique correctement
    controller.ajouterAuPanier(product);
  }

  void _handleIncrement(CartController controller) {
    if (!controller.peutAjouterProduit(product)) return;
    if (product.productType == 'single' || controller.aVarianteSelectionnee()) {
      // Obtenir la quantité temporaire actuelle et l'incrémenter
      final currentQuantity = controller.obtenirQuantiteTemporaire(product);
      controller.mettreAJourQuantiteTemporaire(product, currentQuantity + 1);
    }
  }

  void _handleDecrement(CartController controller) {
    if (product.productType == 'single' || controller.aVarianteSelectionnee()) {
      // Obtenir la quantité temporaire actuelle et la décrémenter
      final currentQuantity = controller.obtenirQuantiteTemporaire(product);
      if (currentQuantity > 0) {
        controller.mettreAJourQuantiteTemporaire(product, currentQuantity - 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use safe instance getter
    final controller = CartController.instance;

    return ProductBottomBar(
      product: product,
      dark: dark,
      isSmallScreen: isSmallScreen,
      onIncrement: () => _handleIncrement(controller),
      onDecrement: () => _handleDecrement(controller),
      onMainAction: () => _handleMainAction(controller),
    );
  }
}
