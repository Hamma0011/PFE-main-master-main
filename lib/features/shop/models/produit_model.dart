import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'etablissement_model.dart';

class ProduitModel {
  final String id;
  final int stockQuantity;
  final String name;
  final String imageUrl;
  final List<String>? images;
  final String categoryId;
  final List<ProductSizePrice> sizesPrices;
  final List<String> supplements;
  final String? description;
  final int preparationTime;
  final String etablissementId;
  final bool isStockable;
  final bool? isFeatured;
  final double price;
  final double salePrice;
  final String productType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Etablissement? etablissement;

  ProduitModel(
      {required this.id,
      required this.name,
      required this.imageUrl,
      this.images,
      required this.categoryId,
      required this.sizesPrices,
      required this.supplements,
      this.description,
      required this.preparationTime,
      required this.etablissementId,
      required this.isStockable,
      required this.stockQuantity,
      this.isFeatured,
      required this.price,
      required this.salePrice,
      required this.productType,
      required this.createdAt,
      required this.updatedAt,
      this.etablissement});

  /// Instance vide
  static ProduitModel empty() {
    return ProduitModel(
      id: '',
      name: '',
      categoryId: '',
      sizesPrices: [],
      supplements: [],
      preparationTime: 0,
      etablissementId: '',
      isStockable: false,
      stockQuantity: 0,
      isFeatured: false,
      price: 0.0,
      salePrice: 0.0,
      productType: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      imageUrl: '',
    );
  }

