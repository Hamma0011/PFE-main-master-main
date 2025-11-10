import 'dart:convert';

import 'package:caferesto/common/widgets/texts/section_heading.dart';
import 'package:caferesto/features/personalization/screens/address/widgets/single_address.dart';
import 'package:caferesto/utils/helpers/cloud_helper_functions.dart';
import 'package:caferesto/utils/loaders/circular_loader.dart';
import 'package:caferesto/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../data/repositories/address/address_repository.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../models/address_model.dart';
import '../screens/address/add_new_address.dart';

import 'user_controller.dart';

class AddressController extends GetxController {
  static AddressController get instance {
    try {
      return Get.find<AddressController>();
    } catch (e) {
      // If not found, create it (shouldn't happen with proper binding)
      return Get.put(AddressController(), permanent: true);
    }
  }

  // Form controllers
  final name = TextEditingController();
  final phoneNumber = TextEditingController();
  final street = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final postalCode = TextEditingController();
  final country = TextEditingController();

  final addressFormKey = GlobalKey<FormState>();

  // Reactive state
  final refreshData = true.obs;
  final selectedAddress = AddressModel.empty().obs;
  final useMap = true.obs;
  final selectedLocation = Rxn<LatLng>();
  final isLoadingAddress = false.obs;

  final MapController mapController = MapController();

  final addressRepository = Get.put(AddressRepository());

  @override
  void onInit() {
    super.onInit();
    // Prefill name & phone from UserController
    final user = UserController.instance.user.value;
    name.text = user.fullName;
    phoneNumber.text = user.phone;
    getAllUserAddresses(); // ⚡️ charge la sélection existante
  }

  /// ───────────────────────────────────────────────
  /// FETCH ALL USER ADDRESSES
  Future<List<AddressModel>> getAllUserAddresses() async {
    try {
      final addresses = await addressRepository.fetchUserAddresses();

      selectedAddress.value = addresses.firstWhere(
        (element) => element.selectedAddress,
        orElse: () => AddressModel.empty(),
      );

      return addresses;
    } catch (e) {
      TLoaders.errorSnackBar(
          title: "Adresse non trouvée", message: e.toString());
      return [];
    }
  }

  /// ───────────────────────────────────────────────
  /// SELECT ADDRESS
  Future selectAddress(AddressModel newSelectedAddress) async {
    try {
      Get.defaultDialog(
        title: '',
        onWillPop: () async => false,
        barrierDismissible: false,
        backgroundColor: Colors.transparent,
        content: const TCircularLoader(),
      );

      // Unselect previous
      if (selectedAddress.value.id.isNotEmpty) {
        await addressRepository.updateSelectedField(
            selectedAddress.value.id, false);
      }

      // Set new one
      newSelectedAddress.selectedAddress = true;
      selectedAddress.value = newSelectedAddress;
      await addressRepository.updateSelectedField(
          selectedAddress.value.id, true);

      Get.back();
    } catch (e) {
      TLoaders.errorSnackBar(
          title: "Erreur de sélection", message: e.toString());
    }
  }

