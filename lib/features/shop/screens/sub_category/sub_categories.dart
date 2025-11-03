import 'package:caferesto/common/widgets/appbar/appbar.dart';
import 'package:caferesto/common/widgets/images/t_rounded_image.dart';
import 'package:caferesto/common/widgets/texts/section_heading.dart';
import 'package:caferesto/features/shop/controllers/category_controller.dart';
import 'package:caferesto/utils/constants/image_strings.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/helpers/cloud_helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/products/product_cards/product_card_horizontal.dart';
import '../../../../common/widgets/shimmer/horizontal_product_shimmer.dart';
import '../../models/category_model.dart';
import '../../models/produit_model.dart';
import '../all_products/all_products.dart';

class SubCategoriesScreen extends StatelessWidget {
  const SubCategoriesScreen({super.key, required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    final controller = CategoryController.instance;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      appBar: TAppBar(
        title: Text(category.name),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(
            isLargeScreen ? AppSizes.defaultSpace * 1.5 : AppSizes.defaultSpace,
          ),
          child: Column(
            children: [
              /// Banner Responsive
              _buildResponsiveBanner(screenWidth, screenHeight),
              SizedBox(
                height: isLargeScreen
                    ? AppSizes.spaceBtwSections * 1.5
                    : AppSizes.spaceBtwSections,
              ),

              /// Subcategories
              FutureBuilder(
                future: controller.getSubCategories(category.id),
                builder: (context, snapshot) {
                  final loader = THorizontalProductShimmer(
                    itemCount: isLargeScreen ? 6 : 4,
                    cardHeight: _getCardHeight(screenWidth),
                  );
                  final widget = TCloudHelperFunctions.checkMultiRecordState(
                    snapshot: snapshot,
                    loader: loader,
                  );
                  if (widget != null) return widget;

                  final subCategories = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: subCategories.length,
                    itemBuilder: (_, index) {
                      final subCategory = subCategories[index];
                      return _buildSubCategorySection(
                        context,
                        subCategory,
                        controller,
                        screenWidth,
                        isLargeScreen,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------- RESPONSIVE BANNER ----------------------
  Widget _buildResponsiveBanner(double screenWidth, double screenHeight) {
    final bannerHeight = _getBannerHeight(screenWidth, screenHeight);

    return Container(
      width: double.infinity,
      height: bannerHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        child: TRoundedImage(
          imageUrl: TImages.promoBanner3,
          applyImageRadius: false,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  double _getBannerHeight(double screenWidth, double screenHeight) {
    if (screenWidth >= 1050) {
      return 300; // Desktop
    } else if (screenWidth >= 600) {
      return 240; // Tablet
    } else {
      return 180; // Mobile
    }
  }

  double _getCardHeight(double screenWidth) {
    if (screenWidth >= 1050) {
      return 140; // Desktop compact
    } else if (screenWidth >= 600) {
      return 130; // Tablet
    } else {
      return 120; // Mobile
    }
  }

  double _getCardWidth(double screenWidth) {
    if (screenWidth >= 1050) {
      return 260; // Desktop - permet plus de produits visibles
    } else if (screenWidth >= 600) {
      return 240; // Tablet
    } else {
      return 280; // Mobile
    }
  }

  // ---------------------- SUBCATEGORY SECTION ----------------------
  Widget _buildSubCategorySection(
    BuildContext context,
    CategoryModel subCategory,
    CategoryController controller,
    double screenWidth,
    bool isLargeScreen,
  ) {
    return FutureBuilder(
      future: controller.getCategoryProducts(categoryId: subCategory.id),
      builder: (context, snapshot) {
        final loader = THorizontalProductShimmer(
          itemCount: isLargeScreen ? 4 : 3,
          cardHeight: _getCardHeight(screenWidth),
        );
        final widget = TCloudHelperFunctions.checkMultiRecordState(
          snapshot: snapshot,
          loader: loader,
        );
        if (widget != null) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: isLargeScreen
                  ? AppSizes.spaceBtwSections * 1.5
                  : AppSizes.spaceBtwSections,
            ),
            child: widget,
          );
        }

        final products = snapshot.data!;
        if (products.isEmpty) return const SizedBox();

        return Padding(
          padding: EdgeInsets.only(
            bottom: isLargeScreen
                ? AppSizes.spaceBtwSections * 1.5
                : AppSizes.spaceBtwSections,
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? AppSizes.defaultSpace : 0,
                ),
                child: TSectionHeading(
                  title: subCategory.name,
                  onPressed: () => Get.to(
                    () => AllProducts(
                      title: subCategory.name,
                      futureMethod: controller.getCategoryProducts(
                        categoryId: subCategory.id,
                        limit: -1,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: isLargeScreen
                    ? AppSizes.spaceBtwItems
                    : AppSizes.spaceBtwItems / 2,
              ),
              _buildHorizontalProductList(
                context,
                products: products,
                screenWidth: screenWidth,
                isLargeScreen: isLargeScreen,
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------- PRODUCT LIST WITH HOVER EFFECT ----------------------
  Widget _buildHorizontalProductList(
    BuildContext context, {
    required List<ProduitModel> products,
    required double screenWidth,
    required bool isLargeScreen,
  }) {
    final scrollController = ScrollController();
    final cardWidth = _getCardWidth(screenWidth);
    final cardHeight = _getCardHeight(screenWidth);

    // Flèches visibles uniquement sur petits écrans
    final showArrows = products.length > 1 && !isLargeScreen;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            padding: EdgeInsets.symmetric(horizontal: AppSizes.defaultSpace),
            separatorBuilder: (context, index) => SizedBox(
              width: isLargeScreen
                  ? AppSizes.spaceBtwItems
                  : AppSizes.spaceBtwItems / 1.2,
            ),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: cardWidth,
                child: MouseRegion(
                  onEnter: (_) {},
                  onExit: (_) {},
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    transform: isLargeScreen
                        ? (Matrix4.identity()..scale(1.0))
                        : Matrix4.identity(),
                    child: InkWell(
                      hoverColor: Colors.transparent,
                      onTap: () {},
                      child: Card(
                        elevation: isLargeScreen ? 2 : 1,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.cardRadiusMd),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: TProductCardHorizontal(product: product),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        /// Flèches uniquement sur mobile/tablette
        if (showArrows) ...[
          Positioned(
            left: 4,
            child: _buildNavigationArrow(
              context: context,
              onTap: () {
                final currentPosition = scrollController.offset;
                final newPosition =
                    currentPosition - cardWidth - AppSizes.spaceBtwItems;
                scrollController.animateTo(
                  newPosition.clamp(
                      0.0, scrollController.position.maxScrollExtent),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              icon: Icons.arrow_back_ios_new_rounded,
            ),
          ),
          Positioned(
            right: 4,
            child: _buildNavigationArrow(
              context: context,
              onTap: () {
                final currentPosition = scrollController.offset;
                final newPosition =
                    currentPosition + cardWidth + AppSizes.spaceBtwItems;
                scrollController.animateTo(
                  newPosition.clamp(
                      0.0, scrollController.position.maxScrollExtent),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              icon: Icons.arrow_forward_ios_rounded,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNavigationArrow({
    required BuildContext context,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadiusLg),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 18,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}
