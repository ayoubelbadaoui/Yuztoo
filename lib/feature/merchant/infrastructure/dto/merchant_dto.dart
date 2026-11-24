import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/domain/entities/french_commune.dart';
import '../../../../core/utils/city_input.dart';
import '../../../../core/utils/city_match.dart';
import '../../../../core/utils/profile_placeholders.dart';
import '../../domain/entities/merchant_storefront_link.dart';
import '../../domain/entities/client_gratification_config.dart';
import '../../domain/entities/merchant.dart';
import '../../domain/entities/merchant_subscription_plan.dart';
import '../../domain/entities/mobility_accessibility.dart';
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
    this.commune,
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
    this.organizationId,
    this.storeLabel,
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
    this.subscriptionPlan = MerchantSubscriptionPlan.gratuit,
    this.mobilityAccessibility = MobilityAccessibility.defaultValue,
  });

  final String id;
  final String ownerUid;
  final String name;
  final String email;
  final String phone;
  final String city;
  final FrenchCommune? commune;
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
  final String? organizationId;
  final String? storeLabel;
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

  final MerchantSubscriptionPlan subscriptionPlan;

  final MobilityAccessibility mobilityAccessibility;

  // Merchant docs are also edited from the console and Cloud Functions, so a
  // field can hold the wrong type; one bad doc must not fail a whole feed.
  static String? _str(dynamic v) => v is String ? v : null;

  /// Real value or null — legacy example strings count as unset.
  static String? _realOrNull(dynamic v) {
    final clean = ProfilePlaceholders.clean(_str(v));
    return clean.isEmpty ? null : clean;
  }

  static List<String> _strList(dynamic v) =>
      v is List ? v.whereType<String>().toList() : const <String>[];

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
      if (v is num && v.isFinite) return v.toInt().clamp(0, 999999999);
      return 0;
    }

    Map<String, dynamic>? loyaltyRaw;
    final lp = data['loyalty_program'];
    if (lp is Map) {
      loyaltyRaw = Map<String, dynamic>.from(lp);
    }
    final loyaltyParsed = LoyaltyProgramFirestoreMapper.fromFirestoreMap(lp);
    final loyaltyEnabledEffective =
        loyaltyParsed?.programEnabled ?? (data['loyalty_enabled'] == true);

    return MerchantDto(
      id: doc.id,
      ownerUid: (_str(data['owner_uid']) ?? ''),
      name: (_str(data['name']) ?? ''),
      email: (_str(data['email']) ?? ''),
      phone: ProfilePlaceholders.clean(_str(data['phone'])),
      city: (_str(data['city']) ?? ''),
      commune: data['city_metadata'] is Map
          ? FrenchCommune.fromFirestore(
              Map<String, dynamic>.from(data['city_metadata'] as Map),
            )
          : null,
      address: _realOrNull(data['address']),
      categories:
          data['categories'] is List ? _strList(data['categories']) : null,
      description: _realOrNull(data['description']),
      hours: data['hours'] is Map
          ? Map<String, dynamic>.from(data['hours'] as Map)
          : null,
      status: (_str(data['status']) ?? 'inactive'),
      createdAt: parseTimestamp(data['created_at']),
      updatedAt: parseTimestamp(data['updated_at']),
      displayName: _str(data['display_name']),
      logoUrl: _str(data['logo_url']),
      websiteUrl: _realOrNull(data['website_url']),
      organizationId: _str(data['organization_id']),
      storeLabel: _str(data['store_label']),
      bannerUrl: _str(data['banner_url']),
      newsImageUrls: data['news_image_urls'] is List
          ? _strList(data['news_image_urls'])
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
      merchantType: (_str(data['merchant_type']) ?? 'b2c'),
      welcomeGiftDescription: _str(data['welcome_gift_description']),
      categoryId: _str(data['category_id']),
      subcategoryTitle: _str(data['subcategory_title']),
      gratificationConfigRaw: data['gratification_config'] is Map
          ? Map<String, dynamic>.from(data['gratification_config'] as Map)
          : null,
      publicFollowersCount: nonNegativeInt(data['public_followers_count']),
      storefrontLinks: _parseStorefrontLinks(data['storefront_links']),
      subscriptionPlan: MerchantSubscriptionPlan.fromFirestore(
        _str(data['subscription_plan']),
      ),
      mobilityAccessibility: MobilityAccessibility.fromFirestore(
        _str(data['mobility_accessibility']),
      ),
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
        commune: commune,
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
        organizationId: organizationId,
        storeLabel: storeLabel,
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
        subscriptionPlan: subscriptionPlan,
        mobilityAccessibility: mobilityAccessibility,
      );
  factory MerchantDto.fromDomain(Merchant merchant) => MerchantDto(
        id: merchant.id,
        ownerUid: merchant.ownerUid,
        name: merchant.name,
        email: merchant.email,
        phone: merchant.phone,
        city: merchant.city,
        commune: merchant.commune,
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
        organizationId: merchant.organizationId,
        storeLabel: merchant.storeLabel,
        bannerUrl: merchant.bannerUrl,
        newsImageUrls: merchant.newsImageUrls,
        loyaltyEnabled: merchant.loyaltyEnabled,
        loyaltyProgramRaw: merchant.loyaltyProgram != null
            ? LoyaltyProgramFirestoreMapper.toFirestoreMap(
                merchant.loyaltyProgram!)
            : null,
        messagingEnabled: merchant.messagingEnabled,
        notificationsAutoEnabled: merchant.notificationsAutoEnabled,
        galerieEnabled: merchant.galerieEnabled,
        rappelsAutoClientValidation: merchant.rappelsAutoClientValidation,
        rappelsAutoPassageValidation: merchant.rappelsAutoPassageValidation,
        passageCooldownEnabled: merchant.passageCooldownEnabled,
        rappelsMonthlyConnectedClients: merchant.rappelsMonthlyConnectedClients,
        rappelsMonthlyValidatedPassages:
            merchant.rappelsMonthlyValidatedPassages,
        weeklyNotifSentCount: merchant.weeklyNotifSentCount,
        weeklyNotifResetAt: merchant.weeklyNotifResetAt,
        merchantType: merchant.merchantType,
        welcomeGiftDescription: merchant.welcomeGiftDescription,
        categoryId: merchant.categoryId,
        subcategoryTitle: merchant.subcategoryTitle,
        gratificationConfigRaw: merchant.gratificationConfig?.toMap(),
        publicFollowersCount: merchant.publicFollowersCount,
        storefrontLinks: merchant.storefrontLinks,
        subscriptionPlan: merchant.subscriptionPlan,
        mobilityAccessibility: merchant.mobilityAccessibility,
      );

  /// Note: 'id' is not included as it's the Firestore document ID.
  Map<String, dynamic> toFirestore() => <String, dynamic>{
        'owner_uid': ownerUid,
        'name': name,
        'name_lowercase': name.toLowerCase(),
        'email': email,
        'phone': phone,
        'city': CityInput.forFirestore(city) ?? city,
        // Découvrir queries `city_keys` (array-contains-any). The server
        // trigger `onMerchantCityKeysSync` computes the same keys.
        'city_keys': merchantCityKeys(
          CityInput.forFirestore(city) ?? city,
          communeName: commune?.name,
        ),
        if (commune != null) 'city_metadata': commune!.toFirestore(),
        if (address != null) 'address': address,
        if (categories != null) 'categories': categories,
        if (description != null) 'description': description,
        if (hours != null) 'hours': hours,
        if (displayName != null) 'display_name': displayName,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (websiteUrl != null) 'website_url': websiteUrl,
        if (organizationId != null) 'organization_id': organizationId,
        if (storeLabel != null) 'store_label': storeLabel,
        if (bannerUrl != null) 'banner_url': bannerUrl,
        if (newsImageUrls != null) 'news_image_urls': newsImageUrls,
        'loyalty_enabled': loyaltyEnabled,
        if (loyaltyProgramRaw != null) 'loyalty_program': loyaltyProgramRaw,
        'messaging_enabled': messagingEnabled,
        'notifications_auto_enabled': notificationsAutoEnabled,
        'galerie_enabled': galerieEnabled,
        if (rappelsAutoClientValidation != null)
          'rappels_auto_client_validation': rappelsAutoClientValidation,
        if (rappelsAutoPassageValidation != null)
          'rappels_auto_passage_validation': rappelsAutoPassageValidation,
        if (passageCooldownEnabled != null)
          'passage_cooldown_enabled': passageCooldownEnabled,
        'merchant_type': merchantType,
        'subscription_plan': subscriptionPlan.firestoreValue,
        'mobility_accessibility': mobilityAccessibility.firestoreValue,
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
