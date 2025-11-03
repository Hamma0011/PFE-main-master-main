import 'package:get/get.dart';

import '../../personalization/screens/settings/settings.dart';
import '../screens/home/home.dart';
import '../screens/store/store.dart';
import '../screens/favorite/favorite_screen.dart';

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;

  final screens = [
    HomeScreen(),
    StoreScreen(),
    FavoriteScreen(),
    SettingsScreen(),
  ];
}
