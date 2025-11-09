import 'package:get/get.dart';

class CheckoutController extends GetxController {
  static CheckoutController get instance {
    try {
      return Get.find<CheckoutController>();
    } catch (e) {
      // If not found, create it (shouldn't happen with proper binding)
      return Get.put(CheckoutController(), permanent: true);
    }
  }

  // Méthode de paiement par défaut (simple String)
  String get paymentMethod => 'Paiement à la caisse';
}
