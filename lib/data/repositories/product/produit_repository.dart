import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/shop/models/category_model.dart';
import '../../../features/shop/models/etablissement_model.dart';
import '../../../features/shop/models/produit_model.dart';
import '../../../features/shop/models/statut_etablissement_model.dart';
import '../../../utils/exceptions/platform_exceptions.dart';
import '../order/order_repository.dart';

class ProduitRepository extends GetxController {
  static ProduitRepository get instance => Get.find();

  /// Variables
  final _db = Supabase.instance.client;
  final _table = 'produits';
  int _page = 1;
  final int _limit = 10;

  /// Charger tous les produits
  Future<List<ProduitModel>> getAllProducts() async {
    try {
      final response = await _db
          .from(_table)
          .select('*, etablissement:etablissement_id(*)')
          .order('created_at', ascending: false);
      return response.map((produit) => ProduitModel.fromMap(produit)).toList();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Echec de récupération des produits : $e';
    }
  }

  Future<List<String>> getAllCategories() async {
    final data = await _db.from('categories').select('name');
    return data.map<String>((c) => c['name'] as String).toList();
  }

  Future<List<String>> getAllEtablissementsNames() async {
    final data = await _db.from('etablissements').select('name');
    return data.map<String>((e) => e['name'] as String).toList();
  }

  /// Optional: Search directly in Supabase (server-side search)
  Future<List<ProduitModel>> searchProducts(String query) async {
    final response = await _db
        .from(_table)
        .select('*')
        .or('name.ilike.%$query%,description.ilike.%$query%')
        .order('created_at', ascending: false)
        .limit(20);

    if (response.isEmpty) return [];

    return response.map((e) => ProduitModel.fromMap(e)).toList();
  }

  Future<List<ProduitModel>> getAllProductsPaginated({
    int? page,
    int? limit,
  }) async {
    final currentPage = page ?? _page;
    final currentLimit = limit ?? _limit;

    final from = (currentPage - 1) * currentLimit;
    final to = from + currentLimit - 1;

    final response = await _db
        .from(_table)
        .select('*, etablissement:etablissement_id(*)')
        .order('created_at', ascending: false)
        .range(from, to);

    if (response.isEmpty) return [];

    // Increment page counter for next call
    _page++;

    return response.map((e) => ProduitModel.fromMap(e)).toList();
  }

  Future<List<ProduitModel>> getProductsForCategory(
      {required String categoryId, int limit = 4}) async {
    try {
      // Essayer avec différents noms de colonnes possibles
      final query = _db.from(_table).select('''
            *,
            etablissement:etablissement_id(*),
            category:categorie_id(*)
          ''').eq('categorie_id', categoryId);

      if (limit > 0) {
        query.limit(limit);
      }

      final data = await query;

      if (data.isEmpty) return [];

      return data.map((item) => ProduitModel.fromMap(item)).toList();
    } catch (e) {
      // Debug: afficher l'erreur exacte
      debugPrint('Erreur getProductsForCategory: $e');

      // Fallback: essayer avec une requête plus simple
      try {
        final simpleQuery =
            _db.from(_table).select('*').eq('categorie_id', categoryId);

        if (limit > 0) {
          simpleQuery.limit(limit);
        }

        final simpleData = await simpleQuery;
        return simpleData.map((item) => ProduitModel.fromMap(item)).toList();
      } catch (fallbackError) {
        debugPrint('Fallback error: $fallbackError');
        throw 'Impossible de charger les produits: $e';
      }
    }
  }

  // Helper to split lists into chunks
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(
          i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }

