class BrandModel {
  String id;
  String name;
  String image;
  bool? isFeatured;
  int? productsCount;

  BrandModel({
    required this.id,
    required this.name,
    required this.image,
    this.isFeatured,
    this.productsCount,
  });

  static BrandModel empty() {
    return BrandModel(id: '', image: '', name: '');
  }

  toJson() {
    return {
      'name': name,
      'image': image,
      'products_count': productsCount,
      'is_featured': isFeatured,
    };
  }

  factory BrandModel.fromJson(Map<String, dynamic> document) {
    final data = document;
    if (data.isEmpty) {
      return BrandModel.empty();
    }
    return BrandModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      isFeatured: data['is_featured'] ?? false,
      productsCount: data['products_count'] as int?,
    );
  }

  factory BrandModel.fromMap(Map<String, dynamic> data) {
    return BrandModel(
      id: data['id']?.toString() ?? '',
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      productsCount: data['products_count'] ?? 0,
      isFeatured: data['is_featured'] ?? false,
    );
  }
}
