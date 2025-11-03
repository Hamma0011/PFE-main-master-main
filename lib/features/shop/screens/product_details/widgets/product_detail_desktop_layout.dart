import 'package:caferesto/features/shop/models/produit_model.dart';
import 'package:flutter/material.dart';
import 'product_details_content.dart';
import 'product_image_section.dart';

class ProductDetailDesktopLayout extends StatelessWidget {
  const ProductDetailDesktopLayout({
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
    return LayoutBuilder(
      builder: (context, outerConstraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - Images
              Expanded(
                flex: 2,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: outerConstraints.maxHeight,
                  ),
                  child: ProductImageSection(product: product, dark: dark),
                ),
              ),

              const SizedBox(width: 40),

              // Right side - Details
              Expanded(
                flex: 1,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: outerConstraints.maxHeight,
                  ),
                  child: SingleChildScrollView(
                    child: ProductDetailsContent(
                      product: product,
                      dark: dark,
                      excludeVariationId: excludeVariationId,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

