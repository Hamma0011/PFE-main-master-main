import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  String id;
  String name;
  String image;
  bool? isFeatured;
  int? productsCount;

  BannerModel({
    required this.id,
    required this.name,
    required this.image,
    this.isFeatured,
    this.productsCount,
  });

  static BannerModel empty() {
    return BannerModel(
      id: '',
      image: '',
      name: '',
    );
  }

  toJson() {
    return {
      'Id': id,
      'Name': name,
      'Image': image,
      'ProductsCount': productsCount,
      'IsFeatured': isFeatured,
    };
  }

  factory BannerModel.fromJson(Map<String, dynamic> document) {
    final data = document;
    if (data.isEmpty) {
      return BannerModel.empty();
    }
    return BannerModel(
      id: data['Id'] ?? '',
      name: data['Name'] ?? '',
      image: data['Image'] ?? '',
      isFeatured: data['IsFeatured'] as bool? ?? false,
      productsCount: data['ProductsCount'] as int?,
    );
  }

  factory BannerModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    if (document.data() != null) {
      final data = document.data()!;

      return BannerModel(
        id: document.id,
        name: data['Name'] ?? '',
        image: data['Image'] ?? '',
        productsCount: data['ProductsCount'] ?? '',
        isFeatured: data['IsFeatured'] ?? false,
      );
    } else {
      return BannerModel.empty();
    }
  }
}
