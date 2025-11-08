import 'package:caferesto/data/repositories/product/produit_repository.dart';
import 'package:caferesto/features/personalization/controllers/user_controller.dart';
import 'package:caferesto/features/shop/models/produit_model.dart';
import 'package:caferesto/features/shop/models/etablissement_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../utils/popups/loaders.dart';
import '../etablissement_controller.dart';

enum ProduitFilter { all, stockables, nonStockables, rupture }

class ProduitController extends GetxController {
  static ProduitController get instance => Get.find();

  // --- FORMULAIRES ET CONTROLLERS ---
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final preparationTimeController = TextEditingController();
  final stockQuantityController = TextEditingController();

  final isStockable = false.obs;
  final selectedCategoryId = Rx<String?>(null);
  final ImagePicker _picker = ImagePicker();
  final pickedImage = Rx<XFile?>(null);

  // --- DÉPENDANCES ---
  final UserController userController = Get.find<UserController>();
  late final ProduitRepository produitRepository;
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _productsChannel;
  RealtimeChannel? _featuredProductsChannel;

  // --- ÉTATS ET LISTES ---
  final isLoading = false.obs;
  RxList<ProduitModel> allProducts = <ProduitModel>[].obs;
  RxList<ProduitModel> filteredProducts = <ProduitModel>[].obs;
  final Rx<ProduitFilter> selectedFilter = ProduitFilter.all.obs;
  final RxString searchQuery = ''.obs;
  RxList<ProduitModel> featuredProducts = <ProduitModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    produitRepository = Get.put(ProduitRepository());
    fetchFeaturedProducts();
    _subscribeToRealtimeProducts();
    _subscribeToRealtimeFeaturedProducts();
  }

  @override
  void onClose() {
    _unsubscribeFromRealtime();
    nameController.dispose();
    descriptionController.dispose();
    preparationTimeController.dispose();
    stockQuantityController.dispose();
    super.onClose();
  }

  void filterProducts(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  void applyFilters() {
    List<ProduitModel> filtered = allProducts;

    // Appliquer la recherche par nom
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((product) =>
              product.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    // Appliquer le filtre sélectionné
    switch (selectedFilter.value) {
      case ProduitFilter.stockables:
        filtered = filtered.where((product) => product.isStockable).toList();
        break;
      case ProduitFilter.nonStockables:
        filtered = filtered.where((product) => !product.isStockable).toList();
        break;
      case ProduitFilter.rupture:
        filtered = filtered
            .where(
                (product) => product.isStockable && product.stockQuantity <= 0)
            .toList();
        break;
      case ProduitFilter.all:
    }

    filteredProducts.assignAll(filtered);
  }

  void updateFilter(ProduitFilter filter) {
    selectedFilter.value = filter;
    applyFilters();
  }

  // --- IMAGE ---
  Future<void> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        pickedImage.value = XFile(pickedFile.path);
      }
    } catch (e) {
      TLoaders.errorSnackBar(
          message: "Erreur lors de la sélection de l'image: $e");
    }
  }

  Future<String?> uploadProductImage(XFile imageFile) async {
    try {
      return await produitRepository.uploadProductImage(imageFile);
    } catch (e) {
      TLoaders.errorSnackBar(message: "Erreur lors de l'upload de l'image: $e");
      return null;
    }
  }

