import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:caferesto/features/shop/models/category_model.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../shop/controllers/category_controller.dart';
import '../widgets/loading_screen.dart';
import 'add_category_screen.dart';
import 'edit_category_screen.dart';

class CategoryManagementPage extends StatelessWidget {
  CategoryManagementPage({super.key});

  final controller = Get.find<CategoryController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildSearchAndFilterBar(context),
          Expanded(child: _buildBody(context)),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar(context) {
    return TAppBar(
      title: const Text("Gestion des catégories"),
      doubleAppBarHeight: true,
      bottomWidget: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: _buildElegantTabs(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value)
        return LoadingScreen(
          screenName: 'Catégories',
        );
      if (controller.allCategories.isEmpty) {
        return _buildEmptyState();
      }

      return TabBarView(
        controller: controller.tabController,
        children: [
          _buildCategoryList(context, false),
          _buildCategoryList(context, true),
        ],
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Aucune catégorie trouvée",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text("Commencez par ajouter votre première catégorie",
              style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.to(() => AddCategoryScreen()),
            icon: const Icon(Iconsax.add),
            label: const Text("Ajouter une catégorie"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, bool isSubcategory) {
    final categories = controller.getFilteredCategories(isSubcategory);

    if (categories.isEmpty) {
      return Center(
        child: Text(
          controller.searchQuery.value.isNotEmpty
              ? "Aucun résultat pour votre recherche"
              : "Aucune catégorie ${isSubcategory ? 'secondaire' : 'principale'}",
          style: TextStyle(color: Colors.grey[600], fontSize: 15),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refreshCategories,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.defaultSpace),
        itemCount: categories.length,
        itemBuilder: (_, i) => _buildCategoryCard(categories[i], context),
      ),
    );
  }

  Widget _buildEmptyTabState(bool isSubcategory, BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.refreshCategories,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSubcategory
                      ? Icons.subdirectory_arrow_right
                      : Icons.category,
                  size: 60,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  isSubcategory
                      ? "Aucune sous-catégorie"
                      : "Aucune catégorie principale",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  isSubcategory
                      ? "Les sous-catégories apparaîtront ici"
                      : "Les catégories principales apparaîtront ici",
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category, BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: dark ? AppColors.eerieBlack : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildCategoryImage(category),
        title: Text(category.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: _buildCategorySubtitle(category),
        trailing: _buildFeaturedBadge(category),
        onTap: () => _showCategoryOptions(context, category),
      ),
    );
  }

  Widget _buildCategoryImage(CategoryModel category) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          category.image,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Icon(Icons.category, color: Colors.grey[400], size: 24),
          loadingBuilder: (context, child, loading) {
            if (loading == null) return child;
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2));
          },
        ),
      ),
    );
  }

  Widget _buildCategorySubtitle(CategoryModel category) {
    if (category.parentId != null) {
      return Text(
        "Sous-catégorie • ${controller.getParentName(category.parentId!)}",
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      );
    }

    final count =
        controller.allCategories.where((c) => c.parentId == category.id).length;

    return Text(
      count == 0
          ? "Catégorie principale"
          : "Catégorie principale • $count sous-catégorie${count > 1 ? 's' : ''}",
      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
    );
  }

  Widget _buildFeaturedBadge(CategoryModel category) {
    if (!category.isFeatured) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.star, color: Colors.amber.shade600, size: 14),
        const SizedBox(width: 4),
        Text("Vedette",
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade700))
      ]),
    );
  }

  Widget _buildFloatingActionButton() => FloatingActionButton(
        onPressed: () => Get.to(() => AddCategoryScreen()),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Iconsax.additem, size: 28),
      );

  void _showCategoryOptions(BuildContext context, CategoryModel category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildBottomSheetContent(context, category),
    );
  }

  Widget _buildBottomSheetContent(
      BuildContext context, CategoryModel category) {
    final dark = THelperFunctions.isDarkMode(context);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.eerieBlack : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBottomSheetHeader(category),
          const SizedBox(height: 16),
          _buildActionButtons(context, category),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 12)),
                child: const Text("Annuler"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheetHeader(CategoryModel category) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildCategoryImage(category),
          const SizedBox(width: 16),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(category.name,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              _buildCategorySubtitle(category),
              if (category.isFeatured) ...[
                const SizedBox(height: 8),
                _buildFeaturedBadge(category),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, CategoryModel category) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Get.to(() => EditCategoryScreen(category: category));
            },
            icon: const Icon(Iconsax.edit, size: 20),
            label: const Text("Éditer"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue.shade700,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showDeleteDialog(context, category),
            icon: const Icon(Iconsax.trash, size: 20),
            label: const Text("Supprimer"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  void _showDeleteDialog(BuildContext context, CategoryModel category) {
    Navigator.pop(context);
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber),
            SizedBox(width: 12),
            Text("Confirmer la suppression"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Supprimer la catégorie \"${category.name}\" ?"),
            const SizedBox(height: 8),
            Text("Cette action est irréversible.",
                style: TextStyle(
                    color: Colors.red.shade600, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back(),
              child:
                  const Text("Annuler", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.removeCategory(category.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text("Supprimer"),
          )
        ],
      ),
    );
  }

  Widget _buildElegantTabs(BuildContext context) {
    final selectedIndex = controller.tabController.index.obs;
    final dark = THelperFunctions.isDarkMode(context);

    controller.tabController.addListener(() {
      selectedIndex.value = controller.tabController.index;
    });

    final tabs = ["Catégories", "Sous-catégories"];

    return Obx(() {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: dark ? AppColors.eerieBlack : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final isSelected = selectedIndex.value == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => controller.tabController.animateTo(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeInOut,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? Colors.blue.shade600 : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      tabs[i],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }

  // --- Search + Filter Bar ---
  Widget _buildSearchAndFilterBar(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.defaultSpace),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: TextField(
              onChanged: controller.updateSearch,
              decoration: InputDecoration(
                hintText: "Rechercher une catégorie...",
                prefixIcon: const Icon(Iconsax.search_normal_1, size: 20),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: dark ? AppColors.eerieBlack : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Filter Button
          Obx(() {
            final isFeatured =
                controller.selectedFilter.value == CategoryFilter.featured;
            return GestureDetector(
              onTap: () {
                controller.updateFilter(
                    isFeatured ? CategoryFilter.all : CategoryFilter.featured);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color:
                      isFeatured ? Colors.amber.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: isFeatured
                          ? Colors.amber.shade800
                          : Colors.grey.shade600,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isFeatured ? "Vedettes" : "Toutes",
                      style: TextStyle(
                        color: isFeatured
                            ? Colors.amber.shade800
                            : Colors.grey.shade700,
                        fontWeight:
                            isFeatured ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
