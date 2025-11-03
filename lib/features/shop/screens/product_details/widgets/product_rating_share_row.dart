import 'package:caferesto/features/shop/controllers/product/favorites_controller.dart';
import 'package:caferesto/features/shop/controllers/product/share_controller.dart';
import 'package:caferesto/features/shop/models/produit_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductRatingShareRow extends StatelessWidget {
  const ProductRatingShareRow({
    super.key,
    required this.product,
    required this.dark,
  });

  final ProduitModel product;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        /// Rating
        Row(
          children: [
            Icon(Icons.star_rounded, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text(
              '4.8',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: dark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(199 reviews)',
              style: TextStyle(
                color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),

        /// Share & Favorite
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: dark ? Colors.grey.shade800 : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: InkWell(
                onTap: () => ShareController.instance.shareProduct(product),
                child: Icon(
                  Icons.share_rounded,
                  size: 18,
                  color: dark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Obx(() {
              final isFav =
                  FavoritesController.instance.isFavourite(product.id);
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: dark ? Colors.grey.shade800 : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: InkWell(
                  onTap: () => FavoritesController.instance
                      .toggleFavoriteProduct(product.id),
                  child: Icon(
                    isFav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 18,
                    color: isFav
                        ? Colors.red
                        : (dark ? Colors.grey.shade300 : Colors.grey.shade700),
                  ),
                ),
              );
            })
          ],
        ),
      ],
    );
  }
}
