import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/popups/loaders.dart';
import '../../../controllers/product/panier_controller.dart';

class DeleteAllBottomSheet extends StatelessWidget {
  const DeleteAllBottomSheet({
    super.key,
    required this.controller,
  });

  final CartController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(AppSizes.defaultSpace),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.trash,
            size: 60,
            color: Colors.red.shade600,
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),
          Text(
            'Vider le panier',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),
          Text(
            'Êtes-vous sûr de vouloir supprimer tous les articles du panier ?',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spaceBtwSections),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Annuler',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spaceBtwItems),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    controller.viderPanier();
                    Get.back();
                    TLoaders.customToast(message: 'Panier vidé');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Supprimer',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}