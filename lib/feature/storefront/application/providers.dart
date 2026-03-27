import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/firebase_providers.dart';
import '../domain/entities/storefront.dart';
import '../domain/entities/business_hours.dart';
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant/infrastructure/merchant_repository_provider.dart';
import '../../auth/core/application/providers.dart' as auth_providers;
import '../../auth/core/application/state/auth_state.dart';

/// Check if a value is a placeholder/default text (DDD: domain logic)
bool _isPlaceholderText(String? value) {
  if (value == null || value.trim().isEmpty) return true;
  final trimmed = value.trim();
  return trimmed == 'Décrivez votre activité en quelques lignes.' ||
      trimmed == '+33 6 12 34 56 78' ||
      trimmed == 'www.votresite.com' ||
      trimmed == 'Votre adresse' ||
      trimmed == 'Nom du commerce' ||
      trimmed.isEmpty;
}

/// Calculate profile completion percentage based on filled fields (DDD: domain logic)
///
/// Required fields (40%):
/// - name: 10%
/// - email: 10%
/// - phone: 10%
/// - city: 10%
///
/// Optional fields (60%):
/// - address: 8%
/// - category: 8%
/// - description: 8%
/// - websiteUrl: 6%
/// - banner image: 15%
/// - profile image: 15%
int _calculateProfileCompletionPercentage({
  required String? name,
  required String? email,
  required String? phone,
  required String? city,
  String? address,
  String? category,
  List<String>? categories,
  String? description,
  String? websiteUrl,
  String? bannerImagePath,
  String? profileImagePath,
  String? bannerImageUrl,
  String? profileImageUrl,
}) {
  int percentage = 0;

  // Required fields (40% total) - exclude placeholder text
  if (name != null && name.trim().isNotEmpty && !_isPlaceholderText(name)) {
    percentage += 10;
  }
  if (email != null && email.trim().isNotEmpty && !_isPlaceholderText(email)) {
    percentage += 10;
  }
  if (phone != null && phone.trim().isNotEmpty && !_isPlaceholderText(phone)) {
    percentage += 10;
  }
  if (city != null && city.trim().isNotEmpty && !_isPlaceholderText(city)) {
    percentage += 10;
  }

  // Optional fields (60% total) - exclude placeholder text
  if (address != null &&
      address.trim().isNotEmpty &&
      !_isPlaceholderText(address)) {
    percentage += 8;
  }
  if ((category != null &&
          category.trim().isNotEmpty &&
          !_isPlaceholderText(category)) ||
      (categories != null && categories.isNotEmpty)) {
    percentage += 8;
  }
  if (description != null &&
      description.trim().isNotEmpty &&
      !_isPlaceholderText(description)) {
    percentage += 8;
  }
  if (websiteUrl != null &&
      websiteUrl.trim().isNotEmpty &&
      !_isPlaceholderText(websiteUrl)) {
    percentage += 6;
  }

  // Check for images (banner and profile) - images count as completed
  // Image is valid if: has local file path OR has URL that's not default placeholder
  final hasBannerImage =
      (bannerImagePath != null && bannerImagePath.trim().isNotEmpty) ||
          (bannerImageUrl != null &&
              bannerImageUrl.trim().isNotEmpty &&
              (bannerImageUrl.startsWith('file://') ||
                  bannerImageUrl.startsWith('http'))); // Custom image
  final hasProfileImage =
      (profileImagePath != null && profileImagePath.trim().isNotEmpty) ||
          (profileImageUrl != null &&
              profileImageUrl.trim().isNotEmpty &&
              (profileImageUrl.startsWith('file://') ||
                  profileImageUrl.startsWith('http'))); // Custom image

  if (hasBannerImage) {
    percentage += 15;
  }
  if (hasProfileImage) {
    percentage += 15;
  }

  return percentage.clamp(0, 100);
}

