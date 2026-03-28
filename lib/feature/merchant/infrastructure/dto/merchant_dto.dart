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
    this.status = 'inactive',
    this.createdAt,
    this.updatedAt,
    this.displayName,
    this.logoUrl,
    this.websiteUrl,
    this.bannerUrl,
    this.newsImageUrls,
    this.rappelsAutoClientValidation,
    this.rappelsAutoPassageValidation,
    this.rappelsMonthlyConnectedClients = 0,
    this.rappelsMonthlyValidatedPassages = 0,
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
  final String? displayName;
  final String? logoUrl;
  final String? websiteUrl;
  final String? bannerUrl;
  final List<String>? newsImageUrls;
  final bool? rappelsAutoClientValidation;
  final bool? rappelsAutoPassageValidation;
  final int rappelsMonthlyConnectedClients;
  final int rappelsMonthlyValidatedPassages;

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

    int nonNegativeInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v < 0 ? 0 : v;
      if (v is num) return v.toInt().clamp(0, 999999999);
      return 0;
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
      status: data['status'] as String? ?? 'inactive',
      createdAt: parseTimestamp(data['created_at']),
      updatedAt: parseTimestamp(data['updated_at']),
      displayName: data['display_name'] as String?,
      logoUrl: data['logo_url'] as String?,
      websiteUrl: data['website_url'] as String?,
      bannerUrl: data['banner_url'] as String?,
      newsImageUrls: data['news_image_urls'] != null
          ? List<String>.from(data['news_image_urls'] as List)
          : null,
      rappelsAutoClientValidation: data['rappels_auto_client_validation'] as bool?,
      rappelsAutoPassageValidation: data['rappels_auto_passage_validation'] as bool?,
      rappelsMonthlyConnectedClients:
          nonNegativeInt(data['rappels_monthly_connected_clients']),
      rappelsMonthlyValidatedPassages:
          nonNegativeInt(data['rappels_monthly_validated_passages']),
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
        displayName: displayName,
        logoUrl: logoUrl,
        websiteUrl: websiteUrl,
        bannerUrl: bannerUrl,
        newsImageUrls: newsImageUrls,
        rappelsAutoClientValidation: rappelsAutoClientValidation,
        rappelsAutoPassageValidation: rappelsAutoPassageValidation,
        rappelsMonthlyConnectedClients: rappelsMonthlyConnectedClients,
        rappelsMonthlyValidatedPassages: rappelsMonthlyValidatedPassages,
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
        displayName: merchant.displayName,
        logoUrl: merchant.logoUrl,
        websiteUrl: merchant.websiteUrl,
        bannerUrl: merchant.bannerUrl,
        newsImageUrls: merchant.newsImageUrls,
        rappelsAutoClientValidation: merchant.rappelsAutoClientValidation,
        rappelsAutoPassageValidation: merchant.rappelsAutoPassageValidation,
        rappelsMonthlyConnectedClients: merchant.rappelsMonthlyConnectedClients,
        rappelsMonthlyValidatedPassages: merchant.rappelsMonthlyValidatedPassages,
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
        if (displayName != null) 'display_name': displayName,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (websiteUrl != null) 'website_url': websiteUrl,
        if (bannerUrl != null) 'banner_url': bannerUrl,
        if (newsImageUrls != null) 'news_image_urls': newsImageUrls,
        if (rappelsAutoClientValidation != null) 'rappels_auto_client_validation': rappelsAutoClientValidation,
        if (rappelsAutoPassageValidation != null) 'rappels_auto_passage_validation': rappelsAutoPassageValidation,
        'status': status,
        'created_at': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
}

