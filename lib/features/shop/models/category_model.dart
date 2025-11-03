class CategoryModel {
  final String id;
  final String name;
  late final String image;
  final String? parentId;
  final bool isFeatured;

  CategoryModel({
    this.id = '',
    required this.name,
    required this.image,
    this.parentId,
    this.isFeatured = false,
  });

  /// Instance vide
  static CategoryModel empty() {
    return CategoryModel(
      id: '',
      name: '',
      image: '',
      parentId: null,
      isFeatured: false,
    );
  }

  /// Conversion en JSON pour Supabase
  /// Assure que parentId est null si vide
  Map<String, dynamic> toJson({bool includeId = false}) {
    final data = <String, dynamic>{
      'name': name.trim(),
      'image': image,
      'isFeatured': isFeatured,
    };

    // Si parentId est non null et non vide, l'ajouter
    if (parentId != null && parentId!.trim().isNotEmpty) {
      data['parentId'] = parentId;
    } else {
      // FORCER null pour Supabase afin d'éviter ''
      data['parentId'] = null;
    }

    if (includeId && id.isNotEmpty) {
      data['id'] = id;
    }

    return data;
  }

  /// Conversion JSON -> Model
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      // Si parentId est vide ou null, on met null
      parentId: (json['parentId'] == null ||
              json['parentId'].toString().trim().isEmpty)
          ? null
          : json['parentId'].toString(),
      isFeatured: json['isFeatured'] is bool
          ? json['isFeatured']
          : (json['isFeatured']?.toString().toLowerCase() == 'true'),
    );
  }

  /// Conversion spécifique Supabase
  factory CategoryModel.fromSupabaseRow(Map<String, dynamic> row) {
    return CategoryModel(
      id: row['id']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      image: row['image']?.toString() ?? '',
      parentId:
          (row['parentId'] == null || row['parentId'].toString().trim().isEmpty)
              ? null
              : row['parentId'].toString(),
      isFeatured: row['isFeatured'] is bool
          ? row['isFeatured']
          : (row['isFeatured']?.toString().toLowerCase() == 'true'),
    );
  }

  /// Clone avec champs modifiables
  CategoryModel copyWith({
    String? id,
    String? name,
    String? image,
    String? parentId,
    bool? isFeatured,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      parentId: parentId ?? this.parentId,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  factory CategoryModel.fromBasicData(
      {required String id, required String name}) {
    return CategoryModel(
      id: id,
      name: name,
      image: 'assets/images/default_category.png', // Valeur par défaut
    );
  }
}
