import 'package:caferesto/utils/helpers/pricing_calculator.dart';
import 'package:flutter/material.dart';

import '../../../../../utils/constants/sizes.dart';
import '../../../controllers/product/panier_controller.dart';

class TBillingAmountSection extends StatelessWidget {
  const TBillingAmountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cartController = CartController.instance;
    final subTotal = cartController.totalCartPrice.value;
    return Column(
      children: [
        /// Subtotal
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sous total',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '$subTotal DT',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(
          height: AppSizes.spaceBtwItems / 2,
        ),

        /// Shipping fee
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //   children: [
        //     Text(
        //       'Frais de livraison',
        //       style: Theme.of(context).textTheme.bodyMedium,
        //     ),
        //     Text(
        //       '${TPricingCalculator.calculateShippingCost(subTotal, 'tn')} DT',
        //       style: Theme.of(context).textTheme.bodyMedium,
        //     ),
        //   ],
        // ),

        const SizedBox(
          height: AppSizes.spaceBtwItems / 2,
        ),

        /// Tax fee
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //   children: [
        //     Text(
        //       'Taxes',
        //       style: Theme.of(context).textTheme.bodyMedium,
        //     ),
        //     Text(
        //       '${TPricingCalculator.calculateTax(subTotal, 'tn')} DT',
        //       style: Theme.of(context).textTheme.bodyMedium,
        //     ),
        //   ],
        // ),
        const SizedBox(
          height: AppSizes.spaceBtwItems / 2,
        ),

        /// Order total fee
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              '${TPricingCalculator.calculateTotalPrice(subTotal, 'tn')} DT',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }
}
