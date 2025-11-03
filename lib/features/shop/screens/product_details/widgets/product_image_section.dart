import 'package:caferesto/features/shop/models/produit_model.dart';
import 'package:flutter/material.dart';
import 'product_detail_image_slider.dart';
import 'product_image_placeholder.dart';

class ProductImageSection extends StatelessWidget {
  const ProductImageSection({
    super.key,
    required this.product,
    required this.dark,
  });

  final ProduitModel product;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final hasImage = product.imageUrl.isNotEmpty;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 300,
        maxHeight: 500,
      ),
      child: hasImage
          ? TProductImageSlider(product: product)
          : ProductImagePlaceholder(dark: dark),
    );
  }
}

