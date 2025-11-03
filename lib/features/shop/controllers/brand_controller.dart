import 'dart:io';

import 'package:caferesto/data/repositories/authentication/authentication_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/repositories/brands/brand_repository.dart';
import '../../../data/repositories/product/produit_repository.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/popups/loaders.dart';
import '../models/brand_model.dart';
import '../models/produit_model.dart';

class BrandController extends GetxController {
  static BrandController get instance => Get.find();

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final parentIdController = TextEditingController();
  final isFeatured = false.obs;

  // Image picker
  final ImagePicker _picker = ImagePicker();
  final pickedImage = Rx<File?>(null);

  /// image depuis gallery
  Future<void> pickImage() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      pickedImage.value = File(pickedFile.path);
    }
  }

  /// Réinitiliser formulaire
  void clearForm() {
    nameController.clear();
    parentIdController.clear();
    isFeatured.value = false;
    pickedImage.value = null;
  }

  /// Variables
  RxBool isLoading = true.obs;
  final RxList<BrandModel> allBrands = <BrandModel>[].obs;
  final RxList<BrandModel> featuredBrands = <BrandModel>[].obs;
  final brandRepository = Get.put(BrandRepository());

  @override
  void onInit() {
    super.onInit();
    getFeaturedBrands();
  }

  /// -- Charger établissements
  Future<void> getFeaturedBrands() async {
    try {
      // Afficher loader au chargement des ets
      isLoading.value = true;

      final brands = await brandRepository.getAllBrands();

      allBrands.assignAll(brands);

      featuredBrands.assignAll(
          allBrands.where((brand) => brand.isFeatured ?? false).take(4));
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Erreur', message: e.toString());
    } finally {
      // Masquer le loader
      isLoading.value = false;
    }
  }

  /// -- Charger ETS pour une catégorie
  Future<List<BrandModel>> getBrandsForCategory(String categoryId) async {
    try {
      final brands = await brandRepository.getBrandsForCategory(categoryId);

      return brands;
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Erreur', message: e.toString());
      return [];
    }
  }

  /// -- Charger ETS produits spécifiques
  Future<List<ProduitModel>> getBrandProducts(
      {required String etablissementId, int limit = -1}) async {
    try {
      final products = await ProduitRepository.instance
          .getProductsForBrand(etablissementId: etablissementId , limit: limit);

      return products;
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Erreur', message: e.toString());
      return [];
    }
  }

  Future<void> addBrand() async {
    if (!formKey.currentState!.validate()) return;

    final userRole =
        AuthenticationRepository.instance.authUser?.userMetadata?['role'];

    if (userRole != 'Gérant' && userRole != 'Admin') {
      throw "Vous n'avez pas la permission d'ajouter une catégorie.";
    }

    try {
      isLoading.value = true; //

      String imageUrl = TImages.coffee;
      if (pickedImage.value != null) {
        imageUrl = pickedImage.value!.path;
      }

      final newBrand = BrandModel(
        id: '',
        name: nameController.text.trim(),
        image: imageUrl,
        isFeatured: isFeatured.value,
      );

      await BrandRepository.instance.addBrand(newBrand);
      // Rafrâichir les catégories après ajout
      await getFeaturedBrands();

      clearForm();
      Get.back();
      TLoaders.successSnackBar(message: 'Etablissements ajoutée avec succès');
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
