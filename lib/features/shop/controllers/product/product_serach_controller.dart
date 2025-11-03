import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../product/all_products_controller.dart';
import '../../models/produit_model.dart';

class ProductSearchController extends GetxController {
  final searchController = TextEditingController();
  final query = ''.obs;
  final searchedProducts = <ProduitModel>[].obs;
  final isLoading = false.obs;

  late final AllProductsController allProductsController;

  @override
  void onInit() {
    super.onInit();
    allProductsController = AllProductsController.instance;

    // Initialiser avec les produits disponibles
    _initializeWithAllProducts();

    // Débounce pour la recherche
    debounce(query, (_) => _filterProducts(),
        time: const Duration(milliseconds: 300));
  }

  // Méthode d'initialisation améliorée
  void _initializeWithAllProducts() {
    if (allProductsController.products.isNotEmpty) {
      searchedProducts.assignAll(allProductsController.products);
    } else {
      // Attendre que les produits soient chargés
      ever(allProductsController.products, (List<ProduitModel> products) {
        if (products.isNotEmpty) {
          searchedProducts.assignAll(products);
        }
      });
    }
  }

  /// Ajout de la méthode refreshSearch manquante
  void refreshSearch() {
    query.value = '';
    searchController.clear();
    _initializeWithAllProducts();
    print(
        '🔄 Recherche rafraîchie - ${searchedProducts.length} produits disponibles');
  }

  /// --- Filtrage des produits amélioré
  void _filterProducts() {
    final allProducts = allProductsController.products;
    final text = query.value.trim().toLowerCase();

    // Si recherche vide, afficher tous les produits
    if (text.isEmpty) {
      searchedProducts.assignAll(allProducts);
      return;
    }

    isLoading.value = true;

    // Recherche synchrone
    final results = allProducts.where((product) {
      return _matchesSearch(product, text);
    }).toList();

    // Mettre à jour les résultats
    searchedProducts.assignAll(results);
    isLoading.value = false;
  }

  // Logique de matching améliorée
  bool _matchesSearch(ProduitModel product, String searchText) {
    if (searchText.isEmpty) return true;

    final searchTerms =
        searchText.split(' ').where((term) => term.isNotEmpty).toList();

    for (final term in searchTerms) {
      final matchesName = product.name.toLowerCase().contains(term);
      final matchesDescription =
          (product.description ?? '').toLowerCase().contains(term);
      final matchesCategory = (product.categoryId).toLowerCase().contains(term);

      // Recherche dans les tailles/prix pour produits variables
      final matchesSizes = product.sizesPrices?.any(
              (sizePrice) => sizePrice.size.toLowerCase().contains(term)) ??
          false;

      // Recherche dans les suppléments
      final matchesSupplements = product.supplements
              ?.any((supplement) => supplement.toLowerCase().contains(term)) ??
          false;

      if (matchesName ||
          matchesDescription ||
          matchesCategory ||
          matchesSizes ||
          matchesSupplements) {
        return true;
      }
    }

    return false;
  }

  /// --- Nettoyer la recherche
  void clearSearch() {
    searchController.clear();
    query.value = '';
    // Réinitialiser avec tous les produits
    searchedProducts.assignAll(allProductsController.products);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
