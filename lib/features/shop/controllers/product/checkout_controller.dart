import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';
import '../../models/payment_method_model.dart';
import '../../screens/checkout/widgets/payment_tile.dart';

class CheckoutController extends GetxController {
  static CheckoutController get instance {
    try {
      return Get.find<CheckoutController>();
    } catch (e) {
      // If not found, create it (shouldn't happen with proper binding)
      return Get.put(CheckoutController(), permanent: true);
    }
  }

  final Rx<PaymentMethodModel> selectedPaymentMethod =
      PaymentMethodModel.empty().obs;

  @override
  void onInit() {
    selectedPaymentMethod.value = PaymentMethodModel(
        name: 'Payement à la caisse', image: TImages.masterCard);
    super.onInit();
  }

  Future<void> selectPaymentMethod(BuildContext context) async {
    return showModalBottomSheet(
        context: context,
        builder: (_) => SingleChildScrollView(
            child: Container(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TSectionHeading(
                          title: 'Selectionner une methode de payement',
                          showActionButton: false),
                      SizedBox(height: AppSizes.spaceBtwSections),
                      TPaymentTile(
                          paymentMethod: PaymentMethodModel(
                              name: 'Payement à la caisse',
                              image: TImages.masterCard)),
                      const SizedBox(height: AppSizes.spaceBtwItems / 2),
                      TPaymentTile(
                          paymentMethod: PaymentMethodModel(
                              name: 'Payement à la livraison',
                              image: TImages.masterCard)),
                      const SizedBox(height: AppSizes.spaceBtwItems / 2),
                      TPaymentTile(
                          paymentMethod: PaymentMethodModel(
                              name: 'D17 ', image: TImages.masterCard)),
                      const SizedBox(height: AppSizes.spaceBtwSections),
                    ]))));
  }
}
