import 'package:flutter/material.dart';

import '../features/shop/models/produit_model.dart';

class ProduitHelper {
  static String getAffichagePrix(ProduitModel produit) {
    if (produit.isSingle) {
      // Pour les produits simples, afficher le prix soldé s'il existe
      if (produit.salePrice > 0 && produit.salePrice < produit.price) {
        return '${produit.salePrice} DT';
      }
      return '${produit.price} DT';
    } else {
      // Pour les produits avec tailles, garder la logique existante
      if (produit.sizesPrices.isEmpty) return '${produit.price} DT';

      final prix = produit.sizesPrices
          .map((p) => p.price)
          .reduce((a, b) => a < b ? a : b);
      final prixMax = produit.sizesPrices
          .map((p) => p.price)
          .reduce((a, b) => a > b ? a : b);

      return prix == prixMax ? '$prix DT' : '$prix - $prixMax DT';
    }
  }

  static String getAffichageTailles(ProduitModel produit) {
    if (produit.sizesPrices.isEmpty) {
      return 'Aucune taille';
    } else if (produit.sizesPrices.length == 1) {
      return produit.sizesPrices.first.size;
    } else {
      return '${produit.sizesPrices.length} tailles';
    }
  }

  static String getAffichageStock(ProduitModel produit) {
    if (!produit.isStockable) {
      return 'Non stockable';
    } else if (produit.stockQuantity > 0) {
      return 'Stock: ${produit.stockQuantity}';
    } else {
      return 'Rupture de stock';
    }
  }

  static Color getCouleurStock(ProduitModel produit) {
    if (!produit.isStockable) {
      return Colors.grey;
    } else if (produit.stockQuantity > 10) {
      return Colors.green;
    } else if (produit.stockQuantity > 0) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  static String getAffichageTempsPreparation(ProduitModel produit) {
    if (produit.preparationTime == 0) {
      return 'Prêt immédiatement';
    } else if (produit.preparationTime == 1) {
      return '1 minute';
    } else {
      return '${produit.preparationTime} minutes';
    }
  }

  static bool estProduitValide(ProduitModel produit) {
    return produit.name.isNotEmpty &&
        produit.categoryId.isNotEmpty &&
        produit.preparationTime >= 0 &&
        (!produit.isStockable || produit.stockQuantity >= 0);
  }

  static String getStatutProduit(ProduitModel produit) {
    if (!produit.isStockable) {
      return 'Disponible';
    } else if (produit.stockQuantity > 0) {
      return 'En stock';
    } else {
      return 'Rupture';
    }
  }
}
