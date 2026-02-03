import 'package:equatable/equatable.dart';

/// Domain representation of a merchant business entity.
/// 
/// This entity is separate from user identity and represents a business
/// that can be owned by a user.
class Merchant extends Equatable {
  const Merchant({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    this.address,
    this.categories,
    this.description,
    this.hours,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  /// Unique identifier for the merchant document
  final String id;

  /// User ID of the merchant owner
  final String ownerUid;

  /// Business name
  final String name;

  /// Business email address
  final String email;

  /// Business phone number
  final String phone;

  /// City where the business is located
  final String city;

  /// Business address (optional)
  final String? address;

  /// List of business categories (optional)
  final List<String>? categories;

  /// Business description (optional)
  final String? description;

  /// Business hours (optional, typically a map or structured data)
  final Map<String, dynamic>? hours;

  /// Merchant status (default: 'active')
  final String status;

  /// Timestamp when the merchant was created
  final DateTime? createdAt;

  /// Timestamp when the merchant was last updated
  final DateTime? updatedAt;

  @override
  List<Object?> get props => <Object?>[
        id,
        ownerUid,
        name,
        email,
        phone,
        city,
        address,
        categories,
        description,
        hours,
        status,
        createdAt,
        updatedAt,
      ];

  /// Creates a copy of the merchant with updated fields
  Merchant copyWith({
    String? id,
    String? ownerUid,
    String? name,
    String? email,
    String? phone,
    String? city,
    String? address,
    List<String>? categories,
    String? description,
    Map<String, dynamic>? hours,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Merchant(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      address: address ?? this.address,
      categories: categories ?? this.categories,
      description: description ?? this.description,
      hours: hours ?? this.hours,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Validates that required fields are not empty
  bool isValid() {
    return id.isNotEmpty &&
        ownerUid.isNotEmpty &&
        name.isNotEmpty &&
        email.isNotEmpty &&
        phone.isNotEmpty &&
        city.isNotEmpty &&
        status.isNotEmpty;
  }
}

