import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/merchant.dart';

/// Data Transfer Object for Merchant entity in Firestore.
class MerchantDto {
  const MerchantDto({
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

  final String id;
  final String ownerUid;
  final String name;
  final String email;
  final String phone;
  final String city;
  final String? address;
  final List<String>? categories;
  final String? description;
  final Map<String, dynamic>? hours;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Create DTO from Firestore document snapshot.
  factory MerchantDto.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }

    // Handle Timestamp conversion
    DateTime? parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return null;
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      if (timestamp is DateTime) {
        return timestamp;
      }
      return null;
    }

    return MerchantDto(
      id: doc.id,
      ownerUid: data['owner_uid'] as String? ?? '',
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      city: data['city'] as String? ?? '',
      address: data['address'] as String?,
      categories: data['categories'] != null
          ? List<String>.from(data['categories'] as List)
          : null,
      description: data['description'] as String?,
      hours: data['hours'] as Map<String, dynamic>?,
      status: data['status'] as String? ?? 'active',
      createdAt: parseTimestamp(data['created_at']),
      updatedAt: parseTimestamp(data['updated_at']),
    );
  }

  /// Convert DTO to domain entity.
  Merchant toDomain() => Merchant(
        id: id,
        ownerUid: ownerUid,
        name: name,
        email: email,
        phone: phone,
        city: city,
        address: address,
        categories: categories,
        description: description,
        hours: hours,
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Convert domain entity to DTO.
  factory MerchantDto.fromDomain(Merchant merchant) => MerchantDto(
        id: merchant.id,
        ownerUid: merchant.ownerUid,
        name: merchant.name,
        email: merchant.email,
        phone: merchant.phone,
        city: merchant.city,
        address: merchant.address,
        categories: merchant.categories,
        description: merchant.description,
        hours: merchant.hours,
        status: merchant.status,
        createdAt: merchant.createdAt,
        updatedAt: merchant.updatedAt,
      );

  /// Convert DTO to Firestore map.
  /// Note: 'id' is not included as it's the Firestore document ID.
  Map<String, dynamic> toFirestore() => <String, dynamic>{
        'owner_uid': ownerUid,
        'name': name,
        'email': email,
        'phone': phone,
        'city': city,
        if (address != null) 'address': address,
        if (categories != null) 'categories': categories,
        if (description != null) 'description': description,
        if (hours != null) 'hours': hours,
        'status': status,
        'created_at': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
}

