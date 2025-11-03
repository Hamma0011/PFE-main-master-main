import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../controllers/product/panier_controller.dart';

class CartHeader extends StatelessWidget {
  const CartHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;
    return Padding(
      padding: const EdgeInsets.all(AppSizes.defaultSpace),
      child: Row(
        children: [
          Text(
            'Votre sélection',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          Obx(() => Text(
                '${controller.cartItemsCount.value} ${controller.cartItemsCount.value > 1 ? 'articles' : 'article'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              )),
        ],
      ),
    );
  }
}