Storefront _storefrontFromMerchant(Merchant merchant) {
  final bannerImageUrl = merchant.bannerUrl ?? '';
  final profileImageUrl = merchant.logoUrl ?? '';
  final merchantName = merchant.displayName ?? merchant.name;

  final completionPercentage = _calculateProfileCompletionPercentage(
    name: merchant.name,
    email: merchant.email,
    phone: merchant.phone,
    city: merchant.city,
    address: merchant.address,
    categories: merchant.categories,
    description: merchant.description,
    websiteUrl: merchant.websiteUrl,
    bannerImageUrl: bannerImageUrl,
    profileImageUrl: profileImageUrl,
  );

  return Storefront(
    id: merchant.id,
    merchantName: merchantName,
    description: merchant.description ?? '',
    city: merchant.city,
    bannerImageUrl: bannerImageUrl,
    profileImageUrl: profileImageUrl,
    loyaltyEnabled: merchant.loyaltyEnabled,
    isVerified: true,
    isPublished: merchant.status == 'active',
    profileCompletionPercentage: completionPercentage,
    weeklyViews: 0,
    weeklyViewsChange: 0.0,
    newsContent: merchant.description,
    newsImageUrls: merchant.newsImageUrls ?? const [],
    phone: merchant.phone,
    address: merchant.address,
    websiteUrl: merchant.websiteUrl,
    hours: merchant.hours,
    rappelsAutoClientValidation: merchant.rappelsAutoClientValidation ?? true,
    rappelsAutoPassageValidation: merchant.rappelsAutoPassageValidation ?? true,
    rappelsMonthlyConnectedClients: merchant.rappelsMonthlyConnectedClients,
    rappelsMonthlyValidatedPassages: merchant.rappelsMonthlyValidatedPassages,
  );
}

/// Provider for storefront data — strictly Firestore-driven.
///
/// [autoDispose] so leaving the vitrine (and any screen that watched this) can
/// drop cached [AsyncData]; returning to the tab or resuming the app refetches
/// fresh merchant data instead of showing a stale snapshot.
final storefrontProvider = FutureProvider.autoDispose<Storefront?>((ref) async {
  final authState = ref.watch(auth_providers.authStateProvider);

  if (authState is! Authenticated) {
    return null;
  }

  final userId = authState.user.id;
  final firestore = ref.read(firebaseFirestoreProvider);
  final merchantRepo = ref.read(merchantRepositoryProvider);

  final userDoc = await firestore.collection('users').doc(userId).get();
  final userData = userDoc.data();
  final merchantId = (userData?['merchant_id'] as String?)?.trim();
  if (merchantId == null || merchantId.isEmpty) {
    return null;
  }

  final merchantResult = await merchantRepo.getMerchantById(merchantId);
  return merchantResult.fold(
    (failure) => throw Exception(
      failure.message.isNotEmpty
          ? failure.message
          : 'Impossible de charger la boutique.',
    ),
    (merchant) => merchant == null ? null : _storefrontFromMerchant(merchant),
  );
});

/// Provider for selected tab in storefront navigation
final storefrontTabProvider = StateProvider<String>((ref) => 'actualite');

/// Initial business hours data
BusinessHours _initialBusinessHours() {
  return const BusinessHours(
    monday: DayHours(
      dayName: 'Lundi',
      isEnabled: false,
      timeSlots: [],
    ),
    tuesday: DayHours(
      dayName: 'Mardi',
      isEnabled: false,
      timeSlots: [],
    ),
    wednesday: DayHours(
      dayName: 'Mercredi',
      isEnabled: false,
      timeSlots: [],
    ),
    thursday: DayHours(
      dayName: 'Jeudi',
      isEnabled: false,
      timeSlots: [],
    ),
    friday: DayHours(
      dayName: 'Vendredi',
      isEnabled: false,
      timeSlots: [],
    ),
    saturday: DayHours(
      dayName: 'Samedi',
      isEnabled: false,
      timeSlots: [],
    ),
    sunday: DayHours(
      dayName: 'Dimanche',
      isEnabled: false,
      timeSlots: [],
    ),
    hasExceptionalClosure: false,
  );
}

