import 'dart:io';
import 'package:flutter/foundation.dart'; // pour kIsWeb et debugPrint

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
  TextEditingController nameController = TextEditingController();
  TextEditingController parentIdController = TextEditingController();

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
  RxList<CategoryModel> topCategoriesBySales = <CategoryModel>[].obs;
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

  void _ensureControllersInitialized() {
    try {
      // Vérifier si les contrôleurs peuvent être utilisés en accédant à leur valeur
      nameController.text;
    } catch (e) {
      // Si le contrôleur est disposé, le recréer
      nameController = TextEditingController();
    }
    try {
      parentIdController.text;
    } catch (e) {
      parentIdController = TextEditingController();
    }
  }

  @override
  void onClose() {
    // Pour un contrôleur permanent, on ne devrait pas arriver ici
    // Mais si on y arrive, on dispose proprement
    try {
      nameController.dispose();
    } catch (e) {
      // Déjà disposé, ignorer
    }
    try {
      parentIdController.dispose();
    } catch (e) {
      // Déjà disposé, ignorer
    }
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
    _ensureControllersInitialized();
    try {
      nameController.clear();
    } catch (e) {
      // Si problème, recréer le contrôleur
      nameController = TextEditingController();
    }
    try {
      parentIdController.clear();
    } catch (e) {
      // Si problème, recréer le contrôleur
      parentIdController = TextEditingController();
    }
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
      
      // Charger les top catégories par ventes en arrière-plan
      _loadTopCategoriesBySales();
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Erreur!', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Charger les top catégories par ventes
  Future<void> _loadTopCategoriesBySales() async {
    try {
      final topCategories = await _categoryRepository.getTopCategoriesBySales(
        days: 30,
        limit: 8,
      );
      topCategoriesBySales.assignAll(topCategories);
    } catch (e) {
      debugPrint('Erreur lors du chargement des top catégories par ventes: $e');
      // Ne pas afficher d'erreur à l'utilisateur, c'est secondaire
    }
  }

  Future<void> refreshCategories() async {
    isLoading.value = true;
    await fetchCategories();
    // Recharger aussi les top catégories par ventes
    await _loadTopCategoriesBySales();
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

      // S'assurer que le contrôleur est initialisé avant utilisation
      _ensureControllersInitialized();
      String categoryName = '';
      try {
        categoryName = nameController.text.trim();
      } catch (e) {
        TLoaders.errorSnackBar(message: "Erreur lors de la lecture du nom de la catégorie");
        return;
      }

      final newCategory = CategoryModel(
        id: '',
        name: categoryName,
        image: imageUrl,
        parentId: parentId,
        isFeatured: isFeatured.value,
      );

      await _categoryRepository.addCategory(newCategory);
      await fetchCategories();

      clearForm();
      Get.back();
      TLoaders.successSnackBar(
        message: 'Catégorie "$categoryName" ajoutée avec succès',
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

      // Vérifier que le contrôleur n'est pas disposé avant d'accéder à son texte
      _ensureControllersInitialized();
      String categoryName = originalCategory.name;
      try {
        final nameText = nameController.text.trim();
        if (nameText.isNotEmpty) {
          categoryName = nameText;
        }
      } catch (e) {
        // Si le contrôleur est disposé, utiliser le nom original
        // Le contrôleur sera recréé la prochaine fois
      }

      final updatedCategory = CategoryModel(
        id: originalCategory.id,
        name: categoryName,
        image: imageUrl,
        parentId: selectedParentId.value,
        isFeatured: isFeatured.value,
      );

      await _categoryRepository.updateCategory(updatedCategory);
      await fetchCategories();

      TLoaders.successSnackBar(
        message: "Catégorie '${updatedCategory.name}' mise à jour avec succès.",
      );

      // Ne pas appeler clearForm() ici car le widget pourrait être disposé
      // Le clearForm sera appelé lors de la prochaine utilisation du formulaire
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
    _ensureControllersInitialized();
    try {
      nameController.text = category.name;
    } catch (e) {
      // Si toujours un problème, recréer le contrôleur
      nameController = TextEditingController(text: category.name);
    }
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
