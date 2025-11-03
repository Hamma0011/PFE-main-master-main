// // features/shop/services/product_data_service.dart
// import 'package:get/get.dart';
// import '../../../data/repositories/product/produit_repository.dart';
// import '../../features/shop/models/category_model.dart';
// import '../../features/shop/models/etablissement_model.dart';
// import '../../features/shop/models/produit_model.dart';

// class ProductDataService extends GetxService {
//   static ProductDataService get instance => Get.find();

//   final ProduitRepository _repo = Get.find();

//   // DONNÉES PARTAGÉES
//   final RxList<ProduitModel> _allProducts = <ProduitModel>[].obs;
//   final RxList<CategoryModel> _categories = <CategoryModel>[].obs;
//   final RxList<Etablissement> _etablissements = <Etablissement>[].obs;

//   // ÉTATS DE CHARGEMENT
//   final RxBool _isProductsLoaded = false.obs;
//   final RxBool _isFiltersLoaded = false.obs;

//   // GETTERS POUR L'ACCÈS EXTERNE
//   List<ProduitModel> get allProducts => _allProducts.toList();
//   List<CategoryModel> get categories => _categories.toList();
//   List<Etablissement> get etablissements => _etablissements.toList();
//   bool get isDataLoaded => _isProductsLoaded.value && _isFiltersLoaded.value;

//   @override
//   void onInit() {
//     super.onInit();
//     // Charger les données au démarrage
//     loadAllData();
//   }

//   // CHARGEMENT UNIQUE DE TOUTES LES DONNÉES
//   Future<void> loadAllData() async {
//     await Future.wait([
//       loadProductsWithRelations(),
//       loadFilterData(),
//     ]);
//   }

//   // CHARGEMENT DES PRODUITS AVEC RELATIONS
//   Future<void> loadProductsWithRelations() async {
//     if (_isProductsLoaded.value) return;

//     try {
//       print('🔄 Chargement des produits avec relations...');
//       final products = await _repo.getAllProductsWithRelations();
//       _allProducts.assignAll(products);
//       _isProductsLoaded.value = true;
      
//       print('${products.length} produits chargés avec relations');
//     } catch (e) {
//       print('Erreur chargement produits: $e');
//     }
//   }

//   // CHARGEMENT DES DONNÉES DE FILTRES
//   Future<void> loadFilterData() async {
//     if (_isFiltersLoaded.value) return;

//     try {
//       print('🔄 Chargement des données de filtres...');
//       final [categoriesData, etablissementsData] = await Future.wait([
//         _repo.getAllCategoriesWithIds(),
//         _repo.getAllEtablissementsWithIds(),
//       ]);

//       _categories.assignAll(categoriesData);
//       _etablissements.assignAll(etablissementsData);
//       _isFiltersLoaded.value = true;

//       print('${categoriesData.length} catégories et ${etablissementsData.length} établissements chargés');
//     } catch (e) {
//       print('Erreur chargement filtres: $e');
//     }
//   }

//   // MÉTHODES DE RECHERCHE ET FILTRES
//   List<ProduitModel> searchProducts({
//     String? query,
//     String? categoryId,
//     String? etablissementId,
//     String? sortBy,
//   }) {
//     if (!_isProductsLoaded.value) return [];

//     List<ProduitModel> results = List.from(_allProducts);

//     // Recherche textuelle
//     if (query != null && query.isNotEmpty) {
//       results = results.where((p) {
//         final name = p.name.toLowerCase();
//         final desc = p.description?.toLowerCase() ?? '';
//         final etabName = p.etablissement?.name.toLowerCase() ?? '';

//         return name.contains(query.toLowerCase()) ||
//             desc.contains(query.toLowerCase()) ||
//             etabName.contains(query.toLowerCase());
//       }).toList();
//     }

//     // Filtre par catégorie
//     if (categoryId != null && categoryId.isNotEmpty) {
//       results = results.where((p) => p.categoryId == categoryId).toList();
//     }

//     // Filtre par établissement
//     if (etablissementId != null && etablissementId.isNotEmpty) {
//       results = results.where((p) => p.etablissementId == etablissementId).toList();
//     }

//     // Tri
//     if (sortBy != null && sortBy.isNotEmpty) {
//       results = _sortProducts(results, sortBy);
//     }

//     return results;
//   }

//   List<ProduitModel> _sortProducts(List<ProduitModel> products, String sortBy) {
//     switch (sortBy) {
//       case 'Prix ↑':
//         return products..sort((a, b) => _getEffectivePrice(a).compareTo(_getEffectivePrice(b)));
//       case 'Prix ↓':
//         return products..sort((a, b) => _getEffectivePrice(b).compareTo(_getEffectivePrice(a)));
//       case 'Nom A-Z':
//         return products..sort((a, b) => a.name.compareTo(b.name));
//       case 'Popularité':
//         return products..sort((a, b) {
//           final aScore = a.isFeatured == true ? 1 : 0;
//           final bScore = b.isFeatured == true ? 1 : 0;
//           return bScore.compareTo(aScore);
//         });
//       default:
//         return products;
//     }
//   }

//   double _getEffectivePrice(ProduitModel product) {
//     try {
//       if (product.productType == 'single') {
//         if (product.salePrice > 0 && product.salePrice < product.price) {
//           return product.salePrice;
//         }
//         return product.price;
//       }

//       if (product.productType == 'variable' && product.sizesPrices.isNotEmpty) {
//         final prices = product.sizesPrices.map((e) => e.price).toList();
//         prices.sort();
//         return prices.first;
//       }

//       return product.price;
//     } catch (e) {
//       return 0.00;
//     }
//   }

//   // RECHARGEMENT FORCÉ
//   Future<void> refreshData() async {
//     _isProductsLoaded.value = false;
//     _isFiltersLoaded.value = false;
//     await loadAllData();
//   }
// }