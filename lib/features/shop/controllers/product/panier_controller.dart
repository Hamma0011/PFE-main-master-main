import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../../../utils/popups/loaders.dart';
import '../../models/cart_item_model.dart';
import '../../models/produit_model.dart';
import 'variation_controller.dart';

class CartController extends GetxController {
  static CartController get instance {
    try {
      return Get.find<CartController>();
    } catch (e) {
      // If not found, create it (shouldn't happen with proper binding)
      return Get.put(CartController(), permanent: true);
    }
  }

  RxInt cartItemsCount = 0.obs;
  RxDouble totalCartPrice = 0.0.obs;
  final RxMap<String, int> tempQuantityMap = <String, int>{}.obs;
  RxList<CartItemModel> cartItems = <CartItemModel>[].obs;

  // Get VariationController from GetX dependency injection
  VariationController get variationController =>
      VariationController.instance;

  CartController() {
    loadCartItems();
  }

  bool isVariationInCart(String productId, String variationId) {
    return cartItems.any((item) =>
        item.productId == productId &&
        item.variationId == variationId &&
        item.variationId.isNotEmpty);
  }

  void updateVariation(String productId, String newSize, double newPrice) {
    int index = cartItems.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      cartItems[index] = cartItems[index].copyWith(
        selectedVariation: {
          'size': newSize,
          'price': newPrice.toString(),
        },
        price: newPrice,
      );
    }
    updateCartTotals();
  }

  bool canAddProduct(ProduitModel product) {
    // Si le panier est vide, tout est autorisé
    if (cartItems.isEmpty) return true;

    // Récupère l'établissement du premier produit du panier
    final currentEtablissementId = cartItems.first.etablissementId;
    print('Current Etablissement ID in cart: $currentEtablissementId');
    print('Current Etablissement ID in cart: ${product.etablissementId}');
    // Vérifie si l'établissement du produit correspond
    if (product.etablissementId == currentEtablissementId) {
      return true;
    } else {
      // Refuser si ce n'est pas le même établissement
      TLoaders.customToast(
        message:
            "Vous ne pouvez pas ajouter des produits de plusieurs établissements.",
      );
      return false;
    }
  }

  // --- Helper methods --------------------------------------------------------

  bool hasSelectedVariant() {
    final variation = variationController.selectedVariation.value;
    return variation.id.isNotEmpty && variation.attributeValues.isNotEmpty;
  }

  String _getKey(ProduitModel product) {
    final variationId = product.isVariable
        ? variationController.selectedVariation.value.id
        : "";
    return '${product.id}-$variationId';
  }

  // --- Quantity Management ---------------------------------------------------

  void updateTempQuantity(ProduitModel product, int quantity) {
    final key = _getKey(product);
    if (quantity <= 0) {
      tempQuantityMap.remove(key); // remove entry when 0
    } else {
      tempQuantityMap[key] = quantity;
    }
  }

  int getTempQuantity(ProduitModel product) {
    final key = _getKey(product);
    // Use temp if exists, else fallback to actual cart quantity
    final tempQuantity = tempQuantityMap[key];
    if (tempQuantity != null) {
      return tempQuantity;
    }
    // If no temp quantity, get existing quantity from cart
    return getExistingQuantity(product);
  }

  int getExistingQuantity(ProduitModel product) {
    if (product.isSingle) {
      return getProductQuantityInCart(product.id);
    } else {
      final variationId = variationController.selectedVariation.value.id;
      // For variable products, only return quantity if variation is selected
      if (variationId.isEmpty) {
        // No variation selected yet, return 0 (not in cart)
        return 0;
      }
      return getVariationQuantityInCart(product.id, variationId);
    }
  }
  
  /// Reset temp quantity for a product (useful when navigating to add new variation)
  void resetTempQuantityForProduct(String productId) {
    // Remove all temp quantities for this product (regardless of variation)
    tempQuantityMap.removeWhere((key, value) => key.startsWith('$productId-'));
  }

  // --- Add / Remove from Cart -----------------------------------------------

  void modifyCartVariation(String productId, int currentIndex) {
    if (variationController.selectedVariation.value.id.isEmpty) {
      TLoaders.customToast(message: 'Veuillez choisir une variante');
      return;
    }

    // Get the selected size (variation ID is based on size)
    final selectedSize = variationController.selectedSize.value;
    if (selectedSize.isEmpty) {
      TLoaders.customToast(message: 'Veuillez choisir une variante');
      return;
    }

    // Vérifier si la nouvelle variante est déjà dans le panier (excluding current item)
    final existingIndex = cartItems.indexWhere((item) =>
        item.productId == productId &&
        item.variationId == selectedSize &&
        cartItems.indexOf(item) != currentIndex);

    if (existingIndex >= 0) {
      TLoaders.customToast(
          message: 'Cette variante est déjà dans votre panier');
      return;
    }

    // Mettre à jour la variante existante
    final item = cartItems[currentIndex];
    final product = item.product;

    if (product == null) {
      TLoaders.customToast(message: 'Produit introuvable');
      return;
    }

    final variation = variationController.selectedVariation.value;
    final price =
        variation.salePrice > 0 ? variation.salePrice : variation.price;

    // Get the size from attributeValues
    final size = variation.attributeValues['taille'] ??
        variation.attributeValues['size'] ??
        selectedSize;

    // Créer la nouvelle structure de variation
    final newVariation = <String, String>{
      'id': selectedSize,
      'taille': size,
      'prix': price.toString(),
    };

    // Get the temp quantity (user may have modified it)
    final tempQuantity = getTempQuantity(product);
    final finalQuantity = tempQuantity > 0 ? tempQuantity : item.quantity;

    cartItems[currentIndex] = item.copyWith(
      variationId: selectedSize,
      price: price,
      quantity: finalQuantity, // Update quantity if changed
      selectedVariation: newVariation,
      image: variation.image.isEmpty || variation.image == ''
          ? item.image
          : variation.image,
    );

    // Reset temp quantity after modification
    updateTempQuantity(product, 0);
    updateCart();
    TLoaders.customToast(message: 'Variante modifiée avec succès');
    Get.back(); // Retourner à l'écran précédent
  }

  void addToCart(ProduitModel product) {
    if (!canAddProduct(product)) return;

    final quantity = getTempQuantity(product);

    // Vérifications de base
    if (product.isVariable) {
      if (variationController.selectedVariation.value.id.isEmpty) {
        TLoaders.customToast(message: 'Veuillez choisir une variante');
        return;
      }
      if (variationController.selectedVariation.value.stock < 1) {
        TLoaders.customToast(message: 'Produit hors stock');
        return;
      }
    } else if (product.stockQuantity < 1) {
      TLoaders.customToast(message: 'Produit hors stock');
      return;
    }

    // If quantity is 0, default to 1 for new items
    final quantityToAdd = quantity > 0 ? quantity : 1;

    final selectedCartItem = productToCartItem(product, quantityToAdd);

    // Vérifier si la variante existe déjà
    final existingIndex = cartItems.indexWhere((item) =>
        item.productId == selectedCartItem.productId &&
        item.variationId == selectedCartItem.variationId);

    if (existingIndex >= 0) {
      // La variante existe déjà, ne rien faire
      TLoaders.customToast(
          message: 'Cette variante est déjà dans votre panier');
      return;
    }

    // Ajouter la nouvelle variante
    cartItems.add(selectedCartItem);
    TLoaders.customToast(message: 'Produit ajouté au panier');
    
    // Reset temp quantity after successfully adding to cart
    updateTempQuantity(product, 0);
    updateCart();
  }

  CartItemModel productToCartItem(ProduitModel product, int quantity) {
    if (product.isSingle) {
      variationController.resetSelectedAttributes();
    }

    final variation = variationController.selectedVariation.value;
    final isVariation = variation.id.isNotEmpty;
    final price = isVariation
        ? (variation.salePrice > 0 ? variation.salePrice : variation.price)
        : (product.salePrice > 0.0 ? product.salePrice : product.price);

    // Créer la structure de variation uniformisée
    final variationData = isVariation
        ? {
            'id': variation.id,
            'taille': variation.attributeValues['taille'] ??
                variation.attributeValues['size'] ??
                '',
            'prix': price.toString()
          }
        : null;

    return CartItemModel(
      productId: product.id,
      title: product.name,
      price: price,
      image: isVariation ? variation.image : product.imageUrl,
      quantity: quantity,
      variationId: isVariation ? variation.id : '',
      brandName: product.etablissement?.name ?? 'Inconnu',
      selectedVariation: variationData,
      etablissementId: product.etablissementId,
      product: product,
    );
  }

  // --- Cart Management -------------------------------------------------------

  void updateCart() {
    updateCartTotals();
    saveCartItems();
    cartItems.refresh();
  }

  void addOneToCart(CartItemModel item) {
    final index = cartItems.indexWhere((cartItem) =>
        cartItem.productId == item.productId &&
        cartItem.variationId == item.variationId);

    if (index >= 0) {
      // Create new instance to trigger reactivity
      cartItems[index] = cartItems[index].copyWith(
        quantity: cartItems[index].quantity + 1,
      );
    } else {
      cartItems.add(item);
    }
    updateCart();
  }

  void removeOneFromCart(CartItemModel item) {
    final index = cartItems.indexWhere((cartItem) =>
        cartItem.productId == item.productId &&
        cartItem.variationId == item.variationId);

    if (index >= 0) {
      if (cartItems[index].quantity > 1) {
        // Create new instance to trigger reactivity
        cartItems[index] = cartItems[index].copyWith(
          quantity: cartItems[index].quantity - 1,
        );
      } else {
        removeFromCartDialog(index);
        return; // Don't call updateCart() here, it's called in removeFromCartDialog
      }
      updateCart();
    }
  }

  void removeFromCartDialog(int index) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous vraiment supprimer ce produit du panier?',
      textConfirm: 'Oui',
      textCancel: 'Non',
      onConfirm: () {
        cartItems.removeAt(index);
        updateCart();
        TLoaders.customToast(message: 'Produit supprimé du panier');
        Get.back();
      },
      onCancel: () => Get.back(),
    );
  }

  // --- Totals & Storage ------------------------------------------------------

  void updateCartTotals() {
    double calculatedTotalPrice = 0.0;
    int calculatedcartItemsCount = 0;
    for (var item in cartItems) {
      calculatedTotalPrice += (item.price) * item.quantity.toDouble();
      calculatedcartItemsCount += item.quantity;
    }
    totalCartPrice.value = calculatedTotalPrice;
    cartItemsCount.value = calculatedcartItemsCount;
  }

  void saveCartItems() async {
    final cartItemStrings = cartItems.map((item) => item.toJson()).toList();
    await GetStorage().write('cartItems', cartItemStrings);
  }

  void loadCartItems() async {
    final cartItemStrings = GetStorage().read<List<dynamic>>('cartItems');
    if (cartItemStrings != null) {
      cartItems.assignAll(cartItemStrings
          .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>)));
      updateCartTotals();
    }
  }

  // --- Get Quantities --------------------------------------------------------

  int getProductQuantityInCart(String productId) {
    return cartItems
        .where((item) => item.productId == productId)
        .fold(0, (sum, el) => sum + el.quantity);
  }

  int getVariationQuantityInCart(String productId, String variationId) {
    final foundItem = cartItems.firstWhereOrNull(
      (item) => item.productId == productId && item.variationId == variationId,
    );
    return foundItem?.quantity ?? 0;
  }

  void clearCart() {
    tempQuantityMap.clear();
    cartItems.clear();
    updateCart();
  }

  bool canProceedToCheckout() {
    if (cartItems.isEmpty) return false;

    for (final item in cartItems) {
      if (item.quantity <= 0) return false; // prevent checkout if 0 qty
      final product = item.product;
      if (product != null && product.productType == 'variable') {
        if (item.selectedVariation == null || item.selectedVariation!.isEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  int getProductQuantity(String productId) {
    final item = cartItems.firstWhereOrNull((e) => e.productId == productId);
    return item?.quantity ?? 0;
  }

  /// Get all variation IDs that are in cart for a product
  List<String> getVariationsInCart(String productId) {
    return cartItems
        .where((item) =>
            item.productId == productId && item.variationId.isNotEmpty)
        .map((item) => item.variationId)
        .toList();
  }

  bool areAllVariationsInCart(ProduitModel product) {
    final allVariationIds = product.sizesPrices.map((sp) => sp.size).toSet();
    final cartVariationIds = cartItems
        .where((item) => item.productId == product.id)
        .map((item) => item.variationId)
        .toSet();

    return allVariationIds.difference(cartVariationIds).isEmpty;
  }

  /// Get cached map of variations in cart for a product (for performance)
  Set<String> getVariationsInCartSet(String productId) {
    return cartItems
        .where((item) =>
            item.productId == productId && item.variationId.isNotEmpty)
        .map((item) => item.variationId)
        .toSet();
  }
}
