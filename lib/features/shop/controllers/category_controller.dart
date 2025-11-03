import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // pour kIsWeb

import 'package:caferesto/features/personalization/controllers/user_controller.dart';
import 'package:caferesto/data/repositories/categories/category_repository.dart';
import 'package:caferesto/features/shop/models/category_model.dart';
import 'package:caferesto/utils/constants/image_strings.dart';
import 'package:caferesto/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/repositories/product/produit_repository.dart';
import '../models/produit_model.dart';

enum CategoryFilter { all, featured }

class CategoryController extends GetxController
    with GetTickerProviderStateMixin {
  static CategoryController get instance {
    try {
      return Get.find<CategoryController>();
    } catch (e) {
      // If not found, create it (shouldn't happen with proper binding)
      return Get.put(CategoryController(), permanent: true);
    }
  }

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final parentIdController = TextEditingController();

  final isFeatured = false.obs;
  final Rx<String?> selectedParentId = Rx<String?>(null);

  final ImagePicker _picker = ImagePicker();

  /// Sur Web on stocke les bytes, sur Mobile on stocke File
  final pickedImage = Rx<File?>(null);
  final pickedImageBytes = Rx<Uint8List?>(null);

  final UserController userController = Get.find<UserController>();

  final isLoading = true.obs;
  final _categoryRepository = Get.put(CategoryRepository());
  RxList<CategoryModel> allCategories = <CategoryModel>[].obs;
  RxList<CategoryModel> featuredCategories = <CategoryModel>[].obs;
  late TabController tabController;
  final RxString searchQuery = ''.obs;
  final Rx<CategoryFilter> selectedFilter = CategoryFilter.all.obs;

  @override
  void onReady() {
    super.onReady();
    // Delay tabController creation until after the first frame
    tabController = TabController(length: 2, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      isLoading.value = true;
      await Future.delayed(Duration.zero);
      await fetchCategories();
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Erreur!', message: e.toString());
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    parentIdController.dispose();
    super.onClose();
  }

  /// Sélection d'image compatible Web et Mobile
  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        pickedImageBytes.value = await pickedFile.readAsBytes();
        pickedImage.value = null;
      } else {
        pickedImage.value = File(pickedFile.path);
        pickedImageBytes.value = null;
      }
    }
  }

  void clearForm() {
    nameController.clear();
    parentIdController.clear();
    isFeatured.value = false;
    pickedImage.value = null;
    pickedImageBytes.value = null;
    selectedParentId.value = null;
  }

  Future<void> fetchCategories() async {
    try {
      if (!isLoading.value) isLoading.value = true;
      final categories = await _categoryRepository.getAllCategories();
      allCategories.assignAll(categories);
      featuredCategories.assignAll(
        categories.where((cat) => cat.isFeatured).take(8).toList(),
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Erreur!', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshCategories() async {
    isLoading.value = true;
    await fetchCategories();
  }

  Future<List<CategoryModel>> getSubCategories(String categoryId) async {
    try {
      return await _categoryRepository.getSubCategories(categoryId);
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Erreur', message: e.toString());
      return [];
    }
  }

  Future<List<ProduitModel>>? getCategoryProducts({
    required String categoryId,
    int limit = 4,
  }) async {
    try {
      return await ProduitRepository.instance
          .getProductsForCategory(categoryId: categoryId, limit: limit);
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Erreur', message: e.toString());
      return [];
    }
  }

  /// Ajouter une catégorie
  Future<void> addCategory() async {
    if (!formKey.currentState!.validate()) return;

    if (userController.user.value.role != 'Gérant' &&
        userController.user.value.role != 'Admin') {
      TLoaders.errorSnackBar(
          message: "Vous n'avez pas la permission d'ajouter une catégorie.");
      return;
    }

    try {
      isLoading.value = true;
      String imageUrl = TImages.pasdimage;

      // Upload image Web/Mobile
      if ((kIsWeb && pickedImageBytes.value != null) ||
          (!kIsWeb && pickedImage.value != null)) {
        final dynamic file =
            kIsWeb ? pickedImageBytes.value! : pickedImage.value!;
        imageUrl = await _categoryRepository.uploadCategoryImage(file);
      }

      final String? parentId =
          (selectedParentId.value != null && selectedParentId.value!.isNotEmpty)
              ? selectedParentId.value
              : null;

      final newCategory = CategoryModel(
        id: '',
        name: nameController.text.trim(),
        image: imageUrl,
        parentId: parentId,
        isFeatured: isFeatured.value,
      );

      await _categoryRepository.addCategory(newCategory);
      await fetchCategories();

      clearForm();
      Get.back();
      TLoaders.successSnackBar(
        message:
            'Catégorie "${nameController.text.trim()}" ajoutée avec succès',
      );
    } catch (e) {
      TLoaders.errorSnackBar(message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Modifier une catégorie
  Future<bool> editCategory(CategoryModel originalCategory) async {
    if (userController.user.value.role != 'Gérant' &&
        userController.user.value.role != 'Admin') {
      TLoaders.errorSnackBar(
        message: "Vous n'avez pas la permission de modifier une catégorie.",
      );
      return false;
    }

    try {
      isLoading.value = true;
      String imageUrl = originalCategory.image;

      // Upload image Web/Mobile
      if ((kIsWeb && pickedImageBytes.value != null) ||
          (!kIsWeb && pickedImage.value != null)) {
        final dynamic file =
            kIsWeb ? pickedImageBytes.value! : pickedImage.value!;
        imageUrl = await _categoryRepository.uploadCategoryImage(file);
      }

      final updatedCategory = CategoryModel(
        id: originalCategory.id,
        name: nameController.text.trim(),
        image: imageUrl,
        parentId: selectedParentId.value,
        isFeatured: isFeatured.value,
      );

      await _categoryRepository.updateCategory(updatedCategory);
      Get.back();
      await fetchCategories();

      TLoaders.successSnackBar(
        message: "Catégorie '${updatedCategory.name}' mise à jour avec succès.",
      );

      clearForm();
      return true;
    } catch (e) {
      TLoaders.errorSnackBar(message: e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Supprimer une catégorie
  Future<void> removeCategory(String categoryId) async {
    if (userController.user.value.role != 'Gérant' &&
        userController.user.value.role != 'Admin') {
      TLoaders.errorSnackBar(
          message: "Vous n'avez pas la permission de supprimer une catégorie.");
      return;
    }

    try {
      isLoading.value = true;
      await _categoryRepository.deleteCategory(categoryId);
      await fetchCategories();
      TLoaders.successSnackBar(message: "Catégorie supprimée avec succès");
    } catch (e) {
      TLoaders.errorSnackBar(message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  String getParentName(String parentId) {
    try {
      final parent = allCategories.firstWhere((cat) => cat.id == parentId);
      return parent.name;
    } catch (e) {
      return "Inconnue";
    }
  }

  void initializeForEdit(CategoryModel category) {
    nameController.text = category.name;
    selectedParentId.value = category.parentId;
    isFeatured.value = category.isFeatured;
    pickedImage.value = null;
    pickedImageBytes.value = null;
  }

  List<CategoryModel> get mainCategories =>
      allCategories.where((c) => c.parentId == null).toList();

  List<CategoryModel> get subCategories =>
      allCategories.where((c) => c.parentId != null).toList();

  List<CategoryModel> getFilteredCategories(bool isSubcategory) {
    final all = isSubcategory ? subCategories : mainCategories;
    final filtered = selectedFilter.value == CategoryFilter.featured
        ? all.where((c) => c.isFeatured).toList()
        : all;

    if (searchQuery.value.isEmpty) return filtered;

    final q = searchQuery.value.toLowerCase();
    return filtered.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  void updateSearch(String value) => searchQuery.value = value;
  void updateFilter(CategoryFilter filter) => selectedFilter.value = filter;
}
