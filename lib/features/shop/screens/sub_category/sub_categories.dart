import 'package:caferesto/common/widgets/appbar/appbar.dart';
import 'package:caferesto/features/shop/controllers/category_controller.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/device/device_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/layouts/grid_layout.dart';
import '../../../../common/widgets/products/product_cards/product_card_vertical.dart';
import '../../../../common/widgets/shimmer/vertical_product_shimmer.dart';
import '../../models/category_model.dart';
import '../../models/etablissement_model.dart';
import '../../models/produit_model.dart';
import '../../../../data/repositories/product/produit_repository.dart';

class SubCategoriesScreen extends StatefulWidget {
  const SubCategoriesScreen({super.key, required this.category});

  final CategoryModel category;

  @override
  State<SubCategoriesScreen> createState() => _SubCategoriesScreenState();
}

class _SubCategoriesScreenState extends State<SubCategoriesScreen> {
  final CategoryController categoryController = CategoryController.instance;
  final ProduitRepository produitRepository = ProduitRepository.instance;
  final Rx<Etablissement?> selectedEtablissement = Rx<Etablissement?>(null);
  final RxList<Etablissement> etablissements = <Etablissement>[].obs;
  final RxList<ProduitModel> allProducts = <ProduitModel>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadEtablissements();
  }

  Future<void> _loadProducts() async {
    try {
      isLoading.value = true;
      final products = await categoryController.getCategoryProducts(
        categoryId: widget.category.id,
        limit: -1,
      );
      if (products != null) {
        allProducts.assignAll(products);
      } else {
        allProducts.clear();
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des produits: $e');
      allProducts.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadEtablissements() async {
    try {
      final etabs = await produitRepository.getAllEtablissementsWithIds();
      etablissements.assignAll(etabs);
    } catch (e) {
      debugPrint('Erreur lors du chargement des établissements: $e');
    }
  }

  List<ProduitModel> get filteredProducts {
    if (selectedEtablissement.value == null) {
      return allProducts;
    }
    return allProducts
        .where((p) => p.etablissementId == selectedEtablissement.value!.id)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      appBar: TAppBar(
        title: Text(widget.category.name),
      ),
      body: Column(
        children: [
          /// Filtre par établissement
          _buildEtablissementFilter(context, isLargeScreen),

          /// Liste des produits
          Expanded(
            child: Obx(() {
              if (isLoading.value) {
                return const TVerticalProductShimmer();
              }

              final products = filteredProducts;

              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        selectedEtablissement.value != null
                            ? 'Aucun produit trouvé pour cet établissement'
                            : 'Aucun produit dans cette catégorie',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: EdgeInsets.all(
                  isLargeScreen
                      ? AppSizes.defaultSpace * 1.5
                      : AppSizes.defaultSpace,
                ),
                child: GridLayout(
                  itemCount: products.length,
                  itemBuilder: (_, index) => ProductCardVertical(
                    product: products[index],
                  ),
                  crossAxisCount: TDeviceUtils.getCrossAxisCount(screenWidth),
                  mainAxisExtent: TDeviceUtils.getMainAxisExtent(screenWidth),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEtablissementFilter(BuildContext context, bool isLargeScreen) {
    return Container(
      padding: EdgeInsets.all(
        isLargeScreen ? AppSizes.defaultSpace : AppSizes.defaultSpace / 1.5,
      ),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? AppColors.dark : AppColors.light,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() => Row(
            children: [
              Icon(
                Icons.filter_list,
                color: AppColors.primary,
                size: isLargeScreen ? 24 : 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<Etablissement>(
                  value: selectedEtablissement.value,
                  decoration: InputDecoration(
                    labelText: 'Filtrer par établissement',
                    labelStyle: TextStyle(
                      color: Get.isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                    filled: true,
                    fillColor:
                        Get.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  isExpanded: true,
                  style: TextStyle(
                    color: Get.isDarkMode ? Colors.white : Colors.black87,
                    fontSize: isLargeScreen ? 16 : 14,
                  ),
                  items: [
                    DropdownMenuItem<Etablissement>(
                      value: null,
                      child: Text(
                        'Tous les établissements',
                        style: TextStyle(
                          color:
                              Get.isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                    ...etablissements.map((etablissement) {
                      return DropdownMenuItem<Etablissement>(
                        value: etablissement,
                        child: Text(
                          etablissement.name,
                          style: TextStyle(
                            color:
                                Get.isDarkMode ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (Etablissement? value) {
                    selectedEtablissement.value = value;
                  },
                ),
              ),
              if (selectedEtablissement.value != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AppColors.primary,
                    size: isLargeScreen ? 24 : 20,
                  ),
                  onPressed: () {
                    selectedEtablissement.value = null;
                  },
                  tooltip: 'Effacer le filtre',
                ),
              ],
            ],
          )),
    );
  }
}
