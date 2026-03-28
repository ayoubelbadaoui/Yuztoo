/// Business hours domain entity
/// Pure Dart - no Flutter dependencies
/// Represents a time slot (e.g., "8h - 12h")
class TimeSlot {
  const TimeSlot({
    required this.start,
    required this.end,
  });

  final String start; // e.g., "8h"
  final String end; // e.g., "12h"

  String get display => '$start - $end';

  Map<String, dynamic> toMap() => {'start': start, 'end': end};

  static TimeSlot fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      start: map['start'] as String? ?? '8h',
      end: map['end'] as String? ?? '12h',
    );
  }
}

/// Represents business hours for a single day
class DayHours {
  const DayHours({
    required this.dayName,
    required this.isEnabled,
    required this.timeSlots,
  });

  final String dayName; // e.g., "Lundi"
  final bool isEnabled;
  final List<TimeSlot> timeSlots; // Empty if closed

  bool get isClosed => !isEnabled || timeSlots.isEmpty;
  String get displayText {
    if (isClosed) return 'Fermé';
    return timeSlots.map((slot) => slot.display).join('   ');
  }

  Map<String, dynamic> toMap() => {
        'dayName': dayName,
        'isEnabled': isEnabled,
        'timeSlots': timeSlots.map((s) => s.toMap()).toList(),
      };

  static DayHours fromMap(Map<String, dynamic> map, {String dayNameFallback = 'Lundi'}) {
    final slots = map['timeSlots'];
    final list = slots is List
        ? slots.map((e) => TimeSlot.fromMap(Map<String, dynamic>.from(e as Map))).toList()
        : <TimeSlot>[];
    return DayHours(
      dayName: map['dayName'] as String? ?? dayNameFallback,
      isEnabled: map['isEnabled'] as bool? ?? true,
      timeSlots: list,
    );
  }
}

/// Business hours for the entire week
class BusinessHours {
  const BusinessHours({
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
    required this.hasExceptionalClosure,
  });

  final DayHours monday;
  final DayHours tuesday;
  final DayHours wednesday;
  final DayHours thursday;
  final DayHours friday;
  final DayHours saturday;
  final DayHours sunday;
  final bool hasExceptionalClosure;

  List<DayHours> get allDays => [
        monday,
        tuesday,
        wednesday,
        thursday,
        friday,
        saturday,
        sunday,
      ];

  /// Serialize for Firestore.
  Map<String, dynamic> toMap() => {
        'hasExceptionalClosure': hasExceptionalClosure,
        'monday': monday.toMap(),
        'tuesday': tuesday.toMap(),
        'wednesday': wednesday.toMap(),
        'thursday': thursday.toMap(),
        'friday': friday.toMap(),
        'saturday': saturday.toMap(),
        'sunday': sunday.toMap(),
      };

  /// Deserialize from Firestore; returns default hours if map is null/invalid.
  static BusinessHours fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return const BusinessHours(
        monday: DayHours(dayName: 'Lundi', isEnabled: true, timeSlots: [TimeSlot(start: '8h', end: '12h'), TimeSlot(start: '14h', end: '18h')]),
        tuesday: DayHours(dayName: 'Mardi', isEnabled: true, timeSlots: [TimeSlot(start: '8h', end: '12h'), TimeSlot(start: '14h', end: '18h')]),
        wednesday: DayHours(dayName: 'Mercredi', isEnabled: true, timeSlots: [TimeSlot(start: '8h', end: '12h'), TimeSlot(start: '14h', end: '18h')]),
        thursday: DayHours(dayName: 'Jeudi', isEnabled: true, timeSlots: [TimeSlot(start: '8h', end: '12h'), TimeSlot(start: '14h', end: '18h')]),
        friday: DayHours(dayName: 'Vendredi', isEnabled: true, timeSlots: [TimeSlot(start: '8h', end: '12h'), TimeSlot(start: '14h', end: '18h')]),
        saturday: DayHours(dayName: 'Samedi', isEnabled: true, timeSlots: [TimeSlot(start: '8h', end: '12h'), TimeSlot(start: '14h', end: '18h')]),
        sunday: DayHours(dayName: 'Dimanche', isEnabled: false, timeSlots: []),
        hasExceptionalClosure: false,
      );
    }
    return BusinessHours(
      hasExceptionalClosure: map['hasExceptionalClosure'] as bool? ?? false,
      monday: DayHours.fromMap(Map<String, dynamic>.from((map['monday'] ?? {}) as Map), dayNameFallback: 'Lundi'),
      tuesday: DayHours.fromMap(Map<String, dynamic>.from((map['tuesday'] ?? {}) as Map), dayNameFallback: 'Mardi'),
      wednesday: DayHours.fromMap(Map<String, dynamic>.from((map['wednesday'] ?? {}) as Map), dayNameFallback: 'Mercredi'),
      thursday: DayHours.fromMap(Map<String, dynamic>.from((map['thursday'] ?? {}) as Map), dayNameFallback: 'Jeudi'),
      friday: DayHours.fromMap(Map<String, dynamic>.from((map['friday'] ?? {}) as Map), dayNameFallback: 'Vendredi'),
      saturday: DayHours.fromMap(Map<String, dynamic>.from((map['saturday'] ?? {}) as Map), dayNameFallback: 'Samedi'),
      sunday: DayHours.fromMap(Map<String, dynamic>.from((map['sunday'] ?? {}) as Map), dayNameFallback: 'Dimanche'),
    );
  }
}

