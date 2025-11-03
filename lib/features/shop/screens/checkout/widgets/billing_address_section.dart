import 'package:caferesto/common/widgets/texts/section_heading.dart';
import 'package:caferesto/features/personalization/controllers/address_controller.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TBillingAddressSection extends StatelessWidget {
  const TBillingAddressSection({super.key});

  @override
  Widget build(BuildContext context) {
    final addressController = AddressController.instance;

    return Obx(() {
      final selected = addressController.selectedAddress.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TSectionHeading(
            padding: EdgeInsets.all(0),
            showActionButton: true,
            title: 'Adresse de livraison',
            buttonTitle: selected.id.isNotEmpty ? 'Changer' : 'Ajouter',
            onPressed: () => addressController.selectNewAddressPopup(context),
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),

          /// Si une adresse est sélectionnée
          if (selected.id.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Nom
                Text(
                  selected.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSizes.spaceBtwItems / 2),

                /// Téléphone
                Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.grey, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      selected.phoneNumber,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.spaceBtwItems / 2),

                /// Adresse complète
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${selected.street}, ${selected.city}, ${selected.country}",
                        style: Theme.of(context).textTheme.bodyMedium,
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else

            /// Si aucune adresse sélectionnée
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_off,
                      color: Colors.orange.shade600, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Aucune adresse sélectionnée. Appuyez sur 'Ajouter' pour choisir une adresse.",
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}
