import 'package:caferesto/features/shop/screens/sub_category/sub_categories.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/image_text_widgets/vertical_image_text.dart';
import '../../../../../common/widgets/shimmer/category_shimmer.dart';
import '../../../../shop/controllers/category_controller.dart';
import '../../../../shop/models/category_model.dart';

class THomeCategories extends StatelessWidget {
  const THomeCategories({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final categoryController = Get.put(CategoryController());
    return Obx(() {
      if (categoryController.isLoading.value) {
        return const TCategoryShimmer();
      }
      if (categoryController.allCategories.isEmpty) {
        return Center(
          child: Text(
            'Aucune catégorie trouvée',
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .apply(color: Colors.white),
          ),
        );
      }

      // Construire la liste : d'abord les catégories vedettes, puis les top 8 par ventes
      final List<CategoryModel> categoriesToShow = [];
      
      // 1. Ajouter les catégories vedettes
      final featuredIds = categoryController.featuredCategories
          .map((cat) => cat.id)
          .toSet();
      categoriesToShow.addAll(categoryController.featuredCategories);
      
      // 2. Ajouter les top catégories par ventes (en excluant celles déjà ajoutées)
      final topBySales = categoryController.topCategoriesBySales
          .where((cat) => !featuredIds.contains(cat.id))
          .take(8)
          .toList();
      categoriesToShow.addAll(topBySales);
      
      // 3. Si on n'a pas assez de catégories, compléter avec les autres catégories
      if (categoriesToShow.length < 8) {
        final existingIds = categoriesToShow.map((cat) => cat.id).toSet();
        final additionalCategories = categoryController.allCategories
            .where((cat) => cat.id.isNotEmpty && !existingIds.contains(cat.id))
            .take(8 - categoriesToShow.length)
            .toList();
        categoriesToShow.addAll(additionalCategories);
      }

      if (categoriesToShow.isEmpty) {
        return Center(
          child: Text(
            'Aucune catégorie à afficher',
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .apply(color: Colors.white),
          ),
        );
      }

      return SizedBox(
        height: 150,
        child: ListView.builder(
            padding: const EdgeInsets.only(left: 16),
            shrinkWrap: true,
            itemCount: categoriesToShow.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, index) {
              final category = categoriesToShow[index];
              return TVerticalImageText(
                image: category.image,
                title: category.name,
                onTap: () =>
                    Get.to(() => SubCategoriesScreen(category: category)),
              );
            }),
      );
    });
  }
}
