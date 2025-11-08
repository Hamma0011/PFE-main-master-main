import 'dart:io';

import 'package:caferesto/utils/exceptions/supabase_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/shop/models/category_model.dart';
import '../../../utils/exceptions/platform_exceptions.dart';

class CategoryRepository extends GetxController {
  static CategoryRepository get instance => Get.find();

  /// Variables
  final _db = Supabase.instance.client;
  final _table = 'categories';

  /// Charger toutes les catégories
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      final response =
          await _db.from(_table).select().order('name', ascending: true);
      return response
          .map((category) => CategoryModel.fromJson(category))
          .toList();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Échec de récupération des catégories : $e';
    }
  }

  /// Charger les sous-catégories
  Future<List<CategoryModel>> getSubCategories(String categoryId) async {
    try {
      final response = await _db
          .from(_table)
          .select()
          .eq('parentId', categoryId)
          .order('name', ascending: true);
      return response
          .map((category) => CategoryModel.fromJson(category))
          .toList();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Échec de récupération des sous-catégories : $e';
    }
  }

  /// Ajouter une catégorie
  Future<void> addCategory(CategoryModel category) async {
    try {
      await _db.from(_table).insert(category.toJson());
    } on PostgrestException catch (e) {
      throw 'Erreur base de données : ${e.code} - ${e.message}';
    } on SupabaseException catch (e) {
      throw SupabaseException(e.code).message;
    } catch (e) {
      throw 'Erreur lors de l’ajout de la catégorie : $e';
    }
  }

  /// Upload d'image compatible Web & Mobile
  Future<String> uploadCategoryImage(dynamic file) async {
    try {
      final bucket = 'categories';
      final fileName = 'category_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (kIsWeb && file is Uint8List) {
        // Web → on upload directement les bytes
        await Supabase.instance.client.storage
            .from(bucket)
            .uploadBinary(fileName, file);
      } else if (!kIsWeb && file is File) {
        // Mobile → on upload le File
        await Supabase.instance.client.storage
            .from(bucket)
            .upload(fileName, file);
      } else {
        throw 'Type de fichier non supporté pour l’upload';
      }

      // Récupérer l’URL publique
      final publicUrl =
          Supabase.instance.client.storage.from(bucket).getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      throw 'Erreur lors de l’upload de l’image : $e';
    }
  }

  /// Modifier une catégorie
  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _db.from(_table).update(category.toJson()).eq('id', category.id);
    } on PostgrestException catch (e) {
      throw 'Erreur base de données : ${e.code} - ${e.message}';
    } on SupabaseException catch (e) {
      throw SupabaseException(e.code).message;
    } catch (e) {
      throw 'Erreur lors de la mise à jour de la catégorie : $e';
    }
  }

  /// Supprimer une catégorie
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _db.from(_table).delete().eq('id', categoryId);
    } on PostgrestException catch (e) {
      throw 'Erreur base de données : ${e.code} - ${e.message}';
    } on SupabaseException catch (e) {
      throw SupabaseException(e.code).message;
    } catch (e) {
      throw 'Erreur lors de la suppression de la catégorie : $e';
    }
  }

  /// Récupérer les top catégories par ventes
  /// [days] : nombre de jours à prendre en compte (par défaut 30)
  /// [limit] : nombre de catégories à retourner (par défaut 8)
  Future<List<CategoryModel>> getTopCategoriesBySales({
    int days = 30,
    int limit = 8,
  }) async {
    try {
      // Date limite (30 jours en arrière)
      final dateLimit = DateTime.now().subtract(Duration(days: days));

      // Récupérer toutes les commandes des 30 derniers jours (sauf annulées/refusées)
      final ordersResponse = await _db
          .from('orders')
          .select('items, created_at, status')
          .gte('created_at', dateLimit.toIso8601String())
          .not('status', 'in', '(cancelled,refused)'); // Exclure les annulées/refusées

      if ((ordersResponse as List).isEmpty) {
        return [];
      }

      // Collecter tous les IDs de produits uniques
      final Set<String> productIds = {};
      final Map<String, int> productQuantities = {};

      // Parcourir toutes les commandes pour collecter les produits
      for (final orderData in ordersResponse as List) {
        final items = orderData['items'] as List?;
        if (items == null || items.isEmpty) continue;

        for (final item in items) {
          final itemMap = Map<String, dynamic>.from(item);
          final productId = itemMap['productId']?.toString() ?? '';
          final quantity = (itemMap['quantity'] as num?)?.toInt() ?? 0;

          if (productId.isNotEmpty && quantity > 0) {
            productIds.add(productId);
            productQuantities[productId] =
                (productQuantities[productId] ?? 0) + quantity;
          }
        }
      }

      if (productIds.isEmpty) {
        return [];
      }

      // Récupérer tous les produits avec leurs catégories en une seule requête
      final productsResponse = await _db
          .from('produits')
          .select('id, categorie_id')
          .inFilter('id', productIds.toList());

      if ((productsResponse as List).isEmpty) {
        return [];
      }

      // Map pour agréger les quantités par catégorie
      final Map<String, int> categoryQuantities = {};

      // Parcourir les produits pour agréger par catégorie
      for (final productData in productsResponse as List) {
        final productId = productData['id']?.toString() ?? '';
        final categoryId = productData['categorie_id']?.toString();

        if (productId.isNotEmpty &&
            categoryId != null &&
            categoryId.isNotEmpty) {
          final quantity = productQuantities[productId] ?? 0;
          categoryQuantities[categoryId] =
              (categoryQuantities[categoryId] ?? 0) + quantity;
        }
      }

      if (categoryQuantities.isEmpty) {
        return [];
      }

      // Trier les catégories par quantité décroissante
      final sortedCategoryIds = categoryQuantities.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Récupérer les top catégories (limité)
      final topCategoryIds =
          sortedCategoryIds.take(limit).map((e) => e.key).toList();

      if (topCategoryIds.isEmpty) {
        return [];
      }

      // Récupérer les détails des catégories
      final categoriesResponse = await _db
          .from(_table)
          .select()
          .inFilter('id', topCategoryIds);

      if ((categoriesResponse as List).isEmpty) {
        return [];
      }

      // Créer une map pour préserver l'ordre
      final categoriesMap = <String, CategoryModel>{};
      for (final catData in categoriesResponse as List) {
        final category = CategoryModel.fromJson(catData);
        categoriesMap[category.id] = category;
      }

      // Retourner les catégories dans l'ordre des ventes
      return topCategoryIds
          .map((id) => categoriesMap[id])
          .whereType<CategoryModel>()
          .toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des catégories les plus vendues: $e');
      // Retourner une liste vide en cas d'erreur plutôt que de planter
      return [];
    }
  }
}
