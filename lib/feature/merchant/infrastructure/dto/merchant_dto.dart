import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/city_input.dart';
import '../../domain/entities/merchant_storefront_link.dart';
import '../../domain/entities/client_gratification_config.dart';
import '../../domain/entities/merchant.dart';
import '../loyalty_program_firestore_mapper.dart';

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
    this.loyaltyEnabled = false,
    this.loyaltyProgramRaw,
    this.messagingEnabled = true,
    this.notificationsAutoEnabled = true,
    this.galerieEnabled = true,
    this.rappelsAutoClientValidation,
    this.rappelsAutoPassageValidation,
    this.passageCooldownEnabled,
    this.rappelsMonthlyConnectedClients = 0,
    this.rappelsMonthlyValidatedPassages = 0,
    this.weeklyNotifSentCount = 0,
    this.weeklyNotifResetAt,
    this.merchantType = 'b2c',
    this.welcomeGiftDescription,
    this.categoryId,
    this.subcategoryTitle,
    this.gratificationConfigRaw,
    this.publicFollowersCount = 0,
    this.storefrontLinks = const [],
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
  final bool loyaltyEnabled;
  /// Raw `loyalty_program` map from Firestore (parsed in [toDomain]).
  final Map<String, dynamic>? loyaltyProgramRaw;
  final bool messagingEnabled;
  final bool notificationsAutoEnabled;
  final bool galerieEnabled;
  final bool? rappelsAutoClientValidation;
  final bool? rappelsAutoPassageValidation;
  final bool? passageCooldownEnabled;
  final int rappelsMonthlyConnectedClients;
  final int rappelsMonthlyValidatedPassages;
  final int weeklyNotifSentCount;
  final DateTime? weeklyNotifResetAt;
  final String merchantType;
  final String? welcomeGiftDescription;
  final String? categoryId;
  final String? subcategoryTitle;
  /// Raw `gratification_config` map from Firestore (parsed in [toDomain]).
  final Map<String, dynamic>? gratificationConfigRaw;

  /// Denormalized follower count (`public_followers_count` on merchant doc).
  final int publicFollowersCount;

  final List<MerchantStorefrontLink> storefrontLinks;

  static List<MerchantStorefrontLink> _parseStorefrontLinks(dynamic raw) {
    if (raw is! List) return const [];
    final out = <MerchantStorefrontLink>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final link = MerchantStorefrontLink.fromMap(
        Map<String, dynamic>.from(item),
      );
      if (link.isValid) out.add(link);
    }
    return out;
  }

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

    Map<String, dynamic>? loyaltyRaw;
    final lp = data['loyalty_program'];
    if (lp is Map) {
      loyaltyRaw = Map<String, dynamic>.from(lp);
    }
    final loyaltyParsed = LoyaltyProgramFirestoreMapper.fromFirestoreMap(lp);
    final loyaltyEnabledEffective = loyaltyParsed?.programEnabled ??
        (data['loyalty_enabled'] == true);

    return MerchantDto(
      id: doc.id,
      ownerUid: data['owner_uid'] as String? ?? '',
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      city: data['city'] as String? ?? '',
      address: data['address'] as String?,
      categories: data['categories'] is List
          ? List<String>.from(data['categories'] as List)
          : null,
      description: data['description'] as String?,
      hours: data['hours'] is Map
          ? Map<String, dynamic>.from(data['hours'] as Map)
          : null,
      status: data['status'] as String? ?? 'inactive',
      createdAt: parseTimestamp(data['created_at']),
      updatedAt: parseTimestamp(data['updated_at']),
      displayName: data['display_name'] as String?,
      logoUrl: data['logo_url'] as String?,
      websiteUrl: data['website_url'] as String?,
      bannerUrl: data['banner_url'] as String?,
      newsImageUrls: data['news_image_urls'] is List
          ? List<String>.from(data['news_image_urls'] as List)
          : null,
      loyaltyEnabled: loyaltyEnabledEffective,
      loyaltyProgramRaw: loyaltyRaw,
      // Defensive bool casts: `as bool? ?? default` throws TypeError if Firestore
      // stored the field as an int (0/1) or string ('true'/'false'). Use `!= false`
      // for true-defaulting fields (null → true) and `== true` for false-defaulting.
      messagingEnabled: data['messaging_enabled'] != false,
      notificationsAutoEnabled: data['notifications_auto_enabled'] != false,
      galerieEnabled: data['galerie_enabled'] != false,
      rappelsAutoClientValidation:
          data['rappels_auto_client_validation'] is bool
              ? data['rappels_auto_client_validation'] as bool
              : null,
      rappelsAutoPassageValidation:
          data['rappels_auto_passage_validation'] is bool
              ? data['rappels_auto_passage_validation'] as bool
              : null,
      passageCooldownEnabled: data['passage_cooldown_enabled'] is bool
          ? data['passage_cooldown_enabled'] as bool
          : null,
      rappelsMonthlyConnectedClients:
          nonNegativeInt(data['rappels_monthly_connected_clients']),
      rappelsMonthlyValidatedPassages:
          nonNegativeInt(data['rappels_monthly_validated_passages']),
      weeklyNotifSentCount: nonNegativeInt(data['weekly_notif_sent_count']),
      weeklyNotifResetAt: parseTimestamp(data['weekly_notif_reset_at']),
      merchantType: data['merchant_type'] as String? ?? 'b2c',
      welcomeGiftDescription: data['welcome_gift_description'] as String?,
      categoryId: data['category_id'] as String?,
      subcategoryTitle: data['subcategory_title'] as String?,
      gratificationConfigRaw: data['gratification_config'] is Map
          ? Map<String, dynamic>.from(
              data['gratification_config'] as Map)
          : null,
      publicFollowersCount: nonNegativeInt(data['public_followers_count']),
      storefrontLinks: _parseStorefrontLinks(data['storefront_links']),
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
        loyaltyEnabled: loyaltyEnabled,
        loyaltyProgram:
            LoyaltyProgramFirestoreMapper.fromFirestoreMap(loyaltyProgramRaw),
        messagingEnabled: messagingEnabled,
        notificationsAutoEnabled: notificationsAutoEnabled,
        galerieEnabled: galerieEnabled,
        rappelsAutoClientValidation: rappelsAutoClientValidation,
        rappelsAutoPassageValidation: rappelsAutoPassageValidation,
        passageCooldownEnabled: passageCooldownEnabled,
        rappelsMonthlyConnectedClients: rappelsMonthlyConnectedClients,
        rappelsMonthlyValidatedPassages: rappelsMonthlyValidatedPassages,
        weeklyNotifSentCount: weeklyNotifSentCount,
        weeklyNotifResetAt: weeklyNotifResetAt,
        merchantType: merchantType,
        welcomeGiftDescription: welcomeGiftDescription,
        categoryId: categoryId,
        subcategoryTitle: subcategoryTitle,
        gratificationConfig: gratificationConfigRaw != null
            ? ClientGratificationConfig.fromMap(gratificationConfigRaw!)
            : null,
        publicFollowersCount: publicFollowersCount,
        storefrontLinks: storefrontLinks,
      );
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
        loyaltyEnabled: merchant.loyaltyEnabled,
        loyaltyProgramRaw: merchant.loyaltyProgram != null
            ? LoyaltyProgramFirestoreMapper.toFirestoreMap(merchant.loyaltyProgram!)
            : null,
        messagingEnabled: merchant.messagingEnabled,
        notificationsAutoEnabled: merchant.notificationsAutoEnabled,
        galerieEnabled: merchant.galerieEnabled,
        rappelsAutoClientValidation: merchant.rappelsAutoClientValidation,
        rappelsAutoPassageValidation: merchant.rappelsAutoPassageValidation,
        passageCooldownEnabled: merchant.passageCooldownEnabled,
        rappelsMonthlyConnectedClients: merchant.rappelsMonthlyConnectedClients,
        rappelsMonthlyValidatedPassages: merchant.rappelsMonthlyValidatedPassages,
        weeklyNotifSentCount: merchant.weeklyNotifSentCount,
        weeklyNotifResetAt: merchant.weeklyNotifResetAt,
        merchantType: merchant.merchantType,
        welcomeGiftDescription: merchant.welcomeGiftDescription,
        categoryId: merchant.categoryId,
        subcategoryTitle: merchant.subcategoryTitle,
        gratificationConfigRaw: merchant.gratificationConfig?.toMap(),
        publicFollowersCount: merchant.publicFollowersCount,
        storefrontLinks: merchant.storefrontLinks,
      );
  /// Note: 'id' is not included as it's the Firestore document ID.
  Map<String, dynamic> toFirestore() => <String, dynamic>{
        'owner_uid': ownerUid,
        'name': name,
        'name_lowercase': name.toLowerCase(),
        'email': email,
        'phone': phone,
        'city': CityInput.forFirestore(city) ?? city,
        if (address != null) 'address': address,
        if (categories != null) 'categories': categories,
        if (description != null) 'description': description,
        if (hours != null) 'hours': hours,
        if (displayName != null) 'display_name': displayName,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (websiteUrl != null) 'website_url': websiteUrl,
        if (bannerUrl != null) 'banner_url': bannerUrl,
        if (newsImageUrls != null) 'news_image_urls': newsImageUrls,
        'loyalty_enabled': loyaltyEnabled,
        if (loyaltyProgramRaw != null) 'loyalty_program': loyaltyProgramRaw,
        'messaging_enabled': messagingEnabled,
        'notifications_auto_enabled': notificationsAutoEnabled,
        'galerie_enabled': galerieEnabled,
        if (rappelsAutoClientValidation != null) 'rappels_auto_client_validation': rappelsAutoClientValidation,
        if (rappelsAutoPassageValidation != null) 'rappels_auto_passage_validation': rappelsAutoPassageValidation,
        if (passageCooldownEnabled != null) 'passage_cooldown_enabled': passageCooldownEnabled,
        'merchant_type': merchantType,
        if (welcomeGiftDescription != null)
          'welcome_gift_description': welcomeGiftDescription,
        if (categoryId != null) 'category_id': categoryId,
        if (subcategoryTitle != null) 'subcategory_title': subcategoryTitle,
        if (gratificationConfigRaw != null)
          'gratification_config': gratificationConfigRaw,
        'status': status,
        'created_at': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
}

