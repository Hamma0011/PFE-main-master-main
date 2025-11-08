import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/repositories/product/produit_repository.dart';
import '../../models/produit_model.dart';
import '../../models/etablissement_model.dart';

class AllProductsController extends GetxController {
  static AllProductsController get instance => Get.find();

  final repository = ProduitRepository.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _productsChannel;
  RealtimeChannel? _brandProductsChannel;
  String? _currentBrandId;

  /// Liste complète des produits
  final RxList<ProduitModel> products = <ProduitModel>[].obs;

  /// Liste temporaire / filtrée pour une marque spécifique
  final RxList<ProduitModel> brandProducts = <ProduitModel>[].obs;
  final RxString selectedBrandCategoryId = ''.obs;

  /// État du chargement
  final RxBool isLoading = false.obs;

  /// Option de tri sélectionnée
  final RxString selectedSortOption = 'Nom'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllProducts();
    _subscribeToRealtimeProducts();
  }

  @override
  void onClose() {
    _unsubscribeFromRealtime();
    super.onClose();
  }

  /// Assigner les produits d'une marque spécifique
  void setBrandProducts(List<ProduitModel> produits) {
    brandProducts.assignAll(produits);
    sortProducts(selectedSortOption.value);
  }

  /// Récupère tous les produits
  Future<void> fetchAllProducts() async {
    try {
      isLoading.value = true;
      final all = await repository.getAllProducts();

      // Optimisation: Charger tous les établissements manquants en batch
      final allWithEtab = await _loadEtablissementsBatch(all);

      products.assignAll(allWithEtab);

      // Trier après assignation
      sortProducts(selectedSortOption.value);
    } catch (e) {
      print("Erreur chargement produits : $e");
      // Assigner une liste vide en cas d'erreur
      products.assignAll([]);
    } finally {
      isLoading.value = false;
    }
  }

  /// Trie les produits selon l'option choisie
  void sortProducts(String sortOption) {
    selectedSortOption.value = sortOption;

    switch (sortOption) {
      case 'Nom':
        products.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Prix croissant':
        products.sort((a, b) {
          final priceA = a.salePrice > 0 ? a.salePrice : a.price;
          final priceB = b.salePrice > 0 ? b.salePrice : b.price;
          return priceA.compareTo(priceB);
        });
        break;
      case 'Prix décroissant':
        products.sort((a, b) {
          final priceA = a.salePrice > 0 ? a.salePrice : a.price;
          final priceB = b.salePrice > 0 ? b.salePrice : b.price;
          return priceB.compareTo(priceA);
        });
        break;
      case 'Récent':
        products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Ventes':
        products.sort((a, b) {
          final salesA = a.salePrice;
          final salesB = b.salePrice;
          return salesB.compareTo(salesA);
        });
        break;
      default:
        products.sort((a, b) => a.name.compareTo(b.name));
    }

    print('Produits triés par: $sortOption');
  }

  /// Récupère et assigne les produits d'une marque spécifique
  Future<void> fetchBrandProducts(String etablissementId) async {
    try {
      // Ne réinitialiser que si ce n'est pas déjà le même établissement
      if (_currentBrandId != etablissementId) {
        isLoading.value = true;
        brandProducts.clear();
      } else if (!isLoading.value) {
        // Si c'est le même établissement mais qu'on n'est pas en train de charger, mettre à jour
        isLoading.value = true;
      }

      // Désabonner de l'ancien établissement si différent
      if (_currentBrandId != null && _currentBrandId != etablissementId) {
        _unsubscribeFromBrandProducts();
      }

      // Appel au dépôt pour récupérer les produits du brand
      final produits =
          await repository.getProductsByEtablissement(etablissementId);

      // Optimisation: Charger l'établissement une seule fois pour tous les produits
      Etablissement? etablissement;
      if (produits.isNotEmpty && produits.any((p) => p.etablissement == null)) {
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
          print('Erreur chargement établissement pour marque: $e');
        }
      }

      // Assigner l'établissement à tous les produits qui en ont besoin
      final produitsWithEtab = produits.map((produit) {
        if (produit.etablissement == null && etablissement != null) {
          return produit.copyWith(etablissement: etablissement);
        }
        return produit;
      }).toList();

      // Assigner à la liste réactive
      brandProducts.assignAll(produitsWithEtab);
      selectedBrandCategoryId.value = '';
      _currentBrandId = etablissementId;

      // S'abonner aux changements temps réel pour cet établissement
      _subscribeToBrandProducts(etablissementId);

      // Trier après assignation (même logique que pour tous les produits)
      sortBrandProducts(selectedSortOption.value);
    } catch (e) {
      print("Erreur chargement produits marque : $e");
      brandProducts.assignAll([]);
    } finally {
      isLoading.value = false;
    }
  }

  /// Produits filtrés par catégorie pour la marque sélectionnée
  List<ProduitModel> get filteredBrandProducts {
    final cat = selectedBrandCategoryId.value;
    if (cat.isEmpty) return brandProducts;
    return brandProducts.where((p) => p.categoryId == cat).toList();
  }

  void setBrandCategoryFilter(String categoryId) {
    selectedBrandCategoryId.value = categoryId;
  }

  /// Trie les produits d'une marque
  void sortBrandProducts(String sortOption) {
    selectedSortOption.value = sortOption;

    switch (sortOption) {
      case 'Nom':
        brandProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Prix croissant':
        brandProducts.sort((a, b) {
          final priceA = a.salePrice > 0 ? a.salePrice : a.price;
          final priceB = b.salePrice > 0 ? b.salePrice : b.price;
          return priceA.compareTo(priceB);
        });
        break;
      case 'Prix décroissant':
        brandProducts.sort((a, b) {
          final priceA = a.salePrice > 0 ? a.salePrice : a.price;
          final priceB = b.salePrice > 0 ? b.salePrice : b.price;
          return priceB.compareTo(priceA);
        });
        break;
      case 'Récent':
        brandProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Ventes':
        brandProducts.sort((a, b) {
          final salesA = a.salePrice;
          final salesB = b.salePrice;
          return salesB.compareTo(salesA);
        });
        break;
      default:
        brandProducts.sort((a, b) => a.name.compareTo(b.name));
    }

    print('Produits de la marque triés par: $sortOption');
  }

  /// Permet d'assigner une nouvelle liste (utilisé dans la recherche)
  void assignProducts(List<ProduitModel> newProducts) {
    products.assignAll(newProducts);
    sortProducts(selectedSortOption.value);
  }

  // Recherche rapide
  List<ProduitModel> searchProducts(String query) {
    if (query.isEmpty) return products;

    final searchText = query.toLowerCase();
    return products.where((product) {
      return product.name.toLowerCase().contains(searchText) ||
          (product.description ?? '').toLowerCase().contains(searchText); // ||
      // (product.categoryName ?? '').toLowerCase().contains(searchText);
    }).toList();
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
          print('Erreur parsing établissement: $e');
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
      print('Erreur chargement batch établissements: $e');
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
      print('Erreur chargement établissement pour produit: $e');
    }
    return produit;
  }

  /// Subscription temps réel pour tous les produits
  void _subscribeToRealtimeProducts() {
    _productsChannel = _supabase.channel('products_changes');

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
            final index = products.indexWhere((p) => p.id == produit.id);
            if (index == -1) {
              products.insert(0, produit);
            } else {
              products[index] = produit;
            }
            products.refresh();
            sortProducts(selectedSortOption.value);
          } else if (eventType == PostgresChangeEvent.update) {
            var produit = ProduitModel.fromMap(newData);
            // Charger l'établissement si manquant
            if (produit.etablissement == null &&
                produit.etablissementId.isNotEmpty) {
              produit = await _loadEtablissementForProduct(produit);
            }
            final index = products.indexWhere((p) => p.id == produit.id);
            if (index != -1) {
              products[index] = produit;
              products.refresh();
              sortProducts(selectedSortOption.value);
            }
          } else if (eventType == PostgresChangeEvent.delete) {
            final id = oldData['id']?.toString();
            if (id != null) {
              products.removeWhere((p) => p.id == id);
              products.refresh();
            }
          }
        } catch (e) {
          print('Erreur traitement changement produit temps réel: $e');
        }
      },
    );

    _productsChannel!.subscribe();
  }

  /// Charger l'établissement pour un produit de marque si manquant
  Future<ProduitModel> _loadEtablissementForBrandProduct(
      ProduitModel produit, String etablissementId) async {
    if (produit.etablissement != null) {
      return produit;
    }

    try {
      final etabResponse = await _supabase
          .from('etablissements')
          .select('*')
          .eq('id', etablissementId)
          .single();

      final etab = Etablissement.fromJson(etabResponse);
      return produit.copyWith(etablissement: etab);
    } catch (e) {
      print('Erreur chargement établissement pour produit marque: $e');
    }
    return produit;
  }

  /// Subscription temps réel pour les produits d'un établissement
  void _subscribeToBrandProducts(String etablissementId) {
    _unsubscribeFromBrandProducts();

    _brandProductsChannel =
        _supabase.channel('brand_products_changes_$etablissementId');

    _brandProductsChannel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'produits',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'etablissement_id',
        value: etablissementId,
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
              produit = await _loadEtablissementForBrandProduct(
                  produit, etablissementId);
            }
            final index = brandProducts.indexWhere((p) => p.id == produit.id);
            if (index == -1) {
              brandProducts.insert(0, produit);
            } else {
              brandProducts[index] = produit;
            }
            brandProducts.refresh();
            sortBrandProducts(selectedSortOption.value);
          } else if (eventType == PostgresChangeEvent.update) {
            var produit = ProduitModel.fromMap(newData);
            // Charger l'établissement si manquant
            if (produit.etablissement == null &&
                produit.etablissementId.isNotEmpty) {
              produit = await _loadEtablissementForBrandProduct(
                  produit, etablissementId);
            }
            final index = brandProducts.indexWhere((p) => p.id == produit.id);
            if (index != -1) {
              brandProducts[index] = produit;
              brandProducts.refresh();
              sortBrandProducts(selectedSortOption.value);
            }
          } else if (eventType == PostgresChangeEvent.delete) {
            final id = oldData['id']?.toString();
            if (id != null) {
              brandProducts.removeWhere((p) => p.id == id);
              brandProducts.refresh();
            }
          }
        } catch (e) {
          print(
              'Erreur traitement changement produit établissement temps réel: $e');
        }
      },
    );

    _brandProductsChannel!.subscribe();
  }

  /// Désabonnement des subscriptions temps réel
  void _unsubscribeFromRealtime() {
    if (_productsChannel != null) {
      _supabase.removeChannel(_productsChannel!);
      _productsChannel = null;
    }
    _unsubscribeFromBrandProducts();
  }

  void _unsubscribeFromBrandProducts() {
    if (_brandProductsChannel != null) {
      _supabase.removeChannel(_brandProductsChannel!);
      _brandProductsChannel = null;
    }
  }
}
