import 'package:caferesto/features/personalization/screens/categories/widgets/category_form_widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../shop/controllers/category_controller.dart';

class AddCategoryScreen extends StatelessWidget {
  AddCategoryScreen({super.key});

  final CategoryController _categoryController = CategoryController.instance;

  @override
  Widget build(BuildContext context) {
    _categoryController.clearForm();
    return Scaffold(
      appBar: TAppBar(
        title: const Text("Ajouter Catégorie"),
      ),
      body: Obx(() => _buildBody()),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _categoryController.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Image
              CategoryImageSection(
                onPickImage: _categoryController.pickImage,
                pickedImage: _categoryController.pickedImage.value,
              ),
              const SizedBox(height: 40),

              // Formulaire
              CategoryFormCard(
                children: [
                  CategoryNameField(
                    controller: _categoryController.nameController,
                  ),
                  const SizedBox(height: 24),
                  CategoryParentDropdown(
                    selectedParentId:
                        _categoryController.selectedParentId.value,
                    categories: _categoryController.allCategories,
                    onChanged: (value) {
                      _categoryController.selectedParentId.value = value;
                    },
                  ),
                  const SizedBox(height: 24),
                  Obx(() => CategoryFeaturedSwitch(
                        value: _categoryController.isFeatured.value,
                        onChanged: (value) {
                          _categoryController.isFeatured.value = value;
                        },
                      )),
                ],
              ),
              const SizedBox(height: 32),

              // Bouton Ajouter
              Obx(() => CategorySubmitButton(
                    isLoading: _categoryController.isLoading.value,
                    onPressed: () async {
                      await _categoryController.addCategory();
                    },
                    text: "Ajouter la catégorie",
                    icon: Icons.add_circle_outline,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}