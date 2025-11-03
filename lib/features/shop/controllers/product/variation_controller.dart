import 'package:get/get.dart';

import '../../models/product_variation_model.dart';
import '../../models/produit_model.dart';

class VariationController extends GetxController {
  static VariationController get instance {
    if (Get.isRegistered<VariationController>()) {
      return Get.find<VariationController>();
    }
    // Fallback if not registered (shouldn't happen with proper binding)
    return Get.put(VariationController(), permanent: true);
  }

  /// Variables
  final RxMap<String, dynamic> selectedAttributes = <String, dynamic>{}.obs;
  final RxString variationStockStatus = ''.obs;
  final Rx<ProductVariationModel> selectedVariation =
      ProductVariationModel.empty().obs;

  /// -- Check if selected attributes match variation attributes
  RxString selectedSize = ''.obs;
  RxDouble selectedPrice = 0.0.obs;

  void selectVariation(String size, double price) {
    selectedSize.value = size;
    selectedPrice.value = price;

    // Use size as the variation ID (as it matches cart item variationId)
    // This ensures consistency between cart items and product variations
    final variationId = size;

    // Create or update the variation model
    selectedVariation.value = ProductVariationModel(
      id: variationId,
      attributeValues: {
        'id': variationId,
        'taille': size,
        'size': size, // Support both French and English keys
        'prix': price.toString(),
        'price': price.toString(), // Support both French and English keys
      },
      price: price,
      salePrice: 0.0,
      stock: 10, // example or dynamic value
    );
  }

  void clearVariation() {
    selectedSize.value = '';
    selectedPrice.value = 0.0;
  }

  @override
  void onClose() {
    // Nettoyage automatique quand le contrôleur est supprimé
    clearVariation();
    super.onClose();
  }

  /// -- Get available attribute values based on stock
  Set<String?> getAttributesAvailabilityInVariation(
      List<ProductVariationModel> variations, String attributeName) {
    return variations
        .where((variation) =>
            variation.attributeValues[attributeName] != null &&
            variation.attributeValues[attributeName]!.isNotEmpty &&
            variation.stock > 0)
        .map((variation) => variation.attributeValues[attributeName])
        .toSet();
  }

  String getVariationPrice() {
    return (selectedVariation.value.salePrice > 0
            ? selectedVariation.value.salePrice
            : selectedVariation.value.price)
        .toString();
  }

  /// -- Update stock status text
  void getProductVariationStockStatus() {
    variationStockStatus.value =
        selectedVariation.value.stock > 0 ? 'En Stock' : 'Hors Stock';
  }

  /// -- Reset all selections
  void resetSelectedAttributes() {
    selectedAttributes.clear();
    variationStockStatus.value = '';
    selectedVariation.value = ProductVariationModel.empty();
    // Also clear selectedSize and selectedPrice to keep UI in sync
    clearVariation();
  }

  /// -- Initialize variation from variation ID (size)
  void initializeFromVariationId(String variationId, {double? price}) {
    if (variationId.isEmpty) return;
    // If price is provided, use it; otherwise try to get from selectedPrice
    final variationPrice =
        price ?? (selectedPrice.value > 0 ? selectedPrice.value : 0.0);
    selectVariation(variationId, variationPrice);
  }

  /// -- Initialize variation from product and size
  void initializeFromProductAndSize(ProduitModel product, String size) {
    if (size.isEmpty) return;
    // Find the size in product.sizesPrices
    final sizePrice = product.sizesPrices.firstWhereOrNull(
      (sp) => sp.size == size,
    );
    if (sizePrice != null) {
      selectVariation(sizePrice.size, sizePrice.price);
    }
  }
}
