import 'package:caferesto/common/widgets/appbar/appbar.dart';
import 'package:caferesto/features/personalization/controllers/address_controller.dart';
import 'package:caferesto/features/personalization/controllers/user_controller.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../utils/validators/validation.dart';

import 'package:get/get.dart';

class AddNewAddressScreen extends StatelessWidget {
  const AddNewAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AddressController.instance;
    final userController = UserController.instance;
    final dark = THelperFunctions.isDarkMode(context);
    // Prefill user info once
    controller.name.text = userController.user.value.fullName ?? '';
    controller.phoneNumber.text = userController.user.value.phone ?? '';

    return Scaffold(
      appBar: const TAppBar(title: Text("Ajouter une adresse")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.defaultSpace),
        child: Form(
          key: controller.addressFormKey,
          child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// --- Toggle Map / Manual Entry
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Sélectionner sur la carte",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Switch(
                        value: controller.useMap.value,
                        onChanged: (v) => controller.useMap.value = v,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  /// --- MAP MODE ---
                  if (controller.useMap.value) ...[
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: controller.mapController,
                            options: MapOptions(
                              initialCenter: controller.selectedLocation.value ??
                                  LatLng(36.8065, 10.1815),
                              initialZoom : 12,
                              onTap: (tapPosition, latLng) =>
                                  controller.setMapAddress(latLng),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'caferesto.app',
                                tileProvider: CancellableNetworkTileProvider(),
                              ),
                              if (controller.selectedLocation.value != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: controller.selectedLocation.value!,
                                      width: 40,
                                      height: 40,
                                      child : const Icon(
                                        Icons.location_pin,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.my_location),
                              label: const Text("Ma position"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              onPressed: () async {
                                try {
                                  // Get device location
                                  LocationPermission permission =
                                      await Geolocator.checkPermission();
                                  if (permission == LocationPermission.denied) {
                                    permission =
                                        await Geolocator.requestPermission();
                                  }
                                  if (permission ==
                                          LocationPermission.deniedForever ||
                                      permission == LocationPermission.denied) {
                                    throw 'Permissions de localisation refusées';
                                  }

                                  Position position =
                                      await Geolocator.getCurrentPosition(
                                          desiredAccuracy:
                                              LocationAccuracy.high);

                                  final currentLatLng = LatLng(
                                      position.latitude, position.longitude);

                                  // Update controller
                                  controller.setMapAddress(currentLatLng);

                                  // Move map to location
                                  controller.mapController
                                      ?.move(currentLatLng, 15);
                                } catch (e) {
                                  print('Erreur localisation: $e');
                                  Get.snackbar('Erreur',
                                      'Impossible d\'obtenir la localisation',
                                      snackPosition: SnackPosition.BOTTOM);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (controller.selectedLocation.value != null)
                      Text(
                        "Position sélectionnée: ${controller.selectedLocation.value!.latitude.toStringAsFixed(5)}, ${controller.selectedLocation.value!.longitude.toStringAsFixed(5)}",
                        style: TextStyle(
                            fontSize: 13,
                            color: dark ? Colors.white : Colors.black87),
                      ),
                    if (controller.isLoadingAddress.value)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    const SizedBox(height: AppSizes.spaceBtwInputFields),
                  ],

                  /// --- MANUAL FIELDS (ALSO FILLED AUTOMATICALLY BY MAP) ---
                  TextFormField(
                    controller: controller.street,
                    validator: (value) =>
                        TValidator.validateEmptyText("Rue", value),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Iconsax.building_31),
                        labelText: 'Rue'),
                  ),
                  const SizedBox(height: AppSizes.spaceBtwInputFields),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller.postalCode,
                          validator: (value) => TValidator.validateEmptyText(
                              'Code Postal', value),
                          decoration: const InputDecoration(
                              prefixIcon: Icon(Iconsax.activity),
                              labelText: 'Code Postal'),
                        ),
                      ),
                      const SizedBox(width: AppSizes.spaceBtwInputFields),
                      Expanded(
                        child: TextFormField(
                          controller: controller.city,
                          validator: (value) =>
                              TValidator.validateEmptyText('Cité', value),
                          decoration: const InputDecoration(
                              prefixIcon: Icon(Iconsax.building),
                              labelText: 'Cité'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spaceBtwInputFields),
                  TextFormField(
                    controller: controller.state,
                    validator: (value) =>
                        TValidator.validateEmptyText('Gouvernorat', value),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Iconsax.activity),
                        labelText: 'Gouvernorat'),
                  ),
                  const SizedBox(height: AppSizes.spaceBtwInputFields),
                  TextFormField(
                    controller: controller.country,
                    validator: (value) =>
                        TValidator.validateEmptyText('Pays', value),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Iconsax.global), labelText: 'Pays'),
                  ),
                  const SizedBox(height: AppSizes.spaceBtwInputFields),

                  /// --- USER INFO (AUTO-FILLED) ---
                  TextFormField(
                    controller: controller.name,
                    validator: (value) =>
                        TValidator.validateEmptyText("Nom", value),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Iconsax.user), labelText: 'Nom'),
                  ),
                  const SizedBox(height: AppSizes.spaceBtwInputFields),
                  TextFormField(
                    controller: controller.phoneNumber,
                    validator: (value) => TValidator.validatePhoneNumber(value),
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Iconsax.mobile),
                        labelText: 'Numéro de téléphone'),
                  ),

                  const SizedBox(height: AppSizes.defaultSpace),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.addNewAddress,
                      child: const Text('Enregistrer'),
                    ),
                  ),
                ],
              )),
        ),
      ),
    );
  }
}