  Future<List<ProduitModel>> getProductsForBrand({
    required String etablissementId,
    int limit = -1,
  }) async {
    try {
      final query = _db
          .from(_table)
          .select('*')
          .eq('etablissement_id', etablissementId)
          .order('name', ascending: true);

      final response = limit == -1 ? await query : await query.limit(limit);

      return (response as List<dynamic>)
          .map((json) => ProduitModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Erreur Supabase: ${e.message}');
    } catch (e) {
      throw Exception('Erreur lors du chargement des produits: $e');
    }
  }

  /// Récupérer un produit par son ID
  Future<ProduitModel?> getProductById(String productId) async {
    try {
      final response = await _db
          .from(_table)
          .select('*, etablissement:etablissement_id(*)')
          .eq('id', productId)
          .single();

      return ProduitModel.fromMap(response);
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Echec de récupération du produit : $e';
    }
  }

  /// Récupérer les produits d'un établissement
  Future<List<ProduitModel>> getProductsByEtablissement(
      String etablissementId) async {
    try {
      final response = await _db
          .from(_table)
          .select('*, etablissement:etablissement_id(*)')
          .eq('etablissement_id', etablissementId)
          .order('created_at', ascending: false);
      return response.map((produit) => ProduitModel.fromMap(produit)).toList();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Echec de récupération des produits de l\'établissement : $e';
    }
  }

  /// Récupérer les produits d'une catégorie
  Future<List<ProduitModel>> getProductsByCategory(String categoryId) async {
    try {
      final response = await _db
          .from(_table)
          .select('*')
          .eq('categorie_id', categoryId)
          .order('created_at', ascending: false);
      return response.map((produit) => ProduitModel.fromMap(produit)).toList();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Echec de récupération des produits de la catégorie : $e';
    }
  }

  /// Ajouter un nouveau produit
  Future<ProduitModel> addProduct(ProduitModel produit) async {
    try {
      final response =
          await _db.from('produits').insert(produit.toJson()).select().single();
      final createdProduct = ProduitModel.fromMap(response);

      return createdProduct;
    } catch (e) {
      throw Exception('Erreur lors de l’ajout du produit: $e');
    }
  }

  /// Modifier un produit
  Future<void> updateProduct(ProduitModel produit) async {
    try {
      await _db.from(_table).update(produit.toJson()).eq('id', produit.id);
    } on PostgrestException catch (e) {
      throw 'Erreur base de données : ${e.code} - ${e.message}';
    } catch (e) {
      throw 'Erreur lors de la mise à jour du produit : $e';
    }
  }

  /// Supprimer un produit
  Future<void> deleteProduct(String productId) async {
    try {
      await _db.from(_table).delete().eq('id', productId);
    } on PostgrestException catch (e) {
      throw 'Erreur base de données : ${e.code} - ${e.message}';
    } catch (e) {
      throw 'Erreur lors de la suppression du produit : $e';
    }
  }

  /// Mettre à jour le stock d'un produit à une valeur absolue
  Future<void> setProductStock(String productId, int newStock) async {
    try {
      debugPrint(
          '📦 setProductStock appelé pour $productId avec nouvelle valeur: $newStock');

      // Récupérer le produit actuel
      final product = await _db
          .from(_table)
          .select('est_stockable')
          .eq('id', productId)
          .single();

      final isStockable = product['est_stockable'] as bool? ?? false;

      debugPrint('📦 Produit $productId - est stockable: $isStockable');

      // Ne mettre à jour que si le produit est stockable
      if (!isStockable) {
        debugPrint('📦 Produit $productId non stockable, pas de mise à jour');
        throw 'Le produit n\'est pas stockable';
      }

      // S'assurer que le stock ne devienne pas négatif
      final finalStock = newStock < 0 ? 0 : newStock;

      debugPrint('📦 Produit $productId - nouveau stock: $finalStock');

      final response = await _db
          .from(_table)
          .update({'quantite_stock': finalStock})
          .eq('id', productId)
          .select();

      debugPrint(
          '📦 Stock mis à jour avec succès pour $productId. Réponse: $response');
    } on PostgrestException catch (e) {
      debugPrint(
          '❌ Erreur Postgres lors de la mise à jour du stock: ${e.code} - ${e.message}');
      throw 'Erreur base de données : ${e.code} - ${e.message}';
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de la mise à jour du stock: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Mettre à jour le stock d'un produit (changement relatif)
  Future<void> updateProductStock(String productId, int quantityChange) async {
    try {
      debugPrint(
          '📦 updateProductStock appelé pour $productId avec changement: $quantityChange');

      // Récupérer le produit actuel
      final product = await _db
          .from(_table)
          .select('quantite_stock, est_stockable')
          .eq('id', productId)
          .single();

      final currentStock = product['quantite_stock'] as int? ?? 0;
      final isStockable = product['est_stockable'] as bool? ?? false;

      debugPrint(
          '📦 Produit $productId - stock actuel: $currentStock, est stockable: $isStockable');

      // Ne mettre à jour que si le produit est stockable
      if (!isStockable) {
        debugPrint('📦 Produit $productId non stockable, pas de mise à jour');
        return; // Produit non stockable, pas besoin de mettre à jour
      }

      final newStock = currentStock + quantityChange;

      // S'assurer que le stock ne devienne pas négatif
      final finalStock = newStock < 0 ? 0 : newStock;

      debugPrint(
          '📦 Produit $productId - nouveau stock: $finalStock (ancien: $currentStock, changement: $quantityChange)');

      final response = await _db
          .from(_table)
          .update({'quantite_stock': finalStock})
          .eq('id', productId)
          .select();

      debugPrint(
          '📦 Stock mis à jour avec succès pour $productId. Réponse: $response');
    } on PostgrestException catch (e) {
      debugPrint(
          '❌ Erreur Postgres lors de la mise à jour du stock: ${e.code} - ${e.message}');
      throw 'Erreur base de données : ${e.code} - ${e.message}';
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de la mise à jour du stock: $e');
      debugPrint('Stack trace: $stackTrace');
      throw 'Erreur lors de la mise à jour du stock : $e';
    }
  }

// For XFile (web and mobile)
  Future<String> uploadProductImage(XFile pickedFile) async {
    try {
      final bytes = await pickedFile.readAsBytes();
      return await _uploadProductImageBytes(bytes);
    } catch (e) {
      debugPrint("Erreur uploadProductImage: $e");
      throw 'Erreur lors de l\'upload de l\'image : $e';
    }
  }

  Future<String> _uploadProductImageBytes(Uint8List bytes) async {
    final fileName = 'produit_${DateTime.now().millisecondsSinceEpoch}.png';
    final bucket = 'produits';

    await Supabase.instance.client.storage.from(bucket).uploadBinary(
        fileName, bytes,
        fileOptions: const FileOptions(contentType: 'image/png'));

    final publicUrl =
        Supabase.instance.client.storage.from(bucket).getPublicUrl(fileName);

    debugPrint("Product image uploaded. Public URL: $publicUrl");
    return publicUrl;
  }

  Future<List<ProduitModel>> getFeaturedProducts() async {
    try {
      final response = await _db
          .from(_table)
          .select('*, etablissement:etablissement_id(*)')
          .eq('is_featured', true)
          .limit(8)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;

      // Convertit les résultats en objets ProduitModel
      final products = data.map((productData) {
        return ProduitModel.fromMap(Map<String, dynamic>.from(productData));
      }).toList();

      return products;
    } on PostgrestException catch (e) {
      throw Exception('Erreur Supabase: ${e.message}');
    } catch (e) {
      rethrow; // important pour que Flutter te montre l’exception dans la console
    }
  }

  Future<List<ProduitModel>> getAllFeaturedProducts() async {
    try {
      final response = await _db
          .from(_table)
          .select('*, etablissement:etablissement_id(*)')
          .eq('is_featured', true)
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;

      // Convertit les résultats en objets ProduitModel
      final products = data.map((productData) {
        return ProduitModel.fromMap(Map<String, dynamic>.from(productData));
      }).toList();

      return products;
    } on PostgrestException catch (e) {
      throw Exception('Erreur Supabase: ${e.message}');
    } catch (e) {
      rethrow; // important pour que Flutter te montre l'exception dans la console
    }
  }

  /// Récupérer les produits les plus commandés avec leurs détails complets
  Future<List<ProduitModel>> getMostOrderedProductsWithDetails({
    int days = 30,
    int limit = 10,
  }) async {
    try {
      final orderRepository = OrderRepository.instance;

      // Récupérer les IDs et quantités des produits les plus commandés
      final mostOrdered = await orderRepository.getMostOrderedProducts(
        days: days,
        limit: limit,
      );

      if (mostOrdered.isEmpty) {
        return [];
      }

      // Récupérer les IDs des produits et filtrer les IDs vides ou invalides
      final productIds = mostOrdered
          .map((e) => e['productId']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toList();

      if (productIds.isEmpty) {
        debugPrint('Aucun ID de produit valide trouvé');
        return [];
      }

      // Récupérer les détails complets des produits avec gestion d'erreur
      List<dynamic> productsResponse;
      try {
        productsResponse = await _db
            .from(_table)
            .select('*, etablissement:etablissement_id(*)')
            .inFilter('id', productIds);
      } catch (e) {
        debugPrint('Erreur lors de la requête Supabase pour les produits: $e');
        // Si inFilter échoue, essayer de récupérer les produits un par un
        final products = <ProduitModel>[];
        for (final productId in productIds) {
          try {
            final productResponse = await _db
                .from(_table)
                .select('*, etablissement:etablissement_id(*)')
                .eq('id', productId)
                .maybeSingle();
            if (productResponse != null) {
              try {
                products.add(ProduitModel.fromMap(
                    Map<String, dynamic>.from(productResponse)));
              } catch (parseError) {
                debugPrint(
                    'Erreur lors du parsing du produit $productId: $parseError');
              }
            }
          } catch (singleError) {
            debugPrint(
                'Erreur lors de la récupération du produit $productId: $singleError');
            continue;
          }
        }
        if (products.isEmpty) return [];
        return _sortProductsByQuantity(products, mostOrdered);
      }

      if (productsResponse.isEmpty) {
        return [];
      }

      // Convertir en ProduitModel avec gestion d'erreur pour chaque produit
      final products = <ProduitModel>[];
      for (final productData in productsResponse) {
        try {
          final productMap = Map<String, dynamic>.from(productData);
          final product = ProduitModel.fromMap(productMap);
          products.add(product);
        } catch (e) {
          debugPrint('Erreur lors de la conversion d\'un produit: $e');
          // Continuer avec les autres produits même si un échoue
          continue;
        }
      }

      if (products.isEmpty) {
        return [];
      }

      return _sortProductsByQuantity(products, mostOrdered);
    } catch (e) {
      debugPrint(
          'Erreur lors de la récupération des produits les plus commandés: $e');
      // Retourner une liste vide au lieu de lever une exception pour éviter de crasher l'app
      return [];
    }
  }

  /// Trier les produits selon l'ordre des quantités
  List<ProduitModel> _sortProductsByQuantity(
    List<ProduitModel> products,
    List<Map<String, dynamic>> mostOrdered,
  ) {
    // Créer un map pour retrouver les quantités
    final quantityMap = <String, int>{};
    for (final e in mostOrdered) {
      final productId = e['productId']?.toString();
      if (productId != null && productId.isNotEmpty) {
        quantityMap[productId] = (e['totalQuantity'] as num?)?.toInt() ?? 0;
      }
    }

    // Trier les produits selon l'ordre des quantités (plus commandés en premier)
    products.sort((a, b) {
      final qtyA = quantityMap[a.id] ?? 0;
      final qtyB = quantityMap[b.id] ?? 0;
      return qtyB.compareTo(qtyA);
    });

    return products;
  }

  // Récupération avec IDs
  Future<List<CategoryModel>> getAllCategoriesWithIds() async {
    try {
      final data = await _db
          .from('categories')
          .select('id, name, image'); // Inclure image si disponible

      return data.map<CategoryModel>((c) {
        // Utiliser fromJson ou fromBasicData selon les données disponibles
        if (c['image'] != null) {
          return CategoryModel.fromJson(c);
        } else {
          return CategoryModel.fromBasicData(
            id: c['id']?.toString() ?? '',
            name: c['name']?.toString() ?? '',
          );
        }
      }).toList();
    } catch (e) {
      print('Erreur getAllCategoriesWithIds: $e');
      return [];
    }
  }

  Future<List<Etablissement>> getAllEtablissementsWithIds() async {
    try {
      final data = await _db.from('etablissements').select('id, name, statut');
      return data
          .map<Etablissement>((e) => Etablissement(
                id: e['id']?.toString(),
                name: e['name']?.toString() ?? '',
                address: '',
                idOwner: '',
                statut:
                    StatutEtablissementExt.fromString(e['statut']?.toString()),
                createdAt: DateTime.now(),
              ))
          .toList();
    } catch (e) {
      print('Erreur getAllEtablissementsWithIds: $e');
      return [];
    }
  }

// Recherche améliorée avec gestion correcte des types
  Future<List<ProduitModel>> searchProductsWithFilters({
    String? query,
    String? categoryId,
    String? etablissementId,
    String? sortBy,
  }) async {
    try {
      // Utiliser dynamic pour éviter les conflits de types
      dynamic request = _db.from(_table).select('''
      *, 
      etablissement:etablissement_id(*),
      category:categorie_id(*)
    ''');

      // Appliquer les filtres
      if (query != null && query.isNotEmpty) {
        request = request.or('nom.ilike.%$query%,description.ilike.%$query%');
      }

      if (categoryId != null && categoryId.isNotEmpty) {
        request = request.eq('categorie_id', categoryId);
      }

      if (etablissementId != null && etablissementId.isNotEmpty) {
        request = request.eq('etablissement_id', etablissementId);
      }

      // Appliquer le tri avec gestion de type
      switch (sortBy) {
        case 'Prix ↑':
          request = (request as dynamic).order('prix', ascending: true);
          break;
        case 'Prix ↓':
          request = (request as dynamic).order('prix', ascending: false);
          break;
        case 'Nom A-Z':
          request = (request as dynamic).order('nom', ascending: true);
          break;
        case 'Popularité':
          request = (request as dynamic).order('is_featured', ascending: false);
          break;
        default:
          request = (request as dynamic).order('created_at', ascending: false);
      }

      final response = await request;
      return response.map((e) => ProduitModel.fromMap(e)).toList();
    } catch (e) {
      print('Erreur searchProductsWithFilters: $e');
      return [];
    }
  }

  /// Get multiple products by their IDs (for favorites)
  Future<List<ProduitModel>> getProductsByIds(List<String> productIds) async {
    if (productIds.isEmpty) return [];

    try {
      final chunks = _chunkList(productIds, 100);
      List<ProduitModel> allProducts = [];

      for (final chunk in chunks) {
        final response =
            await _db.from('produits').select().inFilter('id', chunk);

        final List<Map<String, dynamic>> productData =
            (response as List).cast<Map<String, dynamic>>();

        allProducts.addAll(
            productData.map((json) => ProduitModel.fromMap(json)).toList());
      }

      // Maintain the order from productIds
      allProducts.sort((a, b) =>
          productIds.indexOf(a.id).compareTo(productIds.indexOf(b.id)));

      return allProducts;
    } on PostgrestException catch (e) {
      throw 'Database error: ${e.message}';
    } catch (e) {
      throw 'Echec de chargement des produits : ${e.toString()}';
    }
  }

  /// Alias for getProductsByIds to maintain compatibility
  Future<List<ProduitModel>> getFavoriteProducts(
      List<String> productIds) async {
    return getProductsByIds(productIds);
  }
}
