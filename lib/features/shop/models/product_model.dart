import 'package:caferesto/features/shop/models/brand_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'product_attribute_model.dart';
import 'product_variation_model.dart';

class ProductModel {
  String id;
  int stock;
  String? sku;
  double price;
  String title;
  DateTime? date;
  double salePrice;
  String thumbnail;
  bool? isFeatured;
  BrandModel? brand;
  String? description;
  String? categoryId;
  List<String>? images;
  String productType;
  List<ProductAttributeModel>? productAttributes;
  List<ProductVariationModel>? productVariations;

  ProductModel({
    required this.id,
    required this.title,
    required this.stock,
    required this.price,
    required this.thumbnail,
    required this.productType,
    this.sku,
    this.brand,
    this.date,
    this.images,
    this.salePrice = 0.0,
    this.isFeatured,
    this.categoryId,
    this.description,
    this.productAttributes,
    this.productVariations,
  });

  /// Create Empty func for clean code
  static ProductModel empty() {
    return ProductModel(
      id: '',
      title: '',
      stock: 0,
      price: 0.0,
      thumbnail: '',
      productType: '',
      sku: '',
      brand: null,
      date: null,
      salePrice: 0.0,
      isFeatured: false,
      categoryId: null,
    );
  }

  /// Convert model to JSON structure so that you can store data in Firestore
  toJson() {
    return {
      'SKU': sku,
      'Title': title,
      'Stock': stock,
      'Price': price,
      'Images': images ?? [],
      'Thumbnail': thumbnail,
      'SalePrice': salePrice,
      'IsFeatured': isFeatured,
      'CategoryId': categoryId,
      'Brand': brand?.toJson(),
      'Description': description,
      'ProductType': productType,
      'ProductAttributes': productAttributes != null
          ? productAttributes!.map((e) => e.toJson()).toList()
          : [],
      'ProductVariations': productVariations != null
          ? productVariations!.map((e) => e.toJson()).toList()
          : [],
    };
  }

  /// Convert JSON structure to model
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? '',
      sku: json['sku'] ?? '',
      title: json['title'] ?? '',
      stock: json['stock'] ?? 0,
      price: double.parse((json['price'] ?? 0.0).toString()),
      thumbnail: json['thumbnail'] ?? '',
      brand:
          json['brands'] != null ? BrandModel.fromJson(json['brands']) : null,
      date: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      salePrice: double.parse((json['sale_price'] ?? 0.0).toString()),
      isFeatured: json['is_featured'] ?? false,
      categoryId: json['category_id'] ?? '',
      description: json['description'] ?? '',
      productType: json['product_type'] ?? '',
      images: (json['images'] is List) ? List<String>.from(json['images']) : [],
      productAttributes: (json['product_attributes'] as List?)
          ?.map((e) => ProductAttributeModel.fromJson(e))
          .toList(),
      productVariations: (json['product_variations'] as List?)
          ?.map((e) => ProductVariationModel.fromJson(e))
          .toList(),
    );
  }

  /// Convert JSON structure to model
  factory ProductModel.fromQuerySnapshot(
      QueryDocumentSnapshot<Object?> document) {
    final data = document.data()! as Map<String, dynamic>;
    return ProductModel(
      id: document.id,
      sku: data['SKU'] ?? '',
      title: data['Title'] ?? '',
      stock: data['Stock'] ?? 0,
      price: double.parse((data['Price'] ?? 0.0).toString()),
      thumbnail: data['Thumbnail'] ?? '',
      brand: data['Brand'] != null ? BrandModel.fromJson(data['Brand']) : null,
      date: data['Date'] != null ? DateTime.parse(data['Date']) : null,
      salePrice: double.parse((data['SalePrice'] ?? 0.0).toString()),
      isFeatured: data['IsFeatured'] ?? false,
      categoryId: data['CategoryId'] ?? '',
      description: data['Description'] ?? '',
      productType: data['ProductType'] ?? '',
      images: List<String>.from(data['Images'] ?? []),
      productAttributes: (data['ProductAttributes'] as List?)
          ?.map((e) => ProductAttributeModel.fromJson(e))
          .toList(),
      productVariations: (data['ProductVariations'] as List?)
          ?.map((e) => ProductVariationModel.fromJson(e))
          .toList(),
    );
  }
}
