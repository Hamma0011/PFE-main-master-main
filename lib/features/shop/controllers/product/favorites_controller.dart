import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../utils/local_storage/storage_utility.dart';
import '../../../../utils/popups/loaders.dart';
import '../../models/produit_model.dart';
import '../../models/etablissement_model.dart';

import 'package:flutter/widgets.dart';

import '../../../../data/repositories/product/produit_repository.dart';



class FavoritesController extends GetxController {
  static FavoritesController get instance => Get.find<FavoritesController>();

  final RxList<String> favoriteIds = <String>[].obs;
  final RxList<ProduitModel> favoriteProducts = <ProduitModel>[].obs;
  final RxBool isLoading = false.obs;

  final String _storageKey = 'favorites';
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadFavorites();
    });
  }

  /// Load favorites IDs from local storage and fetch product details
  Future<void> loadFavorites() async {
    try {
      isLoading.value = true;
      final raw = TLocalStorage.instance().readData(_storageKey);
      if (raw != null && (raw as String).isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        favoriteIds.assignAll(decoded.cast<String>());
      } else {
        favoriteIds.clear();
      }
      await _loadFavoriteProducts();
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Erreur', message: 'Impossible de charger les favoris');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadFavoriteProducts() async {
    favoriteProducts.clear();
    if (favoriteIds.isEmpty) return;

    try {
      final products = await ProduitRepository.instance.getProductsByIds(favoriteIds);
      // Keep order consistent with favoriteIds
      final Map<String, ProduitModel> mapById = { for (var p in products) p.id: p };
      final ordered = favoriteIds.map((id) => mapById[id]).whereType<ProduitModel>().toList();
      
      // Charger les établissements pour les produits qui en ont besoin
      final productsWithEtab = await _loadEtablissementsBatch(ordered);
      
      favoriteProducts.assignAll(productsWithEtab);
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Erreur', message: 'Impossible de charger les produits favoris');
    }
  }

  /// Charge les établissements en batch pour une liste de produits
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

      // Mapper les produits avec leurs établissements
      return produits.map((produit) {
        if (produit.etablissement == null && produit.etablissementId.isNotEmpty) {
          final etab = etablissementsMap[produit.etablissementId];
          if (etab != null) {
            return produit.copyWith(etablissement: etab);
          }
        }
        return produit;
      }).toList();
    } catch (e) {
      debugPrint('Erreur chargement établissements batch: $e');
      // Retourner les produits même si les établissements n'ont pas pu être chargés
      return produits;
    }
  }

  /// Persist favorite ids locally
  Future<void> _saveFavorites() async {
    try {
      final encoded = jsonEncode(favoriteIds);
      await TLocalStorage.instance().saveData(_storageKey, encoded);
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Erreur', message: 'Impossible de sauvegarder les favoris');
    }
  }

  bool isFavourite(String productId) {
    return favoriteIds.contains(productId);
  }

  /// Toggle favorite status and keep product list in sync
  Future<void> toggleFavoriteProduct(String productId) async {
    try {
      if (favoriteIds.contains(productId)) {
        favoriteIds.remove(productId);
        favoriteProducts.removeWhere((p) => p.id == productId);
        TLoaders.customToast(message: 'Produit retiré des favoris');
      } else {
        favoriteIds.add(productId);
        TLoaders.customToast(message: 'Produit ajouté aux favoris');
        try {
          final fetched = await ProduitRepository.instance.getProductById(productId);
          if (fetched != null) {
            // Charger l'établissement si manquant
            ProduitModel productWithEtab = fetched;
            if (fetched.etablissement == null && fetched.etablissementId.isNotEmpty) {
              final productsWithEtab = await _loadEtablissementsBatch([fetched]);
              if (productsWithEtab.isNotEmpty) {
                productWithEtab = productsWithEtab.first;
              }
            }
            
            final insertIndex = favoriteIds.indexOf(productId);
            if (insertIndex >= 0 && insertIndex <= favoriteProducts.length) {
              favoriteProducts.insert(insertIndex, productWithEtab);
            } else {
              favoriteProducts.add(productWithEtab);
            }
          } else {
            await _loadFavoriteProducts();
          }
        } catch (_) {
          await _loadFavoriteProducts();
        }
      }
      await _saveFavorites();
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Erreur', message: 'Action impossible');
    }
  }

  /// Clear all favorites. Returns true if success
  Future<bool> clearAllFavorites() async {
    try {
      isLoading.value = true;
      favoriteIds.clear();
      favoriteProducts.clear();
      await _saveFavorites();
      return true;
    } catch (e) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}