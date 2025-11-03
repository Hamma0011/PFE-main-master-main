import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/shop/models/brand_model.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/supabase_exception.dart';

class BrandRepository extends GetxController {
  static BrandRepository get instance => Get.find();

  /// Variables

  final _db = Supabase.instance.client;
  final _table = 'brands';

  Future<void> addBrand(BrandModel brand) async {
    try {
      final response = await _db.from(_table).insert(brand.toJson());
      if (response.error != null) {
        throw response.error!.message;
      }
    } on SupabaseException catch (e) {
      throw SupabaseException(e.code).message;
    } on PostgrestException catch (e) {
      throw 'Erreur base de données : ${e.code} - ${e.message}';
    } catch (e) {
      throw 'Erreur lors ajout etablissement : $e }';
    }
  }

  /// Get all brands
  Future<List<BrandModel>> getAllBrands() async {
    try {
      final response = await _db
          .from(_table)
          .select()
          .withConverter<List<BrandModel>>((data) {
        return data.map((e) => BrandModel.fromMap(e)).toList();
      });

      return response;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PostgrestException catch (e) {
      throw 'Erreur Supabase: ${e.message}';
    } catch (e) {
      throw 'Quelque chose s\'est mal passée lors de la récupération des marques $e';
    }
  }

  Future<List<BrandModel>> getBrandsForCategory(String categoryId) async {
    try {
      // 1. Récupération des IDs de marques associées à la catégorie
      final brandCategories = await _db
          .from('BrandCategory')
          .select('brandId')
          .eq('categoryId', categoryId);

      // Extraction des IDs
      final brandIds = brandCategories
          .map<String>((item) => item['brandId'] as String)
          .toList();

      // 2. Récupération des marques correspondantes
      if (brandIds.isEmpty) return [];

      final response = await _db
          .from(_table)
          .select()
          .inFilter('id', brandIds)
          .limit(2)
          .withConverter<List<BrandModel>>((data) {
        return data.map((e) => BrandModel.fromMap(e)).toList();
      });
      return response;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PostgrestException catch (e) {
      throw 'Erreur Supabase: ${e.message}';
    } catch (e) {
      throw 'Quelque chose s\'est mal passée lors de la récupération des bannières.';
    }
  }
}
