import 'dart:io';

import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import '../../../../../utils/constants/image_strings.dart';
import '../../../../shop/models/category_model.dart';

/// Widget pour la section image avec caméra
class CategoryImageSection extends StatelessWidget {
  final VoidCallback onPickImage;
  final File? pickedImage;
  final String? existingImageUrl;

  const CategoryImageSection({
    super.key,
    required this.onPickImage,
    this.pickedImage,
    this.existingImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 70,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 65,
                backgroundImage: _getImageProvider(),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: _buildCameraButton(),
          ),
        ],
      ),
    );
  }

  ImageProvider _getImageProvider() {
    if (pickedImage != null) {
      return FileImage(pickedImage!);
    } else if (existingImageUrl != null && existingImageUrl!.isNotEmpty) {
      return NetworkImage(existingImageUrl!);
    } else {
      return const AssetImage(TImages.pasdimage);
    }
  }

  Widget _buildCameraButton() {
    return GestureDetector(
      onTap: onPickImage,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.camera_alt,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

/// Widget pour le champ nom de catégorie
class CategoryNameField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const CategoryNameField({
    super.key,
    required this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Nom de la catégorie",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Entrez le nom",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
            ),
            prefixIcon: Icon(Icons.category, color: Colors.grey[400]),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator ?? _defaultValidator,
        ),
      ],
    );
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return "Nom requis";
    }
    return null;
  }
}

/// Widget pour le dropdown des catégories parentes
class CategoryParentDropdown extends StatelessWidget {
  final String? selectedParentId;
  final List<CategoryModel> categories;
  final Function(String?) onChanged;
  final String? excludeCategoryId;

  const CategoryParentDropdown({
    super.key,
    required this.selectedParentId,
    required this.categories,
    required this.onChanged,
    this.excludeCategoryId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Catégorie parente",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          value: selectedParentId,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
            ),
            prefixIcon: Icon(Icons.folder, color: Colors.grey[400]),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: _buildDropdownItems(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  List<DropdownMenuItem<String?>> _buildDropdownItems() {
    final items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(
        value: null,
        child: Text("Aucune"),
      ),
    ];

    final filteredCategories =
        categories.where((cat) => cat.id != excludeCategoryId).toList();

    items.addAll(
      filteredCategories
          .map((cat) => DropdownMenuItem<String?>(
                value: cat.id,
                child: Text(cat.name),
              ))
          .toList(),
    );

    return items;
  }
}

/// Widget pour le switch en vedette
class CategoryFeaturedSwitch extends StatelessWidget {
  final bool value;
  final Function(bool) onChanged;

  const CategoryFeaturedSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        title: const Text(
          "Catégorie en vedette",
          style: TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          "Afficher dans les catégories populaires",
          style: TextStyle(
            fontSize: 12,
          ),
        ),
        value: value,
        activeColor: Colors.blue.shade400,
        onChanged: onChanged,
      ),
    );
  }
}

/// Widget pour le bouton de soumission
class CategorySubmitButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final String text;
  final IconData icon;

  const CategorySubmitButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: Colors.blue.withOpacity(0.3),
        ).copyWith(
          elevation: MaterialStateProperty.resolveWith<double>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) return 0;
              return 8;
            },
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Container de formulaire stylisé
class CategoryFormCard extends StatelessWidget {
  final List<Widget> children;

  const CategoryFormCard({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      decoration: BoxDecoration(
        color: dark ? AppColors.eerieBlack : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
