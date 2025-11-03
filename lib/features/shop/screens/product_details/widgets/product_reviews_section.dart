import 'package:caferesto/features/shop/screens/product_reviews/product_reviews.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductReviewsSection extends StatelessWidget {
  const ProductReviewsSection({
    super.key,
    required this.dark,
  });

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? Colors.grey.shade900 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Avis des clients',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: dark ? Colors.white : Colors.black,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: dark
                      ? Colors.green.shade900.withOpacity(0.3)
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: dark ? Colors.green.shade800 : Colors.green.shade100,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '4.8/5',
                      style: TextStyle(
                        color: dark
                            ? Colors.green.shade300
                            : Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Basé sur 199 achats vérifiés',
            style: TextStyle(
              color: dark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => Get.to(() => const ProductReviewsScreen()),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: dark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Voir tous les avis',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded,
                      size: 16, color: Colors.green.shade600),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
