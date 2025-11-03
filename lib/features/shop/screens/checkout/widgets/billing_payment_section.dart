import 'package:caferesto/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/products/product_cards/widgets/rounded_container.dart';
import '../../../../../common/widgets/texts/section_heading.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../../../utils/helpers/helper_functions.dart';
import '../../../controllers/product/checkout_controller.dart';

class TBillingPaymentSection extends StatelessWidget {
  const TBillingPaymentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CheckoutController.instance;

    final dark = THelperFunctions.isDarkMode(context);

    return Column(
      children: [
        TSectionHeading(
          title: 'Méthode de payement',
          buttonTitle: 'Changer',
          onPressed: () => controller.selectPaymentMethod(context),
        ),
        const SizedBox(
          height: AppSizes.spaceBtwItems / 2,
        ),
        Obx(
          () => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TRoundedContainer(
                  width: 60,
                  height: 35,
                  backgroundColor: dark ? AppColors.light : AppColors.white,
                  padding: const EdgeInsets.all(AppSizes.sm),
                  child: Image(
                      image: AssetImage(
                          controller.selectedPaymentMethod.value.image),
                      fit: BoxFit.contain)),
              const SizedBox(width: AppSizes.spaceBtwItems / 2),
              Text(controller.selectedPaymentMethod.value.name,
                  style: Theme.of(context).textTheme.bodyLarge)
            ],
          ),
        ),
        const SizedBox(
          height: AppSizes.spaceBtwItems / 2,
        ),
      ],
    );
  }
}
