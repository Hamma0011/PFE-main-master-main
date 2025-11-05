import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../controllers/product/panier_controller.dart';

class CartBottomSection extends StatelessWidget {
  final VoidCallback onCheckoutPressed;
  const CartBottomSection({super.key, required this.onCheckoutPressed});

  @override
  Widget build(BuildContext context) {
    final controller = CartController.instance;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.defaultSpace,
        vertical: AppSizes.spaceBtwItems,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 380;

          if (isSmallScreen) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TotalPrice(controller: controller),
                const SizedBox(height: AppSizes.spaceBtwItems),
                _CheckoutButton(onPressed: onCheckoutPressed),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _TotalPrice(controller: controller)),
              const SizedBox(width: AppSizes.spaceBtwItems),
              Expanded(flex: 2, child: _CheckoutButton(onPressed: onCheckoutPressed)),
            ],
          );
        }),
      ),
    );
  }
}

class _TotalPrice extends StatelessWidget {
  final CartController controller;
  const _TotalPrice({required this.controller});

  String _formatPreparationTime(int minutes) {
    if (minutes == 0) {
      return 'Prêt immédiatement';
    } else if (minutes == 1) {
      return '1 minute';
    } else {
      return '$minutes minutes';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final preparationTime = controller.calculerTempsPreparation();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Total',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${controller.totalCartPrice.value.toStringAsFixed(2)} DT',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (preparationTime > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatPreparationTime(preparationTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ],
        ],
      );
    });
  }
}

class _CheckoutButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CheckoutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          'Résumé de la commande',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}
