import 'package:caferesto/common/widgets/appbar/appbar.dart';
import 'package:caferesto/common/widgets/brands/brand_card.dart';
import 'package:caferesto/common/widgets/products/sortable/sortable_products.dart';
import 'package:caferesto/features/shop/controllers/product/all_products_controller.dart';
import 'package:caferesto/features/shop/models/etablissement_model.dart';
import 'package:caferesto/features/shop/controllers/category_controller.dart';
import 'package:caferesto/features/shop/models/statut_etablissement_model.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/shimmer/brand_products_shimmer.dart';

class BrandProducts extends StatefulWidget {
  const BrandProducts({super.key, required this.brand});

  final Etablissement brand;

  @override
  State<BrandProducts> createState() => _BrandProductsState();
}

class _BrandProductsState extends State<BrandProducts> {
  late AllProductsController controller;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(AllProductsController());
    _loadProducts();
  }

  @override
  void didUpdateWidget(BrandProducts oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si l'établissement a changé, recharger les produits
    if (oldWidget.brand.id != widget.brand.id) {
      _hasInitialized = false;
      _loadProducts();
    }
  }

  void _loadProducts() {
    if (_hasInitialized) return;
    _hasInitialized = true;

    // Vérifier le statut de l'établissement avant de charger les produits
    if (widget.brand.statut != StatutEtablissement.approuve) {
      return;
    }

    // Initialiser le chargement et charger les produits
    controller.setBrandCategoryFilter(''); // Reset filter when changing brand
    
    // Toujours réinitialiser l'état de chargement et vider la liste avant de charger
    final brandId = widget.brand.id ?? '';
    controller.isLoading.value = true;
    controller.brandProducts.clear();
    controller.fetchBrandProducts(brandId);
  }

  @override
  Widget build(BuildContext context) {
    // Vérifier le statut de l'établissement avant d'afficher
    if (widget.brand.statut != StatutEtablissement.approuve) {
      return Scaffold(
        appBar: TAppBar(title: Text(widget.brand.name)),
        body: const Center(
          child: Text('Les produits de cet établissement ne sont pas disponibles.'),
        ),
      );
    }

    return Scaffold(
      appBar: TAppBar(title: Text(widget.brand.name)),
      body: Obx(() {
        // Afficher le shimmer pendant le chargement
        if (controller.isLoading.value) {
          return const TBrandProductsShimmer();
        }

        // Afficher "Aucun produit" seulement si le chargement est terminé et qu'il n'y a vraiment aucun produit
        if (controller.brandProducts.isEmpty) {
          return const Center(child: Text('Aucun produit trouvé.'));
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            children: [
              BrandCard(showBorder: true, brand: widget.brand),
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
