// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:caferesto/common/widgets/products/product_cards/widgets/aucune_image.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../features/shop/controllers/product/favorites_controller.dart';
import '../../../../features/shop/controllers/product/produit_controller.dart';
import '../../../../features/shop/models/produit_model.dart';
import '../../../../features/shop/screens/product_details/product_detail.dart';
import '../../../../features/shop/controllers/category_controller.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../styles/shadows.dart';
import '../../texts/brand_title_text_with_verified_icon.dart';
import '../../texts/product_price_text.dart';
import '../../texts/product_title_text.dart';
import 'widgets/add_to_cart_button.dart';

class ProductCardVertical extends StatelessWidget {
  const ProductCardVertical({
    super.key,
    required this.product,
    this.onFavoriteTap,
  });

  final ProduitModel product;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final controller = ProduitController.instance;
    final salePercentage =
        controller.calculateSalePercentage(product.price, product.salePrice);
    final dark = THelperFunctions.isDarkMode(context);

    return GestureDetector(
      onTap: () => Get.to(() => ProductDetailScreen(
            product: product,
          )),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: dark ? AppColors.eerieBlack : AppColors.white,
          borderRadius: BorderRadius.circular(AppSizes.defaultSpace),
          boxShadow: [TShadowStyle.vericalCardProductShadow],
        ),
        constraints: const BoxConstraints(
          minHeight: 0, // Permet à la carte de rétrécir si besoin
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Thumbnail
            Stack(
              children: [
                /// -- Thumbnail Image
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: _buildProductImage(),
                ),

                /// Overlay avec effets
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 50,
                          child: ClipRect(
                            child: BackdropFilter(
                              filter:
                                  ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
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
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.xs,
                                horizontal: AppSizes.sm,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(
                                    AppSizes.buttonRadius),
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

                        /// -- Favorite Icon Button
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            decoration: BoxDecoration(
                              color: dark
                                  ? Colors.black.withAlpha((255 * 0.3).toInt())
                                  : AppColors.white,
                              shape: BoxShape.circle,
                            ),
                            child: _buildFavoriteIcon(context),
                          ),
                        ),

                        /// Category Badge
                        _CategoryBadge(product: product, dark: dark),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.spaceBtwItems / 2),

            /// Product info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BrandTitleWithVerifiedIcon(
                    title: product.etablissement?.name ?? 'null',
                    textColor: dark ? Colors.white70 : Colors.grey[700],
                  ),
                  const SizedBox(height: AppSizes.spaceBtwItems / 2),

                  /// Title
                  TProductTitleText(
                    title: product.name,
                    maxLines: 1,
                    smallSize: true,
                  ),
                ],
              ),
            ),

            /// Price and cart button
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.productType == 'single' &&
                            product.salePrice > 0)
                          Text(
                            '${product.price} DT',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    ),
                          ),
                        ProductPriceText(
                          variable: product.productType == 'variable',
                          price: controller.getProductPrice(product),
                          isLarge: false,
                        ),
                      ],
                    ),
                  ),
                  ProductCardAddToCartButton(product: product),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build favorite icon with custom onTap callback
  Widget _buildFavoriteIcon(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    return Obx(() {
      final isFavorite = FavoritesController.instance.isFavourite(product.id);

      return GestureDetector(
        onTap: onFavoriteTap ??
            () {
              FavoritesController.instance.toggleFavoriteProduct(product.id);
            },
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dark
                ? Colors.black.withAlpha(100)
                : Colors.white.withAlpha(200),
          ),
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite
                ? Colors.redAccent
                : (dark ? Colors.grey.shade300 : Colors.grey.shade600),
            size: 16,
          ),
        ),
      );
    });
  }

  /// Méthode pour construire l'image du produit (supporte réseau et assets)
  Widget _buildProductImage() {
    // Si l'URL de l'image commence par http, c'est une image réseau
    if (product.imageUrl.isNotEmpty && product.imageUrl.startsWith('http')) {
      return Image.network(
        product.imageUrl,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageErrorWidget();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildImageLoadingWidget(loadingProgress);
        },
      );
    }

    // Si c'est un asset local
    if (product.imageUrl.isNotEmpty) {
      return Image.asset(
        product.imageUrl,
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageErrorWidget();
        },
      );
    }

    // Si aucune image n'est disponible
    return AucuneImageWidget(height: 150, iconSize: 40, textSize: 12);
  }

  Widget _buildImageErrorWidget() {
    return Container(
      height: 150,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.grey, size: 40),
          SizedBox(height: 8),
          Text(
            'Erreur image',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildImageLoadingWidget(ImageChunkEvent loadingProgress) {
    return Container(
      height: 150,
      width: double.infinity,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.product, required this.dark});

  final ProduitModel product;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final categoryController = CategoryController.instance;
    String categoryName = '';
    try {
      categoryName = categoryController.allCategories
          .firstWhere((c) => c.id == product.categoryId)
          .name;
    } catch (_) {}

    if (categoryName.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color:
              dark ? Colors.black.withAlpha(140) : Colors.white.withAlpha(230),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: dark ? Colors.white24 : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Text(
          categoryName,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: dark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