/// Provider for business hours data (stateful)
final businessHoursProvider =
    StateNotifierProvider<BusinessHoursNotifier, BusinessHours>((ref) {
  return BusinessHoursNotifier(_initialBusinessHours());
});

/// Notifier for managing business hours state
class BusinessHoursNotifier extends StateNotifier<BusinessHours> {
  BusinessHoursNotifier(super.state);

  void toggleDay(String dayName, bool enabled) {
    // Helper to get the day hours with default time slots if enabling a closed day
    DayHours getUpdatedDay(DayHours currentDay, bool enabled) {
      if (currentDay.dayName == dayName) {
        // If enabling and has no time slots, add default ones (symmetric with other days)
        if (enabled && currentDay.timeSlots.isEmpty) {
          return DayHours(
            dayName: dayName,
            isEnabled: enabled,
            timeSlots: const [
              TimeSlot(start: '8h', end: '12h'),
              TimeSlot(start: '14h', end: '18h'),
            ],
          );
        }
        // Otherwise just update enabled state
        return DayHours(
          dayName: dayName,
          isEnabled: enabled,
          timeSlots: currentDay.timeSlots,
        );
      }
      return currentDay;
    }

    state = BusinessHours(
      monday: getUpdatedDay(state.monday, enabled),
      tuesday: getUpdatedDay(state.tuesday, enabled),
      wednesday: getUpdatedDay(state.wednesday, enabled),
      thursday: getUpdatedDay(state.thursday, enabled),
      friday: getUpdatedDay(state.friday, enabled),
      saturday: getUpdatedDay(state.saturday, enabled),
      sunday: getUpdatedDay(state.sunday, enabled),
      hasExceptionalClosure: state.hasExceptionalClosure,
    );
  }

  void updateDayHours(String dayName, List<TimeSlot> timeSlots) {
    state = BusinessHours(
      monday: state.monday.dayName == dayName
          ? DayHours(
              dayName: dayName,
              isEnabled: state.monday.isEnabled,
              timeSlots: timeSlots)
          : state.monday,
      tuesday: state.tuesday.dayName == dayName
          ? DayHours(
              dayName: dayName,
              isEnabled: state.tuesday.isEnabled,
              timeSlots: timeSlots)
          : state.tuesday,
      wednesday: state.wednesday.dayName == dayName
          ? DayHours(
              dayName: dayName,
              isEnabled: state.wednesday.isEnabled,
              timeSlots: timeSlots)
          : state.wednesday,
      thursday: state.thursday.dayName == dayName
          ? DayHours(
              dayName: dayName,
              isEnabled: state.thursday.isEnabled,
              timeSlots: timeSlots)
          : state.thursday,
      friday: state.friday.dayName == dayName
          ? DayHours(
              dayName: dayName,
              isEnabled: state.friday.isEnabled,
              timeSlots: timeSlots)
          : state.friday,
      saturday: state.saturday.dayName == dayName
          ? DayHours(
              dayName: dayName,
              isEnabled: state.saturday.isEnabled,
              timeSlots: timeSlots)
          : state.saturday,
      sunday: state.sunday.dayName == dayName
          ? DayHours(
              dayName: dayName,
              isEnabled: state.sunday.isEnabled,
              timeSlots: timeSlots)
          : state.sunday,
      hasExceptionalClosure: state.hasExceptionalClosure,
    );
  }

  void toggleExceptionalClosure(bool enabled) {
    state = BusinessHours(
      monday: state.monday,
      tuesday: state.tuesday,
      wednesday: state.wednesday,
      thursday: state.thursday,
      friday: state.friday,
      saturday: state.saturday,
      sunday: state.sunday,
      hasExceptionalClosure: enabled,
    );
  }

  /// Load state from Firestore map (e.g. when storefront loads with saved hours).
  void loadFromMap(Map<String, dynamic>? map) {
    state = BusinessHours.fromMap(map);
  }
}