  /// ───────────────────────────────────────────────
  /// SET MAP ADDRESS (Reverse Geocoding)
  Future<void> setMapAddress(LatLng position) async {
    selectedLocation.value = position;
    isLoadingAddress.value = true;

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2'
        '&lat=${position.latitude}&lon=${position.longitude}&addressdetails=1'
        '&accept-language=fr',
      );
      final response = await http.get(url,
          headers: {'User-Agent': 'YourAppName/1.0 (your@email.com)'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] ?? {};

        street.text = address['road'] ?? '';
        city.text =
            address['city'] ?? address['town'] ?? address['village'] ?? '';
        state.text = address['state'] ?? '';
        postalCode.text = address['postcode'] ?? '';
        country.text = address['country'] ?? '';
      } else {
        throw Exception('Échec du géocodage inverse');
      }
    } catch (e) {
      TLoaders.errorSnackBar(
          title: 'Erreur', message: 'Impossible de récupérer l’adresse');
    } finally {
      isLoadingAddress.value = false;
    }
  }

  /// ───────────────────────────────────────────────
  /// ADD NEW ADDRESS
  Future<void> addNewAddress() async {
    try {
      TFullScreenLoader.openLoadingDialog(
          'Enregistrement en cours...', TImages.docerAnimation);

      // Check internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Validate form
      if (!addressFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Build new address model
      final address = AddressModel(
        id: '',
        name: name.text.trim(),
        phoneNumber: phoneNumber.text.trim(),
        street: street.text.trim(),
        city: city.text.trim(),
        state: state.text.trim(),
        postalCode: postalCode.text.trim(),
        country: country.text.trim(),
        latitude: selectedLocation.value?.latitude,
        longitude: selectedLocation.value?.longitude,
        selectedAddress: true,
      );

      // Save to DB
      final id = await addressRepository.addAddress(address);
      address.id = id;

      // Set it as selected
      await selectAddress(address);

      TFullScreenLoader.stopLoading();
      TLoaders.successSnackBar(
          title: 'Adresse ajoutée',
          message: 'Votre adresse a bien été ajoutée.');

      refreshData.toggle();
      resetFormFields();
      Navigator.of(Get.context!).pop();
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(
          title: 'Erreur', message: 'Addresse non ajoutée : $e');
    }
  }

  /// ───────────────────────────────────────────────
  /// ADDRESS SELECTION POPUP
  Future<dynamic> selectNewAddressPopup(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      builder: (modalContext) => Obx(
        () => SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TSectionHeading(
                  title: 'Sélectionner une adresse',
                  showActionButton: false,
                ),
                FutureBuilder(
                  key: Key(refreshData.value.toString()), // Force refresh when refreshData changes
                  future: getAllUserAddresses(),
                  builder: (_, snapshot) {
                    final response = TCloudHelperFunctions.checkMultiRecordState(
                        snapshot: snapshot);
                    if (response != null) return response;

                    final addresses = snapshot.data!;
                    if (addresses.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(AppSizes.defaultSpace),
                        child: Center(
                          child: Text(
                            'Aucune adresse enregistrée',
                            style: Theme.of(modalContext).textTheme.bodyMedium,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: addresses.length,
                      itemBuilder: (_, index) {
                        final address = addresses[index];
                        return TSingleAddress(
                          address: address,
                          onTap: () async {
                            await selectAddress(address);
                            Get.back();
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSizes.defaultSpace * 2),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.to(() => const AddNewAddressScreen()),
                    child: const Text('Ajouter une nouvelle adresse'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ───────────────────────────────────────────────
  /// DELETE ADDRESS
  Future<void> deleteAddress(String addressId) async {
    try {
      TFullScreenLoader.openLoadingDialog(
          'Suppression en cours...', TImages.docerAnimation);

      // Check internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      // Vérifier si l'adresse à supprimer est l'adresse sélectionnée
      final isSelectedAddress = selectedAddress.value.id == addressId;

      // Supprimer l'adresse de la base de données
      await addressRepository.deleteAddress(addressId);

      // Si l'adresse supprimée était l'adresse sélectionnée, réinitialiser
      if (isSelectedAddress) {
        selectedAddress.value = AddressModel.empty();
      }

      TFullScreenLoader.stopLoading();
      TLoaders.successSnackBar(
          title: 'Adresse supprimée',
          message: 'Votre adresse a bien été supprimée.');

      // Rafraîchir la liste des adresses
      refreshData.toggle();
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(
          title: 'Erreur', message: 'Impossible de supprimer l\'adresse : $e');
    }
  }

  /// ───────────────────────────────────────────────
  /// RESET FORM
  void resetFormFields() {
    name.clear();
    phoneNumber.clear();
    street.clear();
    city.clear();
    state.clear();
    postalCode.clear();
    country.clear();
    selectedLocation.value = null;
    addressFormKey.currentState?.reset();
  }
}
