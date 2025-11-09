import 'package:caferesto/features/authentication/controllers/signup/signup_controller.dart';
import 'package:caferesto/features/personalization/controllers/address_controller.dart';
import 'package:caferesto/features/shop/controllers/product/order_controller.dart';
import 'package:get/get.dart';

import '../data/repositories/address/address_repository.dart';
import '../data/repositories/etablissement/etablissement_repository.dart';
import '../data/repositories/order/order_repository.dart';
import '../data/repositories/product/produit_repository.dart';
import '../data/repositories/user/user_repository.dart';
import '../features/authentication/controllers/signup/verify_otp_controller.dart';
import '../features/personalization/controllers/user_controller.dart';
import '../features/personalization/controllers/user_management_controller.dart';
import '../features/shop/controllers/etablissement_controller.dart';
import '../features/shop/controllers/product/checkout_controller.dart';
import '../features/shop/controllers/product/favorites_controller.dart';
import '../features/shop/controllers/product/share_controller.dart';
import '../features/shop/controllers/product/variation_controller.dart';
import '../features/shop/controllers/product/panier_controller.dart';
import '../utils/helpers/network_manager.dart';

class GeneralBinding extends Bindings {
  @override
  void dependencies() {
    // Repositories d'abord
    Get.lazyPut<ProduitRepository>(() => ProduitRepository(), fenix: true);
    Get.lazyPut<UserRepository>(() => UserRepository(), fenix: true);
    Get.lazyPut<EtablissementRepository>(() => EtablissementRepository(), fenix: true);
    Get.lazyPut<OrderRepository>(() => OrderRepository(), fenix: true);
    Get.lazyPut<AddressRepository>(() => AddressRepository(), fenix: true);

    // UserController doit être créé avant OrderController car OrderController en dépend
    Get.lazyPut<UserController>(() => UserController(), fenix: true);
    Get.lazyPut<NetworkManager>(() => NetworkManager(), fenix: true);

    // Controllers d'authentification
    Get.lazyPut(() => SignupController());
    Get.lazyPut(() => OTPVerificationController());

    // Controllers qui dépendent de UserController
    Get.lazyPut<AddressController>(() => AddressController(), fenix: true);
    Get.lazyPut<CartController>(() => CartController(), fenix: true);
    Get.lazyPut<CheckoutController>(() => CheckoutController(), fenix: true);
    Get.lazyPut(() => OrderController());
    Get.lazyPut<FavoritesController>(() => FavoritesController(), fenix: true);
    Get.lazyPut<ShareController>(() => ShareController(), fenix: true);
    Get.lazyPut<VariationController>(() => VariationController(), fenix: true);
    Get.lazyPut<UserManagementController>(() => UserManagementController(), fenix: true);
    Get.lazyPut<EtablissementController>(
        () => EtablissementController(Get.find<EtablissementRepository>()),
        fenix: true);
  }
}
