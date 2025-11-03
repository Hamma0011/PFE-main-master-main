import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../utils/constants/sizes.dart';
import '../../models/produit_model.dart';

class ImagesController extends GetxController {
  // Singleton instance
  static ImagesController get instance => Get.find();

  // variables
  RxString selectedProductImage = ''.obs;

  /// -- Set all images from product and variations
  List<String> getAllProductImages(ProduitModel product) {
    Set<String> images = {};

    // Load thmbnail image
    if (product.imageUrl!.isNotEmpty) {
      images.add(product.imageUrl);
    }

    // Assign imageUrl image to selectedProductImage
    selectedProductImage.value = product.imageUrl;

    // Get images from product model if not null
    if (product.images != null) {
      images.addAll(product.images!);
    }

    // Get all images from the product Variations if not null
    /*if (product.productVariations != null ||
        product.productVariations!.isNotEmpty) {
      images.addAll(
          product.productVariations!.map((variation) => variation.image));
    }*/

    return images.toList();
  }

  /// -- Show image popup
  void showEnlargedImage(String image) {
    Get.to(
      fullscreenDialog: true,
      () => Dialog.fullscreen(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: AppSizes.defaultSpace * 2,
                  horizontal: AppSizes.defaultSpace),
              child: CachedNetworkImage(
                imageUrl: image,
              )),
          const SizedBox(height: AppSizes.spaceBtwSections),
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
                width: 150,
                child: OutlinedButton(
                    onPressed: () => Get.back(), child: const Text('Close'))),
          ),
        ],
      )),
    );
  }
}