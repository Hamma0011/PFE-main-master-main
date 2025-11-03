import 'package:caferesto/common/widgets/appbar/appbar.dart';
import 'package:caferesto/features/personalization/controllers/address_controller.dart';
import 'package:caferesto/features/personalization/screens/address/widgets/single_address.dart';
import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../utils/helpers/cloud_helper_functions.dart';
import 'add_new_address.dart';

class UserAddressScreen extends StatelessWidget {
  const UserAddressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddressController());
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Get.to(() => const AddNewAddressScreen()),
        child: const Icon(
          Iconsax.add,
          color: AppColors.white,
        ),
      ),
      appBar: TAppBar(
        title: Text(
          "Adresses",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          child: Obx(
            () => FutureBuilder(
                // Use key to trigger refresh
                key: Key(controller.refreshData.value.toString()),
                future: controller.getAllUserAddresses(),
                builder: (context, snapshot) {
                  /// Handle loader , No record, Or Error Message
                  final widget = TCloudHelperFunctions.checkMultiRecordState(
                    snapshot: snapshot,
                  );
                  if (widget != null) return widget;

                  /// Records found
                  final addresses = snapshot.data!;
                  return ListView.builder(
                      shrinkWrap: true,
                      itemCount: addresses.length,
                      itemBuilder: (_, index) {
                        return TSingleAddress(
                          address: addresses[index],
                          onTap: () =>
                              controller.selectAddress(addresses[index]),
                        );
                      });
                }),
          ),
        ),
      ),
    );
  }
}
