// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'features/shop/controllers/navigation_controller.dart';
import 'utils/helpers/helper_functions.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());
    final darkMode = THelperFunctions.isDarkMode(context);

    // Google Play Store colors
    const Color playStoreUnselected = Color(0xFF5F6368); // Google gray
    const Color playStoreBackground = Color(0xFFFFFFFF); // Pure white
    const Color darkModeBackground = Color(0xFF202124); // Google dark gray

    return Scaffold(
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
      bottomNavigationBar: Obx(
        () => Container(
          decoration: BoxDecoration(
              color: darkMode ? darkModeBackground : playStoreBackground,
              border: Border(
                  top: BorderSide(
                color: Colors.grey.shade300.withOpacity(0.5),
                width: 0.5,
              ))),
          child: NavigationBar(
            height: 70,
            elevation: 0,
            selectedIndex: controller.selectedIndex.value,
            onDestinationSelected: (index) =>
                controller.selectedIndex.value = index,
            backgroundColor:
                darkMode ? darkModeBackground : playStoreBackground,
            indicatorColor: Colors.blue.withOpacity(0.5),
            surfaceTintColor: Colors.transparent,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(Iconsax.home, color: playStoreUnselected),
                selectedIcon: Icon(Iconsax.home5, color: Colors.blue[100]),
                label: 'Accueil',
              ),
              NavigationDestination(
                icon: Icon(Iconsax.shop, color: playStoreUnselected),
                selectedIcon: Icon(Iconsax.shop5, color: Colors.blue[100]),
                label: 'Store',
              ),
              NavigationDestination(
                icon: Icon(Iconsax.heart, color: playStoreUnselected),
                selectedIcon: Icon(Iconsax.heart5, color: Colors.blue[300]),
                label: 'Favoris',
              ),
              NavigationDestination(
                icon: Icon(Iconsax.profile_circle, color: playStoreUnselected),
                selectedIcon:
                    Icon(Iconsax.profile_circle5, color: Colors.blue[300]),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
