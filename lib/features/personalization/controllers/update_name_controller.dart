import 'package:caferesto/data/repositories/user/user_repository.dart';
import 'package:caferesto/utils/constants/image_strings.dart';
import 'package:caferesto/utils/helpers/network_manager.dart';
import 'package:caferesto/utils/popups/full_screen_loader.dart';
import 'package:caferesto/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'user_controller.dart';

class UpdateNameController extends GetxController {
  static UpdateNameController get instance => Get.find();

  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final username = TextEditingController();
  final phone = TextEditingController();
  final birthDate = TextEditingController();
  final userController = UserController.instance;
  final userRepository = Get.put(UserRepository());

  GlobalKey<FormState> updateUserNameFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    initializeNames();
    super.onInit();
  }

  Future<void> initializeNames() async {
    firstName.text = userController.user.value.firstName;
    lastName.text = userController.user.value.lastName;
    username.text = userController.user.value.username;
    phone.text = userController.user.value.phone;
    birthDate.text = userController.user.value.dateOfBirth != null
        ? "${userController.user.value.dateOfBirth!.day.toString().padLeft(2, '0')}/"
            "${userController.user.value.dateOfBirth!.month.toString().padLeft(2, '0')}/"
            "${userController.user.value.dateOfBirth!.year}"
        : "";
  }

  Future<void> updateUserName() async {
    try {
      TFullScreenLoader.openLoadingDialog(
          "Nous sommes en train de mettre à jour vos informations...",
          TImages.docerAnimation);

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TFullScreenLoader.stopLoading();
        return;
      }

      if (!updateUserNameFormKey.currentState!.validate()) {
        TFullScreenLoader.stopLoading();
        return;
      }

      Map<String, dynamic> name = {
        "first_name": firstName.text.trim(),
        "last_name": lastName.text.trim(),
        "username": username.text.trim(),
        "phone": phone.text.trim(),
        "date_of_birth": birthDate.text.trim(),
      };
      await userRepository.updateSingleField(name);

      userController.user.value.firstName = firstName.text.trim();
      userController.user.value.lastName = lastName.text.trim();
      userController.user.value.username = username.text.trim();
      userController.user.value.phone = phone.text.trim();
      // Mettre à jour la date de naissance
      userController.user.value.dateOfBirth = birthDate.text.isNotEmpty
          ? DateTime.parse(
              "${birthDate.text.split("/")[2]}-${birthDate.text.split("/")[1]}-${birthDate.text.split("/")[0]}")
          : null;

      userController.user.refresh();
      TFullScreenLoader.stopLoading();

      if (Get.context != null) {
        TLoaders.successSnackBar(
            message: "Vos informations ont été mis à jour avec succès");
      }

      Get.back(result: true);
    } catch (e) {
      TFullScreenLoader.stopLoading();
      TLoaders.errorSnackBar(title: "Erreur !", message: e.toString());
    }
  }
}
