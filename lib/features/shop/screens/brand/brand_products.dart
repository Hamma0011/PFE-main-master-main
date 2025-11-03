import 'package:caferesto/common/widgets/appbar/appbar.dart';
import 'package:caferesto/common/widgets/brands/brand_card.dart';
import 'package:caferesto/common/widgets/products/sortable/sortable_products.dart';
import 'package:caferesto/features/shop/controllers/product/all_products_controller.dart';
import 'package:caferesto/features/shop/models/etablissement_model.dart';
import 'package:caferesto/features/shop/controllers/category_controller.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/shimmer/vertical_product_shimmer.dart';

class BrandProducts extends StatelessWidget {
  const BrandProducts({super.key, required this.brand});

  final Etablissement brand;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AllProductsController());
    controller.setBrandCategoryFilter(''); // Reset filter when changing brand
    controller.fetchBrandProducts(brand.id ?? '');

    return Scaffold(
      appBar: TAppBar(title: Text(brand.name)),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const TVerticalProductShimmer();
        }

        if (controller.brandProducts.isEmpty) {
          return const Center(child: Text('Aucun produit trouvé.'));
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            children: [
              BrandCard(showBorder: true, brand: brand),
              SizedBox(height: AppSizes.spaceBtwSections),
              _CategoryFilterBar(),
              SizedBox(height: AppSizes.spaceBtwSections),
              Obx(() => TSortableProducts(
                    products: controller.filteredBrandProducts,
                    useBrandContext: true,
                  )),
            ],
          ),
        );
      }),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final productsController = Get.find<AllProductsController>();
    final categoryController = CategoryController.instance;

    // Ensure categories are loaded
    if (categoryController.allCategories.isEmpty &&
        !categoryController.isLoading.value) {
      categoryController.fetchCategories();
    }

    return Obx(() {
      // Wait for categories to be loaded if they're still loading
      if (categoryController.isLoading.value &&
          categoryController.allCategories.isEmpty) {
        return const SizedBox.shrink();
      }

      // Build unique category IDs from current brand products
      final categoryIds = productsController.brandProducts
          .map((p) => p.categoryId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (categoryIds.isEmpty) {
        return const SizedBox.shrink();
      }

      // Map to names using cached categories
      String getCategoryName(String id) {
        try {
          final category = categoryController.allCategories
              .firstWhereOrNull((c) => c.id == id);
          return category?.name ?? 'Catégorie';
        } catch (_) {
          return 'Catégorie';
        }
      }

      final selected = productsController.selectedBrandCategoryId.value;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: const Text('Tout'),
                selected: selected.isEmpty,
                onSelected: (_) => productsController.setBrandCategoryFilter(''),
              ),
            ),
            ...categoryIds.map((id) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(getCategoryName(id)),
                    selected: selected == id,
                    onSelected: (_) =>
                        productsController.setBrandCategoryFilter(id),
                  ),
                )),
          ],
        ),
      );
    });
  }
}
