import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/domain/entities/french_commune.dart';
import 'onboarding_flow_provider.dart';

/// Merchant wizard progress saved on the device, so an app kill / phone
/// restart mid-onboarding resumes at the same step with everything already
/// entered (category, name, city, address, hours…). Cleared once the shop
/// is created.
class MerchantOnboardingDraft {
  const MerchantOnboardingDraft({
    required this.data,
    required this.step,
    required this.skipPersonalInfo,
  });

  final MerchantOnboardingData data;
  final int step;

  /// The step list differs with / without the owner-info + logo steps, so a
  /// step index is only meaningful for the same mode.
  final bool skipPersonalInfo;

  int resumeStep({required bool skipPersonalInfo, required int totalSteps}) {
    if (skipPersonalInfo != this.skipPersonalInfo) return 0;
    return step.clamp(0, totalSteps - 1);
  }
}

Map<String, dynamic> merchantOnboardingDataToJson(MerchantOnboardingData d) =>
    <String, dynamic>{
      'owner_first_name': d.ownerFirstName,
      'owner_last_name': d.ownerLastName,
      'owner_dob': d.ownerDateOfBirth?.toIso8601String(),
      'full_name': d.fullName,
      'city': d.city,
      'commune': d.commune?.toFirestore(),
      'image_path': d.imagePath,
      'banner_image_path': d.bannerImagePath,
      'address': d.address,
      'phone': d.phoneNumber,
      'contact_email': d.contactEmail,
      'website': d.websiteUrl,
      'category_id': d.categoryId,
      'category_title': d.categoryTitle,
      'subcategory_title': d.subcategoryTitle,
      'description': d.description,
      'hours': d.hoursJson,
      'merchant_type': d.merchantType,
    }..removeWhere((_, v) => v == null);

MerchantOnboardingData merchantOnboardingDataFromJson(Map<String, dynamic> m) {
  String? str(String k) {
    final v = m[k];
    return v is String && v.trim().isNotEmpty ? v : null;
  }

  String? existingFile(String k) {
    final path = str(k);
    // Picked images live in temp/cache files the OS may have purged.
    return (path != null && File(path).existsSync()) ? path : null;
  }

  final communeRaw = m['commune'];
  final commune = communeRaw is Map
      ? FrenchCommune.fromFirestore(Map<String, dynamic>.from(communeRaw))
      : null;
  final hours = m['hours'];
  return MerchantOnboardingData(
    ownerFirstName: str('owner_first_name'),
    ownerLastName: str('owner_last_name'),
    ownerDateOfBirth: DateTime.tryParse(str('owner_dob') ?? ''),
    fullName: str('full_name'),
    city: str('city'),
    commune: (commune != null && commune.name.isNotEmpty) ? commune : null,
    imagePath: existingFile('image_path'),
    bannerImagePath: existingFile('banner_image_path'),
    address: str('address'),
    phoneNumber: str('phone'),
    contactEmail: str('contact_email'),
    websiteUrl: str('website'),
    categoryId: str('category_id'),
    categoryTitle: str('category_title'),
    subcategoryTitle: str('subcategory_title'),
    description: str('description'),
    hoursJson: hours is Map ? Map<String, dynamic>.from(hours) : null,
    merchantType: str('merchant_type'),
  );
}

/// SharedPreferences storage, one draft per account.
class MerchantOnboardingDraftStore {
  const MerchantOnboardingDraftStore._();

  static String _key(String uid) => 'merchant_onboarding_draft_$uid';

  static Future<MerchantOnboardingDraft?> load(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(uid));
      if (raw == null) return null;
      final m = jsonDecode(raw);
      if (m is! Map) return null;
      final step = m['step'];
      final data = m['data'];
      if (step is! int || data is! Map) return null;
      return MerchantOnboardingDraft(
        data: merchantOnboardingDataFromJson(Map<String, dynamic>.from(data)),
        step: step,
        skipPersonalInfo: m['skip'] == true,
      );
    } catch (_) {
      return null; // corrupt / unreadable: start fresh
    }
  }

  static Future<void> save(String uid, MerchantOnboardingDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(uid),
        jsonEncode(<String, dynamic>{
          'v': 1,
          'step': draft.step,
          'skip': draft.skipPersonalInfo,
          'data': merchantOnboardingDataToJson(draft.data),
        }),
      );
    } catch (_) {
      // e.g. a non-JSON value inside hours: keep the previous draft.
    }
  }

  static Future<void> clear(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(uid));
    } catch (_) {}
  }
}
