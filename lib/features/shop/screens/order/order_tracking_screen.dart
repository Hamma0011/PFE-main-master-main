import 'package:caferesto/features/shop/screens/order/delivery_map_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/products/product_cards/widgets/rounded_container.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';

import '../../../../utils/helpers/helper_functions.dart';
import '../../models/order_model.dart';

class OrderTrackingScreen extends StatelessWidget {
  final OrderModel order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final backgroundColor = dark ? AppColors.dark : AppColors.light;
    final cardColor = dark ? Colors.grey[850]! : Colors.white;
    final textColor = dark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: TAppBar(
        title:
            Text("Détails de la commande", style: TextStyle(color: textColor)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            TRoundedContainer(
              width: double.infinity,
              backgroundColor: cardColor,
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Statut de la commande",
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order.orderStatusText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 12,
                    spacing: 8,
                    children: [
                      _infoColumn("Montant total", "${order.totalAmount} DT",
                          textColor),
                      _infoColumn(
                          "Date commande", order.formattedOrderDate, textColor),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.spaceBtwItems),

            // Delivery & Pickup Info
            if (order.pickupDay != null && order.pickupTimeRange != null)
              TRoundedContainer(
                backgroundColor: cardColor,
                padding: const EdgeInsets.all(AppSizes.md),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Créneau de retrait",
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${order.pickupDay} • ${order.pickupTimeRange}",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: textColor,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSizes.spaceBtwItems),

            // Order Items
            TRoundedContainer(
              backgroundColor: cardColor,
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Produits commandés",
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final item = order.items[index];
                      // Déterminer si l'image est valide (URL réseau ou asset)
                      final hasValidImage = item.image != null &&
                          item.image!.isNotEmpty &&
                          (item.image!.startsWith('http://') ||
                              item.image!.startsWith('https://') ||
                              item.image!.startsWith('assets/'));

                      return Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: hasValidImage
                                ? item.image!.startsWith('http://') ||
                                        item.image!.startsWith('https://')
                                    ? Image.network(
                                        item.image!,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return _buildPlaceholderImage();
                                        },
                                      )
                                    : Image.asset(
                                        item.image!,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return _buildPlaceholderImage();
                                        },
                                      )
                                : _buildPlaceholderImage(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title,
                                    style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.w600)),
                                if (item.selectedVariation != null)
                                  Text(
                                    item.selectedVariation!.entries
                                        .map((e) => "${e.key}: ${e.value}")
                                        .join(", "),
                                    style: TextStyle(
                                        color: textColor.withOpacity(0.7),
                                        fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                              "${item.quantity} x ${item.price.toStringAsFixed(2)} DT",
                              style: TextStyle(color: textColor)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.spaceBtwItems),

            // Delivery Map Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Vérifier que l'établissement est disponible avant de naviguer
                  if (order.etablissement == null &&
                      order.etablissementId.isEmpty) {
                    Get.snackbar(
                      'Erreur',
                      'Les données de livraison ne sont pas disponibles',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }
                  Get.to(() => DeliveryMapView(order: order));
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text("Afficher l’itinéraire"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for info columns
  Widget _infoColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: color)),
      ],
    );
  }

  // Widget pour l'image placeholder quand l'image est absente
  Widget _buildPlaceholderImage() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.shopping_bag,
        color: Colors.grey[600],
        size: 24,
      ),
    );
  }
}
