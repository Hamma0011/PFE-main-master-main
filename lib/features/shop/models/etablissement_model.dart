import '../../personalization/models/user_model.dart';
import 'horaire_model.dart';
import 'statut_etablissement_model.dart';

class Etablissement {
  final String? id;
  final String name;
  final String address;
  final String? imageUrl;
  final StatutEtablissement statut;
  final double? latitude;
  final double? nbProduits;
  final double? longitude;
  final String idOwner;
  final DateTime createdAt;
  final List<Horaire>? horaires;
  final UserModel? owner;
  final bool isFeatured;

  Etablissement({
    this.id,
    required this.name,
    required this.address,
    this.imageUrl,
    this.statut = StatutEtablissement.en_attente,
    this.latitude,
    this.longitude,
    required this.idOwner,
    DateTime? createdAt,
    this.horaires,
    this.owner,
    this.nbProduits = 0,
    this.isFeatured = false,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Etablissement.fromJson(Map<String, dynamic> json) {
    List<Horaire>? horaires;
    if (json['horaires'] != null && json['horaires'] is List) {
      horaires =
          (json['horaires'] as List).map((e) => Horaire.fromJson(e)).toList();
    }

    final ownerData = json['id_owner'] is Map<String, dynamic>
        ? UserModel.fromJson(json['id_owner'])
        : null;

    return Etablissement(
      id: json['id'],
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      imageUrl: json['image_url'],
      statut: StatutEtablissementExt.fromString(json['statut']),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      idOwner: json['id_owner'] is String
          ? json['id_owner']
          : (json['id_owner']?['id'] ?? ''),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      horaires: horaires,
      owner: json['id_owner'] is Map<String, dynamic>
          ? UserModel.fromJson(json['id_owner'])
          : null,
      isFeatured: json['is_featured'] ?? false,
      nbProduits: (json['nb_produits'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'image_url': imageUrl,
      'statut': statut.value,
      'latitude': latitude,
      'longitude': longitude,
      'id_owner': idOwner,
      'created_at': createdAt.toIso8601String(),
      'is_featured': isFeatured,
      'nb_produits': nbProduits,
    };
  }

  Etablissement copyWith({
    String? id,
    String? name,
    String? address,
    String? imageUrl,
    StatutEtablissement? statut,
    double? latitude,
    double? longitude,
    double? nbProduits,
    String? idOwner,
    DateTime? createdAt,
    List<Horaire>? horaires,
    UserModel? owner,
    bool? isFeatured,
  }) {
    return Etablissement(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      statut: statut ?? this.statut,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      idOwner: idOwner ?? this.idOwner,
      createdAt: createdAt ?? this.createdAt,
      horaires: horaires ?? this.horaires,
      owner: owner ?? this.owner,
      nbProduits: nbProduits ?? this.nbProduits,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  String get ownerDisplayName {
    if (owner != null && owner!.fullName.isNotEmpty) {
      return owner!.fullName;
    }
    return 'Gérant';
  }
}
