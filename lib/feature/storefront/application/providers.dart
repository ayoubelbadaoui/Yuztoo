import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/storefront.dart';
import '../domain/entities/business_hours.dart';

/// Provider for storefront data
/// In a real implementation, this would fetch from a repository
final storefrontProvider = Provider<Storefront>((ref) {
  // Mock data - in real app, this would come from a use case that calls a repository
  return const Storefront(
    id: 'storefront-1',
    merchantName: 'Nom du commerce',
    businessActivity: 'Activité du commerce',
    bannerImageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCMRYodi3mrgFiB-D7skoz_Vp4pdzXj6zGVn0N3Watm60Uf5VLLMMzHpaiBGF2f8xoK3OeoNPJBtoFlDotGTh9BhR8zy89eK24Ue4rwsw7MWckotcD2Ypx2cGVsW9LQYT76tPzTR6swqDBJ6bSsLoTNlfj34s2tGy-5SZy7E6RwoEgCSKZ7-wsYce96xmBrVkWA_r1DF8VLijg2sEwEnY4jAjrsaSfJg-KG_nG_MladLXO0IdDyViA27IUSzlcMxvyH6bOUPLWYVyE',
    profileImageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCTLaEJ8AFxR2p5xuu8yYCmg1wmsql1OrrW2Mqio8J1IsnGB4MF6_3NYEdHwY5NbYxEoNVfkHgwNMryIdgbQlLD-k6-svWARXEhi_tZBVHaeWeDzWhhpRTWrWCYknSBD9rp5doapij1YWZOtkEcSzTDF216pCPAeVpAKQDjK6by8js_8zoJVnI__u6bK7FieD_JITXKM8WBEl5JDapR2AstyymOncoJyekOyuFrv89NauGC1QgK60yymBCwCVg72naKuzJs9eK_WgI',
    isVerified: true,
    profileCompletionPercentage: 10,
    weeklyViews: 248,
    weeklyViewsChange: 12.0,
  );
});

/// Provider for selected tab in storefront navigation
final storefrontTabProvider = StateProvider<String>((ref) => 'actualite');

/// Initial business hours data
BusinessHours _initialBusinessHours() {
  return BusinessHours(
    monday: DayHours(
      dayName: 'Lundi',
      isEnabled: true,
      timeSlots: const [
        TimeSlot(start: '8h', end: '12h'),
        TimeSlot(start: '14h', end: '18h'),
      ],
    ),
    tuesday: DayHours(
      dayName: 'Mardi',
      isEnabled: true,
      timeSlots: const [
        TimeSlot(start: '8h', end: '12h'),
        TimeSlot(start: '14h', end: '18h'),
      ],
    ),
    wednesday: DayHours(
      dayName: 'Mercredi',
      isEnabled: true,
      timeSlots: const [
        TimeSlot(start: '8h', end: '12h'),
        TimeSlot(start: '14h', end: '18h'),
      ],
    ),
    thursday: DayHours(
      dayName: 'Jeudi',
      isEnabled: true,
      timeSlots: const [
        TimeSlot(start: '8h', end: '12h'),
        TimeSlot(start: '14h', end: '18h'),
      ],
    ),
    friday: DayHours(
      dayName: 'Vendredi',
      isEnabled: true,
      timeSlots: const [
        TimeSlot(start: '8h', end: '12h'),
        TimeSlot(start: '14h', end: '18h'),
      ],
    ),
    saturday: DayHours(
      dayName: 'Samedi',
      isEnabled: true,
      timeSlots: const [
        TimeSlot(start: '8h', end: '12h'),
        TimeSlot(start: '14h', end: '18h'),
      ],
    ),
    sunday: DayHours(
      dayName: 'Dimanche',
      isEnabled: false,
      timeSlots: const [],
    ),
    hasExceptionalClosure: false,
  );
}

/// Provider for business hours data (stateful)
final businessHoursProvider = StateNotifierProvider<BusinessHoursNotifier, BusinessHours>((ref) {
  return BusinessHoursNotifier(_initialBusinessHours());
});

/// Notifier for managing business hours state
class BusinessHoursNotifier extends StateNotifier<BusinessHours> {
  BusinessHoursNotifier(super.state);

  void toggleDay(String dayName, bool enabled) {
    // Helper to get the day hours with default time slots if enabling a closed day
    DayHours _getUpdatedDay(DayHours currentDay, bool enabled) {
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
      monday: _getUpdatedDay(state.monday, enabled),
      tuesday: _getUpdatedDay(state.tuesday, enabled),
      wednesday: _getUpdatedDay(state.wednesday, enabled),
      thursday: _getUpdatedDay(state.thursday, enabled),
      friday: _getUpdatedDay(state.friday, enabled),
      saturday: _getUpdatedDay(state.saturday, enabled),
      sunday: _getUpdatedDay(state.sunday, enabled),
      hasExceptionalClosure: state.hasExceptionalClosure,
    );
  }

  void updateDayHours(String dayName, List<TimeSlot> timeSlots) {
    state = BusinessHours(
      monday: state.monday.dayName == dayName
          ? DayHours(dayName: dayName, isEnabled: state.monday.isEnabled, timeSlots: timeSlots)
          : state.monday,
      tuesday: state.tuesday.dayName == dayName
          ? DayHours(dayName: dayName, isEnabled: state.tuesday.isEnabled, timeSlots: timeSlots)
          : state.tuesday,
      wednesday: state.wednesday.dayName == dayName
          ? DayHours(dayName: dayName, isEnabled: state.wednesday.isEnabled, timeSlots: timeSlots)
          : state.wednesday,
      thursday: state.thursday.dayName == dayName
          ? DayHours(dayName: dayName, isEnabled: state.thursday.isEnabled, timeSlots: timeSlots)
          : state.thursday,
      friday: state.friday.dayName == dayName
          ? DayHours(dayName: dayName, isEnabled: state.friday.isEnabled, timeSlots: timeSlots)
          : state.friday,
      saturday: state.saturday.dayName == dayName
          ? DayHours(dayName: dayName, isEnabled: state.saturday.isEnabled, timeSlots: timeSlots)
          : state.saturday,
      sunday: state.sunday.dayName == dayName
          ? DayHours(dayName: dayName, isEnabled: state.sunday.isEnabled, timeSlots: timeSlots)
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
}

