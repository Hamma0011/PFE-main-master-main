import 'package:caferesto/features/shop/models/produit_model.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'product_details_content.dart';
import 'product_image_section.dart';

class ProductDetailMobileLayout extends StatelessWidget {
  const ProductDetailMobileLayout({
    super.key,
    required this.product,
    required this.dark,
    this.excludeVariationId,
  });

  final ProduitModel product;
  final bool dark;
  final String? excludeVariationId;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// 1 - Product Image Section
          ProductImageSection(product: product, dark: dark),

          /// 2 - Product Details
          Padding(
            padding: const EdgeInsets.all(AppSizes.defaultSpace),
            child: ProductDetailsContent(
              product: product,
              dark: dark,
              excludeVariationId: excludeVariationId,
            ),
          ),
        ],
      ),
    );
  }
}

