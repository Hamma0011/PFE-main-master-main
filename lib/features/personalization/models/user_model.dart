import 'package:caferesto/utils/formatters/formatter.dart';

class UserModel {
  final String id;
  final String email;
  String username;
  String firstName;
  String lastName;
  String phone;
  final String role;
  DateTime? dateOfBirth;
  final String? sex;
  final String? establishmentId;
  final List<String> orderIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  String? profileImageUrl;
  final bool isBanned;

  /// constructeur
  UserModel({
    this.id = '',
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.phone = '00000000',
    required this.role,
    this.dateOfBirth,
    this.sex,
    this.establishmentId,
    this.orderIds = const [],
    this.createdAt,
    this.updatedAt,
    this.profileImageUrl,
    this.isBanned = false,
  });

  /// Fonction Helper
  String get fullName => '$firstName $lastName';

  String get formattedPhoneNo => TFormatter.formatPhoneNumber(phone);

  /// Décomposer par une fonction
  static List<String> nameParts(String fullName) => fullName.split(" ");

  /// Générer nom d'utilisateur
  static String generateUsername(String fullName) {
    List<String> nameParts = fullName.split(" ");
    String firstName = nameParts[0].toLowerCase();
    String lastName = nameParts.length > 1 ? nameParts[1].toLowerCase() : "";

    String camelCaseUsername = "$firstName$lastName";
    return "cwt_$camelCaseUsername";
  }

  // Méthode empty
  static UserModel empty() => UserModel(
        id: '',
        email: '',
        username: '',
        firstName: '',
        lastName: '',
        role: 'Client',
      );

  // Méthode toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'role': role,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'sex': sex,
      'establishment_id': establishmentId,
      'order_ids': orderIds,
      'profile_image_url': profileImageUrl,
      'is_banned': isBanned,
    };
  }

  // Méthode fromJson
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'Client', // Valeur par défaut
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      sex: json['sex'],
      establishmentId: json['establishment_id'],
      orderIds: List<String>.from(json['order_ids'] ?? []),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      profileImageUrl: json['profile_image_url'],
      isBanned: json['is_banned'] ?? false,
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? username,
    String? phone,
    String? role,
    List<String>? orderIds,
    String? profileImageUrl,
    bool? isBanned,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      orderIds: orderIds ?? this.orderIds,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isBanned: isBanned ?? this.isBanned,
    );
  }
}
