import 'dart:ui';

import 'package:caferesto/common/widgets/products/favorite_icon/favorite_icon.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../features/shop/controllers/product/produit_controller.dart';
import '../../../../features/shop/models/produit_model.dart';
import '../../../../features/shop/screens/product_details/product_detail.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../features/shop/controllers/category_controller.dart';
import '../../../styles/shadows.dart';
import '../../texts/brand_title_text_with_verified_icon.dart';
import '../../texts/product_price_text.dart';
import '../../texts/product_title_text.dart';
import 'widgets/add_to_cart_button.dart';
import 'widgets/aucune_image.dart';
import 'widgets/chargement_image_widget.dart';
import 'widgets/erreur_image_widget.dart';
import 'widgets/rounded_container.dart';

class TProductCardHorizontal extends StatelessWidget {
  const TProductCardHorizontal({super.key, required this.product});

  final ProduitModel product;

  @override
  Widget build(BuildContext context) {
    final controller = ProduitController.instance;
    final salePercentage =
        controller.calculateSalePercentage(product.price, product.salePrice);
    final dark = THelperFunctions.isDarkMode(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive width - will be overridden if parent provides width constraint
    final defaultCardWidth = screenWidth > 1200
        ? 380.0
        : screenWidth > 900
            ? 340.0
            : screenWidth > 600
                ? 300.0
                : 280.0;

    return GestureDetector(
      onTap: () => Get.to(() => ProductDetailScreen(product: product)),
      child: Container(
        width: defaultCardWidth,
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: dark ? AppColors.eerieBlack : AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.defaultSpace),
          boxShadow: [TShadowStyle.vericalCardProductShadow],
        ),
        child: Row(
          children: [
            /// Thumbnail Section
            _buildThumbnailSection(context, dark, salePercentage),

            /// Details Section
            Expanded(
              child: _buildDetailsSection(context, dark, salePercentage),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailSection(
      BuildContext context, bool dark, String? salePercentage) {
    final categoryController = CategoryController.instance;
    String categoryName = '';
    try {
      categoryName = categoryController.allCategories
          .firstWhere((c) => c.id == product.categoryId)
          .name;
    } catch (_) {}

    return Stack(
      children: [
        /// Thumbnail Container
        TRoundedContainer(
          height: 120,
          width: 120,
          padding: const EdgeInsets.all(AppSizes.sm),
          backgroundColor: dark ? AppColors.dark : AppColors.light,
          child: Stack(
            children: [
              /// Product Image
              _buildProductImage(),

              /// Overlay effects
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppSizes.productImageRadius),
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Stack(
                    children: [
                      /// Blur overlay
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 30,
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white
                                        .withAlpha((255 * 0.15).toInt()),
                                    Colors.white.withOpacity(0.01),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      /// Sale Tag
                      if (salePercentage != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.xs,
                              horizontal: AppSizes.sm,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius:
                                  BorderRadius.circular(AppSizes.buttonRadius),
                            ),
                            child: Text(
                              '- $salePercentage%',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                            ),
                          ),
                        ),

                      /// Favorite Icon
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: dark
                                ? Colors.black.withAlpha((255 * 0.3).toInt())
                                : AppColors.white,
                            shape: BoxShape.circle,
                          ),
                          child: FavoriteIcon(productId: product.id),
                        ),
                      ),

                      /// Category Badge
                      if (categoryName.isNotEmpty)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: dark
                                  ? Colors.black
                                      .withAlpha((255 * 0.6).toInt())
                                  : Colors.white
                                      .withAlpha((255 * 0.9).toInt()),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: dark
                                    ? Colors.white24
                                    : Colors.black.withOpacity(0.05),
                              ),
                            ),
                            child: Text(
                              categoryName,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: dark ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(
      BuildContext context, bool dark, String? salePercentage) {
    final controller = ProduitController.instance;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// Top Section - Brand and Title
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrandTitleWithVerifiedIcon(
                title: product.etablissement?.name ?? product.etablissementId,
                textColor: dark ? Colors.white70 : Colors.grey[700],
              ),
              const SizedBox(height: AppSizes.spaceBtwItems / 2),

              /// Product Title
              TProductTitleText(
                title: product.name,
                maxLines: 2,
                smallSize: true,
              ),
            ],
          ),

          /// Bottom Section - Price and Add to Cart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// Price Section
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Original Price (strikethrough) if on sale
                    if (product.isSingle && product.salePrice > 0)
                      Text(
                        '${product.price} DT',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                      ),

                    /// Current Price
                    ProductPriceText(
                      price: controller.getProductPrice(product),
                      isLarge: false,
                    ),
                  ],
                ),
              ),

              /// Add to Cart Button
              ProductCardAddToCartButton(product: product),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    // Si l'URL de l'image commence par http, c'est une image réseau
    if (product.imageUrl.isNotEmpty &&
        product.imageUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.productImageRadius),
        child: Image.network(
          product.imageUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return imageErreurWidget();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return chargementImageWidget(loadingProgress);
          },
        ),
      );
    }

    // Si c'est un asset local
    if (product.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.productImageRadius),
        child: Image.asset(
          product.imageUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return imageErreurWidget();
          },
        ),
      );
    }

    // Si aucune image n'est disponible
    return AucuneImageWidget();
  }
}