// --- CHARGEMENT DES PRODUITS PAR RÔLE ---
  Future<void> loadProductsByRole() async {
    try {
      isLoading.value = true;

      final userRole = userController.user.value.role;

      if (userRole == 'Admin') {
        // Admin voit tous les produits
        await fetchProducts();
      } else if (userRole == 'Gérant') {
        // Gérant ne voit que ses propres produits
        final etablissementId = await getEtablissementIdUtilisateur();
        if (etablissementId != null) {
          final products = await fetchProductsByEtablissement(etablissementId);
          allProducts.assignAll(products);
          filteredProducts.assignAll(products);
        } else {
          allProducts.clear();
          filteredProducts.clear();
          TLoaders.errorSnackBar(
              message:
                  "Impossible de récupérer les produits de votre établissement");
        }
      } else {
        allProducts.clear();
        filteredProducts.clear();
      }

      applyFilters();
    } catch (e) {
      TLoaders.errorSnackBar(
          message: 'Erreur lors du chargement des produits: $e');
      allProducts.clear();
      filteredProducts.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // --- CHARGEMENT DES PRODUITS ---
  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;
      final productsList = await produitRepository.getAllProducts();

      // Optimisation: Charger tous les établissements manquants en batch
      final productsWithEtab = await _loadEtablissementsBatch(productsList);

      allProducts.assignAll(productsWithEtab);
      filteredProducts.assignAll(productsWithEtab);
    } catch (e) {
      TLoaders.errorSnackBar(
          message: 'Erreur lors du chargement des produits: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<ProduitModel>> fetchProductsByEtablissement(
      String etablissementId) async {
    try {
      final products =
          await produitRepository.getProductsByEtablissement(etablissementId);

      // Optimisation: Charger l'établissement une seule fois pour tous les produits
      Etablissement? etablissement;
      if (products.isNotEmpty && products.any((p) => p.etablissement == null)) {
        try {
          final etabResponse = await _supabase
              .from('etablissements')
              .select('*')
              .eq('id', etablissementId)
              .maybeSingle();
          
          if (etabResponse != null) {
            etablissement = Etablissement.fromJson(etabResponse);
          }
        } catch (e) {
          print('Erreur chargement établissement: $e');
        }
      }

      // Assigner l'établissement à tous les produits qui en ont besoin
      return products.map((produit) {
        if (produit.etablissement == null && etablissement != null) {
          return produit.copyWith(etablissement: etablissement);
        }
        return produit;
      }).toList();
    } catch (e) {
      TLoaders.errorSnackBar(message: 'Erreur: $e');
      return [];
    }
  }

  Future<List<ProduitModel>> getProductsByCategory(String categoryId) async {
    try {
      return await produitRepository.getProductsByCategory(categoryId);
    } catch (e) {
      TLoaders.errorSnackBar(message: 'Erreur: $e');
      return [];
    }
  }

  // --- ÉTABLISSEMENT ---
  Future<String?> getEtablissementIdUtilisateur() async {
    try {
      final etablissementController = Get.find<EtablissementController>();
      final etablissement =
          await etablissementController.getEtablissementUtilisateurConnecte();

      if (etablissement == null) {
        TLoaders.errorSnackBar(
            message:
                "Aucun établissement trouvé. Veuillez d'abord créer un établissement.");
        return null;
      }

      return etablissement.id;
    } catch (e) {
      TLoaders.errorSnackBar(
          message: "Erreur lors de la récupération de l'établissement: $e");
      return null;
    }
  }

  // --- AJOUT / MODIFICATION / SUPPRESSION ---
  Future<bool> addProduct(ProduitModel produit) async {
    if (!_hasProductManagementPermission()) {
      TLoaders.errorSnackBar(
          message: "Vous n'avez pas la permission d'ajouter un produit.");
      return false;
    }

    if (produit.name.isEmpty) {
      TLoaders.errorSnackBar(
          message: "Le nom du produit ne peut pas être vide.");
      return false;
    }

    if (produit.etablissementId.isEmpty) {
      TLoaders.errorSnackBar(message: "ID d'établissement manquant.");
      return false;
    }

    try {
      isLoading.value = true;
      final newProduct = await produitRepository.addProduct(produit);
      featuredProducts.add(newProduct);
      fetchFeaturedProducts();
      loadProductsByRole();
      Get.back(result: true);
      TLoaders.successSnackBar(
          message: 'Produit "${produit.name}" ajouté avec succès');
      return true;
    } catch (e) {
      TLoaders.errorSnackBar(message: "Erreur lors de l'ajout: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProduct(ProduitModel produit) async {
    if (!_hasProductManagementPermission()) {
      TLoaders.errorSnackBar(
          message: "Vous n'avez pas la permission de modifier un produit.");
      return false;
    }

    if (produit.name.isEmpty) {
      TLoaders.errorSnackBar(
          message: "Le nom du produit ne peut pas être vide.");
      return false;
    }

    try {
      isLoading.value = true;

      // Si l'utilisateur est Admin, préserver l'établissement original du produit
      final userRole = userController.user.value.role;
      if (userRole == 'Admin') {
        // Récupérer le produit original depuis la base de données
        final originalProduct =
            await produitRepository.getProductById(produit.id);
        if (originalProduct != null) {
          // Préserver l'établissement original
          produit = produit.copyWith(
            etablissementId: originalProduct.etablissementId,
          );
        }
      }

      await produitRepository.updateProduct(produit);
      await loadProductsByRole();
      Get.back(result: true);
      TLoaders.successSnackBar(
          message: 'Produit "${produit.name}" modifié avec succès');
      return true;
    } catch (e) {
      TLoaders.errorSnackBar(message: "Erreur lors de la modification: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch Products
  void fetchFeaturedProducts() async {
    try {
      // Show loader while loading products
      isLoading.value = true;

      // Fetch most ordered products instead of featured products (top 10 des 30 derniers jours)
      final products =
          await produitRepository.getMostOrderedProductsWithDetails(
        days: 30,
        limit: 10,
      );

      if (products.isEmpty) {
        featuredProducts.clear();
        isLoading.value = false;
        return;
      }

      // Charger l'établissement pour chaque produit si manquant avec gestion d'erreur
      final productsWithEtab = <ProduitModel>[];
      for (final produit in products) {
        try {
          ProduitModel finalProduct = produit;
          if (produit.etablissement == null &&
              produit.etablissementId.isNotEmpty) {
            finalProduct = await _loadEtablissementForProduct(produit);
          }
          productsWithEtab.add(finalProduct);
        } catch (e) {
          debugPrint(
              'Erreur lors du chargement de l\'établissement pour le produit ${produit.id}: $e');
          // Ajouter le produit même si l'établissement n'a pas pu être chargé
          productsWithEtab.add(produit);
        }
      }

      // Assign products
      featuredProducts.assignAll(productsWithEtab);
    } catch (e) {
      debugPrint('Erreur lors du chargement des produits populaires: $e');
      // Ne pas afficher de snackbar pour éviter de spammer l'utilisateur
      // mais garder une liste vide
      featuredProducts.clear();
    } finally {
      // Hide loader after loading products
      isLoading.value = false;
    }
  }

  Future<void> deleteProduct(String productId) async {
    if (!_hasProductManagementPermission()) {
      TLoaders.errorSnackBar(
          message: "Vous n'avez pas la permission de supprimer un produit.");
      return;
    }

    try {
      isLoading.value = true;
      await produitRepository.deleteProduct(productId);
      await loadProductsByRole();
      TLoaders.successSnackBar(message: 'Produit supprimé avec succès');
    } catch (e) {
      TLoaders.errorSnackBar(message: "Erreur lors de la suppression: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Mettre à jour le stock d'un produit à une valeur absolue
  Future<bool> updateProductStockQuantity(
      String productId, int newStock) async {
    if (!_hasProductManagementPermission()) {
      TLoaders.errorSnackBar(
          message: "Vous n'avez pas la permission de modifier le stock.");
      return false;
    }

    try {
      isLoading.value = true;
      await produitRepository.setProductStock(productId, newStock);
      await loadProductsByRole(); // Recharger les produits pour mettre à jour l'affichage
      TLoaders.successSnackBar(message: 'Stock mis à jour avec succès');
      return true;
    } catch (e) {
      TLoaders.errorSnackBar(
          message: "Erreur lors de la mise à jour du stock: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // --- AUTRES OUTILS ---
  bool _hasProductManagementPermission() {
    final userRole = userController.user.value.role;
    return userRole == 'Gérant' || userRole == 'Admin';
  }

  ProduitModel? getProductById(String id) {
    try {
      return allProducts.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  List<ProduitModel> getAvailableProducts() {
    return allProducts.where((product) => product.isAvailable).toList();
  }

  List<ProduitModel> getProductsWithStock() {
    return allProducts
        .where((product) => product.isStockable && product.stockQuantity > 0)
        .toList();
  }

  /// Charger tous les établissements manquants en batch (optimisation)
  Future<List<ProduitModel>> _loadEtablissementsBatch(
      List<ProduitModel> produits) async {
    // Identifier les produits qui ont besoin d'établissements
    final produitsNeedingEtab = produits
        .where((p) => p.etablissement == null && p.etablissementId.isNotEmpty)
        .toList();

    if (produitsNeedingEtab.isEmpty) {
      return produits; // Tous les établissements sont déjà chargés
    }

    // Récupérer tous les IDs d'établissements uniques
    final etablissementIds = produitsNeedingEtab
        .map((p) => p.etablissementId)
        .toSet()
        .toList();

    if (etablissementIds.isEmpty) {
      return produits;
    }

    try {
      // Charger tous les établissements en UNE seule requête batch
      final etablissementsResponse = await _supabase
          .from('etablissements')
          .select('*')
          .inFilter('id', etablissementIds);

      // Créer une map pour un accès rapide
      final etablissementsMap = <String, Etablissement>{};
      for (var etabData in etablissementsResponse as List) {
        try {
          final etab = Etablissement.fromJson(etabData);
          if (etab.id != null && etab.id!.isNotEmpty) {
            etablissementsMap[etab.id!] = etab;
          }
        } catch (e) {
          debugPrint('Erreur parsing établissement: $e');
        }
      }

      // Assigner les établissements aux produits
      return produits.map((produit) {
        if (produit.etablissement == null &&
            produit.etablissementId.isNotEmpty) {
          final etab = etablissementsMap[produit.etablissementId];
          if (etab != null) {
            return produit.copyWith(etablissement: etab);
          }
        }
        return produit;
      }).toList();
    } catch (e) {
      debugPrint('Erreur chargement batch établissements: $e');
      return produits; // Retourner les produits sans établissements en cas d'erreur
    }
  }

  /// Charger l'établissement pour un produit si manquant (méthode legacy pour temps réel)
  Future<ProduitModel> _loadEtablissementForProduct(
      ProduitModel produit) async {
    if (produit.etablissement != null || produit.etablissementId.isEmpty) {
      return produit;
    }

    try {
      final etabResponse = await _supabase
          .from('etablissements')
          .select('*')
          .eq('id', produit.etablissementId)
          .single();

      final etab = Etablissement.fromJson(etabResponse);
      return produit.copyWith(etablissement: etab);
    } catch (e) {
      debugPrint('Erreur chargement établissement pour produit: $e');
    }
    return produit;
  }

  /// Subscription temps réel pour tous les produits
  void _subscribeToRealtimeProducts() {
    _productsChannel = _supabase.channel('produit_controller_products');

    _productsChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'produits',
      callback: (payload) async {
        final eventType = payload.eventType;
        final newData = payload.newRecord;
        final oldData = payload.oldRecord;

        try {
          if (eventType == PostgresChangeEvent.insert) {
            var produit = ProduitModel.fromMap(newData);
            // Charger l'établissement si manquant
            if (produit.etablissement == null &&
                produit.etablissementId.isNotEmpty) {
              produit = await _loadEtablissementForProduct(produit);
            }
            final index = allProducts.indexWhere((p) => p.id == produit.id);
            if (index == -1) {
              allProducts.insert(0, produit);
            } else {
              allProducts[index] = produit;
            }
            allProducts.refresh();
            applyFilters();
          } else if (eventType == PostgresChangeEvent.update) {
            var produit = ProduitModel.fromMap(newData);
            // Charger l'établissement si manquant
            if (produit.etablissement == null &&
                produit.etablissementId.isNotEmpty) {
              produit = await _loadEtablissementForProduct(produit);
            }
            final index = allProducts.indexWhere((p) => p.id == produit.id);
            if (index != -1) {
              allProducts[index] = produit;
              allProducts.refresh();
              applyFilters();
            }
          } else if (eventType == PostgresChangeEvent.delete) {
            final id = oldData['id']?.toString();
            if (id != null) {
              allProducts.removeWhere((p) => p.id == id);
              allProducts.refresh();
              applyFilters();
            }
          }
        } catch (e) {
          debugPrint('Erreur traitement changement produit temps réel: $e');
        }
      },
    );

    _productsChannel!.subscribe();
  }

  /// Subscription temps réel pour les produits featured
  void _subscribeToRealtimeFeaturedProducts() {
    _featuredProductsChannel = _supabase.channel('produit_controller_featured');

    _featuredProductsChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'produits',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'is_featured',
        value: true,
      ),
      callback: (payload) async {
        final eventType = payload.eventType;
        final newData = payload.newRecord;
        final oldData = payload.oldRecord;

        try {
          if (eventType == PostgresChangeEvent.insert) {
            var produit = ProduitModel.fromMap(newData);
            // Charger l'établissement si manquant
            if (produit.etablissement == null &&
                produit.etablissementId.isNotEmpty) {
              produit = await _loadEtablissementForProduct(produit);
            }
            if (produit.isFeatured == true) {
              final index =
                  featuredProducts.indexWhere((p) => p.id == produit.id);
              if (index == -1) {
                featuredProducts.insert(0, produit);
              } else {
                featuredProducts[index] = produit;
              }
              featuredProducts.refresh();
            }
          } else if (eventType == PostgresChangeEvent.update) {
            var produit = ProduitModel.fromMap(newData);
            // Charger l'établissement si manquant
            if (produit.etablissement == null &&
                produit.etablissementId.isNotEmpty) {
              produit = await _loadEtablissementForProduct(produit);
            }
            final index =
                featuredProducts.indexWhere((p) => p.id == produit.id);
            if (produit.isFeatured == true) {
              if (index != -1) {
                featuredProducts[index] = produit;
              } else {
                featuredProducts.insert(0, produit);
              }
            } else {
              if (index != -1) {
                featuredProducts.removeAt(index);
              }
            }
            featuredProducts.refresh();
          } else if (eventType == PostgresChangeEvent.delete) {
            final id = oldData['id']?.toString();
            if (id != null) {
              featuredProducts.removeWhere((p) => p.id == id);
              featuredProducts.refresh();
            }
          }
        } catch (e) {
          debugPrint(
              'Erreur traitement changement produit featured temps réel: $e');
        }
      },
    );

    _featuredProductsChannel!.subscribe();
  }

  /// Désabonnement des subscriptions temps réel
  void _unsubscribeFromRealtime() {
    if (_productsChannel != null) {
      _supabase.removeChannel(_productsChannel!);
      _productsChannel = null;
    }
    if (_featuredProductsChannel != null) {
      _supabase.removeChannel(_featuredProductsChannel!);
      _featuredProductsChannel = null;
    }
  }

  Future<List<String>> pickMultipleImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> files = await picker.pickMultiImage(imageQuality: 75);

      if (files.isEmpty) return [];

      // Upload chaque image sur Supabase ou ton stockage
      final List<String> uploadedUrls = [];
      for (final file in files) {
        final imageUrl = await uploadProductImage(XFile(file.path));
        if (imageUrl != null) uploadedUrls.add(imageUrl);
      }

      return uploadedUrls;
    } catch (e) {
      debugPrint('Erreur sélection multiples images: $e');
      return [];
    }
  }

  /// Fetch Products
  Future<List<ProduitModel>> fetchAllFeaturedProducts() async {
    try {
      // Fetch most ordered products instead of featured products (limite plus élevée pour la page "Tous les produits")
      final products =
          await produitRepository.getMostOrderedProductsWithDetails(
        days: 30,
        limit: 100, // Limite plus élevée pour la page "Tous les produits"
      );

      // Charger l'établissement pour chaque produit si manquant avec gestion d'erreur
      final productsWithEtab = <ProduitModel>[];
      for (final produit in products) {
        try {
          ProduitModel finalProduct = produit;
          if (produit.etablissement == null &&
              produit.etablissementId.isNotEmpty) {
            finalProduct = await _loadEtablissementForProduct(produit);
          }
          productsWithEtab.add(finalProduct);
        } catch (e) {
          debugPrint(
              'Erreur lors du chargement de l\'établissement pour le produit ${produit.id}: $e');
          // Ajouter le produit même si l'établissement n'a pas pu être chargé
          productsWithEtab.add(produit);
        }
      }

      return productsWithEtab;
    } catch (e) {
      debugPrint(
          'Erreur lors du chargement de tous les produits populaires: $e');
      // Ne pas afficher de snackbar pour éviter de spammer l'utilisateur
      return [];
    }
  }

  String? calculateSalePercentage(double originalPrice, double salePrice) {
    // Si pas de réduction, on ne renvoie rien
    if (salePrice <= 0 || salePrice >= originalPrice) return null;

    final percent = ((originalPrice - salePrice) / originalPrice) * 100;
    return percent.toStringAsFixed(0);
  }

  /// -- check product stock status
  String getProductStockStatus(int stock, {bool isStockable = true}) {
    // Si le produit n'est pas stockable, toujours afficher "Disponible"
    if (!isStockable) {
      return 'Disponible';
    }
    // Si le produit est stockable, vérifier le stock
    return stock > 0 ? 'En Stock' : 'Hors Stock';
  }

  String getProductPrice(ProduitModel product) {
    try {
      // PRODUIT SIMPLE
      if (product.productType == 'single') {
        // Si promo active
        if (product.salePrice > 0 && product.salePrice < product.price) {
          return product.salePrice.toStringAsFixed(2);
        }
        return product.price.toStringAsFixed(2);
      }

      // PRODUIT AVEC VARIANTES / TAILLES
      if (product.sizesPrices.isNotEmpty) {
        final prices = product.sizesPrices.map((e) => e.price).toList();
        prices.sort();
        final minPrice = prices.first;
        final maxPrice = prices.last;

        // Si toutes les tailles ont le même prix → un seul affichage
        if (minPrice == maxPrice) {
          return minPrice.toStringAsFixed(2);
        }

        // Sinon afficher une plage
        return minPrice.toStringAsFixed(2);
      }

      return product.price.toStringAsFixed(2);
    } catch (e) {
      return "0.00";
    }
  }
}