  factory ProduitModel.fromMap(Map<String, dynamic> map) {
    // --- Gestion de is_featured ---
    bool? isFeatured;
    if (map['is_featured'] != null) {
      final featured = map['is_featured'];
      if (featured is bool) {
        isFeatured = featured;
      } else if (featured is String) {
        isFeatured = featured.toLowerCase() == 'true';
      } else if (featured is int) {
        isFeatured = featured == 1;
      } else {
        // Si c'est un _JsonMap ou autre type, on tente de convertir en bool
        isFeatured = featured.toString().toLowerCase() == 'true';
      }
    }
    // --- Gestion des tailles_prix (jsonb) ---
    List<ProductSizePrice> sizesPrices = [];
    if (map['tailles_prix'] != null) {
      final taillesPrix = map['tailles_prix'];
      if (taillesPrix is String) {
        try {
          final List<dynamic> jsonList = json.decode(taillesPrix);
          sizesPrices = jsonList
              .map((jsonItem) =>
                  ProductSizePrice.fromMap(Map<String, dynamic>.from(jsonItem)))
              .toList();
        } catch (e) {
          if (kDebugMode) {
            print('Erreur parsing tailles_prix (String): $e');
          }
        }
      } else if (taillesPrix is List) {
        try {
          sizesPrices = taillesPrix
              .map((item) =>
                  ProductSizePrice.fromMap(Map<String, dynamic>.from(item)))
              .toList();
        } catch (e) {
          if (kDebugMode) {
            print('Erreur parsing tailles_prix (List): $e');
          }
        }
      } else {
        // Si c'est un _JsonMap ou autre type
        try {
          final jsonString = json.encode(taillesPrix);
          final List<dynamic> jsonList = json.decode(jsonString);
          sizesPrices = jsonList
              .map((jsonItem) =>
                  ProductSizePrice.fromMap(Map<String, dynamic>.from(jsonItem)))
              .toList();
        } catch (e) {
          if (kDebugMode) {
            print('Erreur parsing tailles_prix (_JsonMap): $e');
          }
        }
      }
    }

    // --- Gestion des supplements (text[] ou string JSON) ---
    List<String> supplements = [];
    if (map['supplements'] != null) {
      final supp = map['supplements'];
      if (supp is List) {
        supplements = List<String>.from(supp);
      } else if (supp is String) {
        try {
          supplements = List<String>.from(json.decode(supp));
        } catch (_) {
          supplements = supp.split(',');
        }
      }
    }

    // --- Gestion des images (text[] ou jsonb ou string) ---
    List<String>? images;
    if (map['images'] != null) {
      final imgs = map['images'];
      if (imgs is List) {
        images = List<String>.from(imgs);
      } else if (imgs is String) {
        try {
          images = List<String>.from(json.decode(imgs));
        } catch (_) {
          images = imgs.split(',');
        }
      }
    }

    // --- Gestion des dates ---
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is DateTime) return date;
      if (date is String) {
        try {
          return DateTime.parse(date);
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    try {
      return ProduitModel(
        id: map['id']?.toString() ?? '',
        name: map['nom']?.toString() ?? '',
        imageUrl: map['url_image']?.toString() ?? '',
        images: images,
        categoryId: map['categorie_id']?.toString() ?? '',
        sizesPrices: sizesPrices,
        supplements: supplements,
        description: map['description']?.toString(),
        preparationTime: (map['temps_preparation'] ?? 0) is int
            ? map['temps_preparation']
            : int.tryParse(map['temps_preparation'].toString()) ?? 0,
        etablissementId: map['etablissement_id']?.toString() ?? '',
        isStockable: (map['est_stockable'] ?? false) is bool
            ? map['est_stockable']
            : (map['est_stockable'].toString().toLowerCase() == 'true'),
        stockQuantity: (map['quantite_stock'] ?? 0) is int
            ? map['quantite_stock']
            : int.tryParse(map['quantite_stock'].toString()) ?? 0,
        isFeatured: isFeatured,
        price: map['prix'] == null
            ? 0.0
            : (map['prix'] is double
                ? map['prix']
                : double.tryParse(map['prix'].toString()) ?? 0.0),
        salePrice: map['prix_promo'] == null
            ? 0.0
            : (map['prix_promo'] is double
                ? map['prix_promo']
                : double.tryParse(map['prix_promo'].toString()) ?? 0.0),
        productType: map['product_type']?.toString() ?? '',
        createdAt: parseDate(map['created_at']),
        updatedAt: parseDate(map['updated_at']),
        etablissement: map['etablissement'] != null
            ? Etablissement.fromJson(
                Map<String, dynamic>.from(map['etablissement']))
            : null,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Conversion vers Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': name,
      'url_image': imageUrl,
      'images': images,
      'categorie_id': categoryId,
      'tailles_prix': json.encode(sizesPrices.map((e) => e.toMap()).toList()),
      'supplements': supplements,
      'description': description,
      'temps_preparation': preparationTime,
      'etablissement_id': etablissementId,
      'est_stockable': isStockable,
      'quantite_stock': stockQuantity,
      'is_featured': isFeatured,
      'prix': price,
      'prix_promo': salePrice,
      'product_type': productType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ProduitModel.fromJson(String source) =>
      ProduitModel.fromMap(json.decode(source));

  Map<String, dynamic> toJson({bool includeId = false}) {
    final data = toMap();
    if (!includeId) data.remove('id');
    return data;
  }

  ProduitModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    List<String>? images,
    String? categoryId,
    List<ProductSizePrice>? sizesPrices,
    List<String>? supplements,
    String? description,
    int? preparationTime,
    String? etablissementId,
    bool? isStockable,
    bool? isFeatured,
    int? stockQuantity,
    double? price,
    double? salePrice,
    String? productType,
    DateTime? createdAt,
    DateTime? updatedAt,
    Etablissement? etablissement,
  }) {
    return ProduitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      categoryId: categoryId ?? this.categoryId,
      sizesPrices: sizesPrices ?? this.sizesPrices,
      supplements: supplements ?? this.supplements,
      description: description ?? this.description,
      preparationTime: preparationTime ?? this.preparationTime,
      etablissementId: etablissementId ?? this.etablissementId,
      isStockable: isStockable ?? this.isStockable,
      isFeatured: isFeatured ?? this.isFeatured,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      price: price ?? this.price,
      salePrice: salePrice ?? this.salePrice,
      productType: productType ?? this.productType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      etablissement: etablissement ?? this.etablissement,
    );
  }

  /// Méthodes utilitaires
  double get minPrice => sizesPrices.isEmpty
      ? (salePrice > 0 ? salePrice : price)
      : sizesPrices.map((e) => e.price).reduce((a, b) => a < b ? a : b);

  double get maxPrice => sizesPrices.isEmpty
      ? (price)
      : sizesPrices.map((e) => e.price).reduce((a, b) => a > b ? a : b);

  bool get isAvailable => !isStockable || stockQuantity > 0;

  List<String> get availableSizes => sizesPrices.map((e) => e.size).toList();

  /// Product type helpers for consistent checks
  bool get isVariable => productType == 'variable';
  bool get isSingle => productType == 'single';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProduitModel &&
        other.id == id &&
        other.name == name &&
        other.imageUrl == imageUrl &&
        listEquals(other.images, images) &&
        other.categoryId == categoryId &&
        listEquals(other.sizesPrices, sizesPrices) &&
        listEquals(other.supplements, supplements) &&
        other.description == description &&
        other.preparationTime == preparationTime &&
        other.etablissementId == etablissementId &&
        other.isStockable == isStockable &&
        other.stockQuantity == stockQuantity &&
        other.price == price &&
        other.salePrice == salePrice &&
        other.isFeatured == isFeatured &&
        other.productType == productType &&
        other.etablissement == etablissement;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        imageUrl,
        Object.hashAll(images ?? []),
        categoryId,
        Object.hashAll(sizesPrices),
        Object.hashAll(supplements),
        description,
        preparationTime,
        etablissementId,
        isStockable,
        stockQuantity,
        price,
        salePrice,
        isFeatured,
        productType,
        etablissement,
      );

  @override
  String toString() =>
      'ProduitModel(etablissement: $etablissement, id: $id, name: $name, price: $price, salePrice: $salePrice, isFeatured: $isFeatured, productType: $productType)';
}

class ProductSizePrice {
  final String size;
  final double price;

  ProductSizePrice({
    required this.size,
    required this.price,
  });

  factory ProductSizePrice.fromMap(Map<String, dynamic> map) {
    return ProductSizePrice(
      size: map['taille']?.toString() ?? map['size']?.toString() ?? '',
      price: (map['prix'] ?? map['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'taille': size, 'prix': price};
  }

  factory ProductSizePrice.fromJson(String source) =>
      ProductSizePrice.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  ProductSizePrice copyWith({String? size, double? price}) {
    return ProductSizePrice(
        size: size ?? this.size, price: price ?? this.price);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductSizePrice && other.size == size && other.price == price);

  @override
  int get hashCode => Object.hash(size, price);

  @override
  String toString() => 'ProductSizePrice(size: $size, price: $price)';
}
