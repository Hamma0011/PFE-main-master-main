import 'package:caferesto/features/shop/models/produit_model.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'product_attributes.dart';
import 'product_description_section.dart';
import 'product_meta_data.dart';
import 'product_rating_share_row.dart';

class ProductDetailsContent extends StatelessWidget {
  const ProductDetailsContent({
    super.key,
    required this.product,
    required this.dark,
    this.excludeVariationId,
  });

  final ProduitModel product;
  final bool dark;
  final String? excludeVariationId; // Variation to exclude from disabled list (for edit mode)

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        /// Rating & Share
        ProductRatingShareRow(product: product, dark: dark),

        const SizedBox(height: AppSizes.md),

        /// Product Meta Data
        TProductMetaData(product: product),

        const SizedBox(height: AppSizes.lg),

        /// Attributes for variable products
        if (product.productType == 'variable')
          TProductAttributes(
            product: product,
            excludeVariationId: excludeVariationId,
          ),

        const SizedBox(height: AppSizes.xl),

        /// Description
        ProductDescriptionSection(product: product, dark: dark),

        const SizedBox(height: AppSizes.xl),

        /// Reviews Preview
        // ProductReviewsSection(dark: dark),

        // const SizedBox(height: 100), // Space for bottom bar
      ],
    );
  }
}

