import 'package:caferesto/features/shop/models/produit_model.dart';

class CartItemModel {
  String productId;
  String title;
  double price;
  String? image;
  int quantity;
  String variationId;
  String? brandName;
  Map<String, String>? selectedVariation;
  String etablissementId;
  ProduitModel? product;

  CartItemModel({
    required this.productId,
    required this.quantity,
    this.variationId = '',
    this.title = '',
    this.price = 0.0,
    this.image,
    this.brandName,
    this.selectedVariation = const {'id': '', 'taille': '', 'prix': '0.0'},
    this.etablissementId = '',
    this.product,
  });

  static CartItemModel empty() {
    return CartItemModel(productId: '', quantity: 0);
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'title': title,
      'price': price,
      'image': image,
      'quantity': quantity,
      'variationId': variationId,
      'brandName': brandName,
      'selectedVariation':
          selectedVariation ?? {'id': '', 'taille': '', 'prix': '0.0'},
      'etablissementId': etablissementId,
    };
  }

  factory CartItemModel.fromJson(Map<String, dynamic> data) {
    return CartItemModel(
      productId: data['productId'] ?? '',
      title: data['title'] ?? '',
      price: (data['price'] as num).toDouble(),
      image: data['image'],
      quantity: data['quantity'] ?? 1,
      variationId: data['variationId'] ?? '',
      brandName: data['brandName'],
      selectedVariation: data['selectedVariation'] != null
          ? Map<String, String>.from(data['selectedVariation'])
          : null,
      etablissementId: data['etablissementId'] ?? '',
    );
  }
  CartItemModel copyWith({
    String? productId,
    String? title,
    double? price,
    String? image,
    int? quantity,
    String? variationId,
    String? brandName,
    Map<String, String>? selectedVariation,
    String? etablissementId,
    ProduitModel? product,
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      title: title ?? this.title,
      price: price ?? this.price,
      image: image ?? this.image,
      quantity: quantity ?? this.quantity,
      variationId: variationId ?? this.variationId,
      brandName: brandName ?? this.brandName,
      selectedVariation: selectedVariation ?? this.selectedVariation,
      etablissementId: etablissementId ?? this.etablissementId,
      product: product ?? this.product,
    );
  }
}
