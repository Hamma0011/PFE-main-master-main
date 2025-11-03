import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../utils/popups/loaders.dart';
import '../../models/produit_model.dart';

class ShareController extends GetxController {
  static ShareController get instance => Get.find();

  Future<void> shareProduct(ProduitModel product) async {
    try {
      final String text = 'Découvrez ${product.name} - ${product.price} DH';
      final String subject = 'Produit recommandé: ${product.name}';

      await Share.share(
        text,
        subject: subject,
        sharePositionOrigin: Rect.fromLTWH(0, 0, 100, 100),
      );
    } catch (e) {
      TLoaders.errorSnackBar(
          title: 'Erreur', message: 'Impossible de partager le produit');
    }
  }
}
