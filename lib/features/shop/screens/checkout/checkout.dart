import 'package:caferesto/features/shop/screens/cart/widgets/cart_items.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:caferesto/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/products/product_cards/widgets/rounded_container.dart';
import '../../../../utils/helpers/pricing_calculator.dart';
import '../../../personalization/controllers/address_controller.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../controllers/product/panier_controller.dart';
import '../../controllers/product/order_controller.dart';
import '../../models/produit_model.dart';
import 'widgets/billing_address_section.dart';
import 'widgets/billing_amount_section.dart';
import 'widgets/time_slot_modal.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();
    // S'assurer que UserController est initialisé
    try {
      Get.find<UserController>();
    } catch (e) {
      Get.put(UserController(), permanent: true);
    }
    final subTotal = cartController.totalCartPrice.value;
    // Use instance getter which handles creation if needed
    final orderController = OrderController.instance;
    final totalAmount = TPricingCalculator.calculateTotalPrice(subTotal, 'tn');
    final dark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      appBar: TAppBar(
          title: Text('Résumé de la Commande',
              style: Theme.of(context).textTheme.headlineSmall)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            children: [
              /// Items in cart (checkout mode - no buttons, bill-like format)
              TCartItems(isCheckout: true),
              SizedBox(
                height: AppSizes.spaceBtwSections,
              ),

              /// --Coupon TextField
              // TCouponCode(dark: dark),
              // const SizedBox(height: AppSizes.spaceBtwSections),

              /// --Billing section
              TRoundedContainer(
                showBorder: true,
                padding: const EdgeInsets.all(AppSizes.md),
                backgroundColor: dark ? AppColors.black : AppColors.white,
                child: Column(
                  children: [
                    /// Pricing
                    TBillingAmountSection(),
                    const SizedBox(height: AppSizes.spaceBtwItems),

                    /// Divider
                    const Divider(),
                    const SizedBox(height: AppSizes.spaceBtwItems),

                    /// Address
                    TBillingAddressSection(),
                    const SizedBox(height: AppSizes.spaceBtwItems),
                    const Divider(),

                    /// Section créneau horaire
                    _buildTimeSlotSection(orderController),
                  ],
                ),
              )
            ],
          ),
        ),
      ),

      /// Checkout button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(AppSizes.defaultSpace),
        child: ElevatedButton(
            onPressed: subTotal > 0
                ? () => _processOrder(orderController, totalAmount, context)
                : () => TLoaders.warningSnackBar(
                    title: 'Panier vide',
                    message:
                        'Veuillez ajouter des produits au panier pour proceder au paiement'),
            child: const Text('Commander')),
      ),
    );
  }

  // Section créneau horaire
  Widget _buildTimeSlotSection(OrderController orderController) {
    return Obx(() {
      // Safety check: ensure controller is initialized
      if (!Get.isRegistered<OrderController>()) {
        return const SizedBox.shrink();
      }
      final hasTimeSlot = orderController.selectedSlot.value != null &&
          orderController.selectedDay.value != null;

      if (!hasTimeSlot) {
        return _buildNoTimeSlotWidget(orderController);
      }

      return _buildSelectedTimeSlotWidget(orderController);
    });
  }

  // WIDGET : Aucun créneau sélectionné
  Widget _buildNoTimeSlotWidget(OrderController orderController) {
    final dark = THelperFunctions.isDarkMode(Get.context!);
    final cartController = Get.find<CartController>();
    final firstItem = cartController.cartItems.isNotEmpty
        ? cartController.cartItems.first
        : null;

    if (firstItem == null) {
      // No items in cart - show the existing empty state but keep the button harmless
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Créneau de retrait",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              TextButton(
                onPressed: () => TLoaders.warningSnackBar(
                  title: 'Erreur',
                  message: 'Impossible de trouver le produit du panier.',
                ),
                child: const Text(
                  "Choisir un créneau",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time,
                    color: Colors.orange.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Aucun créneau sélectionné",
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final product = firstItem.product ??
        ProduitModel.empty().copyWith(
          id: firstItem.productId,
          name: firstItem.title,
          imageUrl: firstItem.image ?? '',
          etablissementId: firstItem.etablissementId,
        );

    // Vérifier que l'établissement est défini
    if (product.etablissementId.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Créneau de retrait",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              TextButton(
                onPressed: () => TLoaders.warningSnackBar(
                  title: 'Erreur',
                  message:
                      'L\'établissement n\'est pas défini pour ce produit.',
                ),
                child: const Text(
                  "Choisir un créneau",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Erreur: établissement non défini",
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Créneau de retrait",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            TextButton(
              onPressed: () async {
                // product is guaranteed to be non-null here (we created a fallback)
                await TimeSlotModal()
                    .openTimeSlotModal(Get.context!, dark, product);
              },
              child: const Text(
                "Choisir un créneau",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, color: Colors.orange.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Aucun créneau sélectionné",
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // WIDGET : Créneau sélectionné
  Widget _buildSelectedTimeSlotWidget(OrderController orderController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Créneau de retrait choisi",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            TextButton(
              onPressed: () async {
                final dark = THelperFunctions.isDarkMode(Get.context!);
                final cartController = Get.find<CartController>();
                final firstItem = cartController.cartItems.isNotEmpty
                    ? cartController.cartItems.first
                    : null;
                if (firstItem == null) {
                  TLoaders.warningSnackBar(
                    title: 'Erreur',
                    message: 'Impossible de trouver le produit du panier.',
                  );
                  return;
                }

                final product = firstItem.product ??
                    ProduitModel.empty().copyWith(
                      id: firstItem.productId,
                      name: firstItem.title,
                      imageUrl: firstItem.image ?? '',
                      etablissementId: firstItem.etablissementId,
                    );

                // Vérifier que l'établissement est défini
                if (product.etablissementId.isEmpty) {
                  TLoaders.warningSnackBar(
                    title: 'Erreur',
                    message:
                        'L\'établissement n\'est pas défini pour ce produit.',
                  );
                  return;
                }

                await TimeSlotModal()
                    .openTimeSlotModal(Get.context!, dark, product);
              },
              child: const Text(
                "Modifier",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orderController.selectedDay.value!,
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      orderController.selectedSlot.value!,
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.access_time_filled, color: Colors.green.shade600),
            ],
          ),
        ),
      ],
    );
  }

  void _processOrder(
    OrderController orderController,
    double totalAmount,
    BuildContext context,
  ) async {
    final cartController = CartController.instance;
    final addressController = Get.find<AddressController>();

    // Vérifier panier
    if (cartController.cartItems.isEmpty) {
      TLoaders.warningSnackBar(
        title: 'Panier vide',
        message: 'Veuillez ajouter des produits au panier',
      );
      return;
    }

    // Calcul etablissementId + date/heure
    final etablissementId = cartController.cartItems.first.etablissementId;

    // Vérifier créneau - si aucun n'est sélectionné, calculer un créneau par défaut
    bool creneauAutoDefini = false;
    if (orderController.selectedSlot.value == null ||
        orderController.selectedDay.value == null) {
      // Calculer le temps de préparation de la commande
      final preparationTime = cartController.calculerTempsPreparation();

      // Calculer et définir un créneau par défaut (1h + 15 min + temps de préparation)
      final creneauValide = await orderController.calculerCreneauParDefaut(
        preparationTime,
        etablissementId,
      );

      if (!creneauValide) {
        // L'établissement est fermé au créneau calculé
        TLoaders.errorSnackBar(
          title: 'Établissement fermé',
          message:
              'L\'établissement est fermé au créneau proposé. Veuillez choisir un créneau de retrait manuellement.',
        );
        return;
      }

      // Marquer que le créneau a été défini automatiquement
      creneauAutoDefini = true;

      // Le créneau sera affiché dans l'interface des produits commandés
      // Plus besoin de snackbar
    }

    // Récupérer l'adresse seulement si elle existe (optionnelle)
    final selectedAddressId = addressController.selectedAddress.value.id.isNotEmpty
        ? addressController.selectedAddress.value.id
        : null;

    // Calculate pickupDateTime based on selected day
    final now = DateTime.now();
    final selectedDayName = orderController.selectedDay.value!;

    // Convert day name to JourSemaine enum and get weekday
    final jourSemaine = THelperFunctions.stringToJourSemaine(selectedDayName);
    final targetWeekday = THelperFunctions.weekdayFromJour(jourSemaine);
    final daysToAdd = (targetWeekday - now.weekday + 7) % 7;
    // If today and it's late (after 10 PM), move to next week
    final chosenDate = daysToAdd == 0 && now.hour >= 22
        ? now.add(const Duration(days: 7))
        : now.add(Duration(days: daysToAdd));

    final startParts = orderController.selectedSlot.value!
        .split(' - ')[0]
        .split(':')
        .map(int.parse)
        .toList();

    final pickupDateTime = DateTime(
      chosenDate.year,
      chosenDate.month,
      chosenDate.day,
      startParts[0],
      startParts[1],
    );

    // Envoi
    orderController.traiterCommande(
      totalAmount: totalAmount,
      pickupDay: orderController.selectedDay.value!,
      pickupTimeRange: orderController.selectedSlot.value!,
      pickupDateTime: pickupDateTime,
      etablissementId: etablissementId,
      addressId: selectedAddressId, // plus de ""
      creneauAutoDefini: creneauAutoDefini, // Passer l'info si le créneau a été auto-défini
    );
  }
}
