import 'dart:io';
import 'dart:typed_data';

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
}
