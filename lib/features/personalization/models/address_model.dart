import '../../../utils/formatters/formatter.dart';

class AddressModel {
  String id;
  final String name;
  final String phoneNumber;
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  bool selectedAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? latitude;
  final double? longitude;

  AddressModel(
      {required this.id,
      required this.name,
      required this.phoneNumber,
      required this.street,
      required this.city,
      required this.state,
      required this.postalCode,
      required this.country,
      this.selectedAddress = true,
      this.createdAt,
      this.updatedAt,
      this.latitude,
      this.longitude});

  String get formattedPhoneNo => TFormatter.formatPhoneNumber(phoneNumber);

  static AddressModel empty() {
    return AddressModel(
        id: '',
        name: '',
        phoneNumber: '',
        street: '',
        city: '',
        state: '',
        postalCode: '',
        country: '',
        latitude: 0,
        longitude: 0);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone_number': phoneNumber,
      'street': street,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'selected_address': selectedAddress,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude
    };
  }

  factory AddressModel.fromJson(Map<String, dynamic> data) {
    if (data.isEmpty) return AddressModel.empty();

    return AddressModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phone_number'] ?? '',
      street: data['street'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      postalCode: data['postal_code'] ?? '',
      country: data['country'] ?? '',
      selectedAddress: data['selected_address'] ?? false,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'] as String)
          : null,
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : null,
      latitude: parseDouble(data['latitude']),
      longitude: parseDouble(data['longitude']),
    );
  }

  factory AddressModel.fromMap(Map<String, dynamic> data) {
    return AddressModel(
      id: data['id']?.toString() ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phone_number'] ?? '', // snake_case
      street: data['street'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      postalCode: data['postal_code'] ?? '', // snake_case
      country: data['country'] ?? '',
      selectedAddress: data['selected_address'] ?? false,
      latitude: data['latitude'] != null
          ? (data['latitude'] as num).toDouble()
          : null,
      longitude: data['longitude'] != null
          ? (data['longitude'] as num).toDouble()
          : null,
    );
  }

  @override
  String toString() {
    return '$street, $city, $state, $postalCode, $country';
  }
}

double parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
