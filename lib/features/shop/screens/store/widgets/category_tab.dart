import 'package:caferesto/common/widgets/texts/section_heading.dart';
import 'package:caferesto/features/shop/controllers/category_controller.dart';
import 'package:caferesto/features/shop/screens/store/widgets/category_brands.dart';
import 'package:flutter/material.dart';

import '../../../../../common/widgets/products/product_cards/product_card_horizontal.dart';
import '../../../../../common/widgets/shimmer/horizontal_product_shimmer.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../models/category_model.dart';

class CategoryTab extends StatelessWidget {
  const CategoryTab({super.key, required this.category});

  final CategoryModel category;

  // Responsive card width
  double _getCardWidth(double screenWidth) {
    if (screenWidth > 1200) {
      return 380.0; // Large screens (PC)
    } else if (screenWidth > 900) {
      return 340.0; // Medium screens (tablets)
    } else if (screenWidth > 600) {
      return 300.0; // Small tablets
    } else {
      return 280.0; // Mobile
    }
  }

  // Responsive card height
  double _getCardHeight(double screenWidth) {
    if (screenWidth > 1200) {
      return 160.0;
    } else if (screenWidth > 600) {
      return 150.0;
    } else {
      return 140.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = CategoryController.instance;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;
    final cardWidth = _getCardWidth(screenWidth);
    final cardHeight = _getCardHeight(screenWidth);

    return ListView(
        shrinkWrap: false,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.defaultSpace),
            child: Column(
              children: [
                /// Brands
                CategoryBrands(category: category),
                const SizedBox(
                  height: AppSizes.spaceBtwItems,
                ),

                /// Products - Display all products horizontally
                FutureBuilder(
                    future: controller.getCategoryProducts(
                        categoryId: category.id, limit: -1),
                    builder: (context, snapshot) {
                      // Handle loading state
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          height: cardHeight,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 3,
                            itemBuilder: (_, __) => Padding(
                              padding: const EdgeInsets.only(
                                  right: AppSizes.spaceBtwItems),
                              child: SizedBox(
                                width: cardWidth,
                                child: THorizontalProductShimmer(),
                              ),
                            ),
                          ),
                        );
                      }

                      // Handle error state
                      if (snapshot.hasError) {
                        return const SizedBox.shrink();
                      }

                      // Handle empty state - just return empty, no message
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      /// Records found
                      final products = snapshot.data!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TSectionHeading(
                            title: category.name,
                            showActionButton: false,
                          ),
                          const SizedBox(
                            height: AppSizes.spaceBtwItems,
                          ),
                          SizedBox(
                            height: cardHeight,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: products.length,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.defaultSpace),
                              separatorBuilder: (context, index) => SizedBox(
                                width: isLargeScreen
                                    ? AppSizes.spaceBtwItems
                                    : AppSizes.spaceBtwItems / 1.2,
                              ),
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return SizedBox(
                                  width: cardWidth,
                                  child: TProductCardHorizontal(
                                      product: product),
                                );
                              },
                            ),
                          ),
                          const SizedBox(
                            height: AppSizes.spaceBtwSections,
                          ),
                        ],
                      );
                    }),
              ],
            ),
          ),
        ]);
  }
}
