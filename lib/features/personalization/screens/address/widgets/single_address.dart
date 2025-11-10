import 'package:caferesto/features/personalization/controllers/address_controller.dart';
import 'package:caferesto/features/personalization/models/address_model.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../../common/widgets/products/product_cards/widgets/rounded_container.dart';
import '../../../../../utils/constants/colors.dart';

class TSingleAddress extends StatelessWidget {
  const TSingleAddress({super.key, required this.address, required this.onTap});

  final AddressModel address;
  final VoidCallback onTap;
  
  /// Affiche une boîte de dialogue de confirmation avant de supprimer
  Future<void> _showDeleteConfirmation(BuildContext context, String addressId) async {
    final controller = AddressController.instance;
    
    return Get.dialog(
      AlertDialog(
        title: const Text('Supprimer l\'adresse'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette adresse ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Fermer la boîte de dialogue de confirmation
              await controller.deleteAddress(addressId);
              // Le modal bottom sheet se rafraîchira automatiquement grâce à refreshData.toggle()
              // Si on est dans un écran normal, il se rafraîchira aussi
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);
    final controller = AddressController.instance;
    return Obx(() {
      final selectedAddressId = controller.selectedAddress.value.id;
      final selectedAddress = selectedAddressId == address.id;
      return InkWell(
        onTap: onTap,
        child: TRoundedContainer(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.md),
          showBorder: true,
          backgroundColor: selectedAddress
              ? AppColors.primary.withAlpha(128)
              : Colors.transparent,
          borderColor: selectedAddress
              ? Colors.transparent
              : dark
                  ? AppColors.darkerGrey
                  : AppColors.grey,
          margin: const EdgeInsets.only(bottom: AppSizes.spaceBtwItems),
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  // Icône de sélection
                  Positioned(
                    right: 40,
                    top: 0,
                    child: Icon(selectedAddress ? Iconsax.tick_circle5 : null,
                        color: selectedAddress
                            ? dark
                                ? AppColors.light
                                : AppColors.dark.withAlpha((255 * 0.6).toInt())
                            : null),
                  ),
                  // Bouton de suppression
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: Icon(
                        Iconsax.trash,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                      onPressed: () => _showDeleteConfirmation(context, address.id),
                      tooltip: 'Supprimer cette adresse',
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSizes.sm / 2),
                      Text(
                        address.phoneNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSizes.sm / 2),
                      Text(
                        address.toString(),
                        softWrap: true,
                      ),
                    ],
                  )
                ],
              )),
        ),
      );
    });
  }
}
