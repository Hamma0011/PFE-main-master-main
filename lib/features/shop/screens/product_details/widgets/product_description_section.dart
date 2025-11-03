import 'package:caferesto/features/shop/models/produit_model.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:readmore/readmore.dart';

class ProductDescriptionSection extends StatelessWidget {
  const ProductDescriptionSection({
    super.key,
    required this.product,
    required this.dark,
  });

  final ProduitModel product;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: dark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        ReadMoreText(
          product.description ??
              'Aucune description disponible pour ce produit.',
          trimLines: 3,
          trimMode: TrimMode.Line,
          trimCollapsedText: 'Voir plus',
          trimExpandedText: 'Voir moins',
          moreStyle: TextStyle(
            color: Colors.green.shade600,
            fontWeight: FontWeight.w600,
          ),
          lessStyle: TextStyle(
            color: Colors.green.shade600,
            fontWeight: FontWeight.w600,
          ),
          style: TextStyle(
            color: dark ? Colors.grey.shade300 : Colors.grey.shade700,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
