import 'package:caferesto/features/shop/models/produit_model.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/device/device_utility.dart';
import 'package:flutter/material.dart';
import 'product_main_action_button.dart';
import 'product_price_display.dart';
import 'product_quantity_controls.dart';

class ProductBottomBar extends StatelessWidget {
  const ProductBottomBar({
    super.key,
    required this.product,
    required this.dark,
    required this.isSmallScreen,
    required this.onIncrement,
    required this.onDecrement,
    required this.onMainAction,
  });

  final ProduitModel product;
  final bool dark;
  final bool isSmallScreen;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback onMainAction;

  @override
  Widget build(BuildContext context) {
    final isDesktop = TDeviceUtils.isDesktop(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : AppSizes.defaultSpace,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkerGrey : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: isDesktop
            ? BorderRadius.circular(20)
            : const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
      ),
      child: isDesktop
          ? _buildDesktopBottomBar(dark)
          : _buildMobileBottomBar(dark, isSmallScreen),
    );
  }

  Widget _buildDesktopBottomBar(bool dark) {
    return Row(
      children: [
        /// Price Display
        Flexible(
          child: ProductPriceDisplay(product: product, dark: dark),
        ),

        const SizedBox(width: 12),

        /// Quantity Controls
        ProductQuantityControls(
          product: product,
          dark: dark,
          onDecrement: onDecrement,
          onIncrement: onIncrement,
        ),

        const SizedBox(width: 20),

        /// Add to Cart Button
        Expanded(
          flex: 2,
          child: ProductMainActionButton(
            product: product,
            isSmallScreen: false,
            onTap: onMainAction,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileBottomBar(bool dark, bool isSmallScreen) {
    if (isSmallScreen) {
      // Very small screens - vertical or compact layout
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // First row: Price and Quantity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: ProductPriceDisplay(product: product, dark: dark),
              ),
              ProductQuantityControls(
                product: product,
                dark: dark,
                onDecrement: onDecrement,
                onIncrement: onIncrement,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Second row: Add to Cart button (full width)
          SizedBox(
            width: double.infinity,
            child: ProductMainActionButton(
              product: product,
              isSmallScreen: isSmallScreen,
              onTap: onMainAction,
            ),
          ),
        ],
      );
    } else {
      // Normal mobile screens - horizontal layout
      return Row(
        children: [
          /// Price Display
          Flexible(
            flex: 1,
            child: ProductPriceDisplay(product: product, dark: dark),
          ),

          const SizedBox(width: 8),

          /// Quantity Controls
          ProductQuantityControls(
            product: product,
            dark: dark,
            onDecrement: onDecrement,
            onIncrement: onIncrement,
          ),

          const SizedBox(width: 8),

          /// Add to Cart Button
          Expanded(
            flex: 2,
            child: ProductMainActionButton(
              product: product,
              isSmallScreen: isSmallScreen,
              onTap: onMainAction,
            ),
          ),
        ],
      );
    }
  }
}

