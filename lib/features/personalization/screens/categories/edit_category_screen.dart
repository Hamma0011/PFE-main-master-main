import 'package:caferesto/features/personalization/screens/categories/widgets/category_form_widgets.dart';
import 'package:caferesto/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../shop/controllers/category_controller.dart';
import '../../../shop/models/category_model.dart';

class EditCategoryScreen extends StatefulWidget {
  final CategoryModel category;

  const EditCategoryScreen({super.key, required this.category});

  @override
  State<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends State<EditCategoryScreen>
    with SingleTickerProviderStateMixin {
  final CategoryController categoryController = Get.find();
  final _formKey = GlobalKey<FormState>();
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initializeController();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    );
    _animationController!.forward();
  }

  void _initializeController() {
    categoryController.initializeForEdit(widget.category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Obx(() => _buildBody()),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return TAppBar(
      title: const Text(
        "Modifier Catégorie",
      ),
    );
  }

  Widget _buildBody() {
    if (categoryController.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    return _fadeAnimation != null
        ? FadeTransition(
            opacity: _fadeAnimation!,
            child: _buildForm(),
          )
        : const SizedBox.shrink();
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Image
              CategoryImageSection(
                onPickImage: categoryController.pickImage,
                pickedImage: categoryController.pickedImage.value,
                existingImageUrl: widget.category.image,
              ),
              const SizedBox(height: 40),

              // Formulaire
              CategoryFormCard(
                children: [
                  CategoryNameField(
                    controller: categoryController.nameController,
                  ),
                  const SizedBox(height: 24),
                  CategoryParentDropdown(
                    selectedParentId: categoryController.selectedParentId.value,
                    categories: categoryController.allCategories,
                    onChanged: (value) {
                      categoryController.selectedParentId.value = value;
                    },
                    excludeCategoryId: widget.category.id,
                  ),
                  const SizedBox(height: 24),
                  Obx(() => CategoryFeaturedSwitch(
                        value: categoryController.isFeatured.value,
                        onChanged: (value) {
                          categoryController.isFeatured.value = value;
                        },
                      )),
                ],
              ),
              const SizedBox(height: 32),

              // Bouton Sauvegarder
              Obx(() => CategorySubmitButton(
                    isLoading: categoryController.isLoading.value,
                    onPressed: _saveCategory,
                    text: "Enregistrer les modifications",
                    icon: Icons.check_circle_outline,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final success = await categoryController.editCategory(widget.category);

      if (success) {
        TLoaders.successSnackBar(message: "Catégorie mise à jour avec succès");
        Get.back();
      }
    } catch (e) {
      TLoaders.errorSnackBar(message: e.toString());
    }
  }
}
