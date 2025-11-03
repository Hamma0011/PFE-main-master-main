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
                  Positioned(
                    right: 5,
                    top: 0,
                    child: Icon(selectedAddress ? Iconsax.tick_circle5 : null,
                        color: selectedAddress
                            ? dark
                                ? AppColors.light
                                : AppColors.dark.withAlpha((255 * 0.6).toInt())
                            : null),
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
