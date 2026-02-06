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
}

