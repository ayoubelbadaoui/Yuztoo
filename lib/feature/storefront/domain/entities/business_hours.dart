// Business hours domain entity — pure Dart, no Flutter dependencies.

// ---------------------------------------------------------------------------
// Normalisation utilities (no Flutter dependency)
// ---------------------------------------------------------------------------

/// Converts any stored time string into the canonical `TimeSlotPicker` format:
/// `'Nh'` or `'Nh30'` where N is the hour without a leading zero.
///
/// Handles the most common legacy and mis-typed formats:
///   '08:00' → '8h'     '08h00' → '8h'    '8H30' → '8h30'
///   '08:30' → '8h30'   '8h00'  → '8h'    '8'    → '8h'
///   '8:58'  → '9h'     (minutes snapped to nearest 0 or 30)
///
/// Unknown formats (e.g. 'Fermé', '12:00 PM') are returned **unchanged** so
/// they remain visible rather than silently replaced with a wrong value.
String normalizeTimeString(String raw) {
  final s = raw.trim().toLowerCase();
  if (s.isEmpty) return raw;

  int? h;
  int? m;

  // Pattern 1: 'Nh' or 'Nh30' or 'Nhm' (h separator, optional minutes)
  final hPat = RegExp(r'^(\d{1,2})h(\d{0,2})$').firstMatch(s);
  if (hPat != null) {
    h = int.parse(hPat.group(1)!);
    final minStr = hPat.group(2)!;
    m = minStr.isEmpty ? 0 : int.parse(minStr);
  } else {
    // Pattern 2: 'N:MM' or 'NN:MM' (colon separator)
    final colon = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s);
    if (colon != null) {
      h = int.parse(colon.group(1)!);
      m = int.parse(colon.group(2)!);
    } else {
      // Pattern 3: bare integer hour, e.g. '8' or '08'
      final bare = RegExp(r'^(\d{1,2})$').firstMatch(s);
      if (bare != null) {
        h = int.parse(bare.group(1)!);
        m = 0;
      }
    }
  }

  if (h == null || m == null) return raw; // unknown format → pass through

  // Snap minutes to the nearest 0 or 30-minute boundary.
  final int snappedH;
  final int snappedM;
  if (m < 15) {
    snappedH = h;
    snappedM = 0;
  } else if (m < 45) {
    snappedH = h;
    snappedM = 30;
  } else {
    // Round up to the next hour.
    snappedH = h + 1;
    snappedM = 0;
  }

  // Clamp to the picker's supported range (6h – 23h30).
  if (snappedH < 6) return '6h';
  if (snappedH > 23 || (snappedH == 23 && snappedM > 30)) return '23h30';

  return snappedM == 0 ? '${snappedH}h' : '${snappedH}h30';
}

/// Ensures a stored day name is title-cased French, e.g. 'lundi' → 'Lundi'.
String _normalizeDayName(String? raw, String fallback) {
  if (raw == null || raw.trim().isEmpty) return fallback;
  final t = raw.trim();
  // Title-case: first char upper, rest lower.
  return t[0].toUpperCase() + t.substring(1).toLowerCase();
}

// ---------------------------------------------------------------------------

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
      start: normalizeTimeString(map['start'] as String? ?? '8h'),
      end: normalizeTimeString(map['end'] as String? ?? '12h'),
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

  static DayHours fromMap(Map<String, dynamic> map,
      {String dayNameFallback = 'Lundi'}) {
    final slots = map['timeSlots'];
    final list = slots is List
        ? slots
            .map((e) => TimeSlot.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList()
        : <TimeSlot>[];
    return DayHours(
      dayName: _normalizeDayName(map['dayName'] as String?, dayNameFallback),
      isEnabled: map['isEnabled'] as bool? ?? false,
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

  /// Deserialize from Firestore; returns closed days if map is null/invalid.
  static BusinessHours fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return const BusinessHours(
        monday: DayHours(dayName: 'Lundi', isEnabled: false, timeSlots: []),
        tuesday: DayHours(dayName: 'Mardi', isEnabled: false, timeSlots: []),
        wednesday:
            DayHours(dayName: 'Mercredi', isEnabled: false, timeSlots: []),
        thursday: DayHours(dayName: 'Jeudi', isEnabled: false, timeSlots: []),
        friday: DayHours(dayName: 'Vendredi', isEnabled: false, timeSlots: []),
        saturday: DayHours(dayName: 'Samedi', isEnabled: false, timeSlots: []),
        sunday: DayHours(dayName: 'Dimanche', isEnabled: false, timeSlots: []),
        hasExceptionalClosure: false,
      );
    }
    Map<String, dynamic> _safeDay(String key) {
      final v = map[key];
      return v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
    }

    return BusinessHours(
      hasExceptionalClosure: map['hasExceptionalClosure'] as bool? ?? false,
      monday: DayHours.fromMap(_safeDay('monday'), dayNameFallback: 'Lundi'),
      tuesday: DayHours.fromMap(_safeDay('tuesday'), dayNameFallback: 'Mardi'),
      wednesday:
          DayHours.fromMap(_safeDay('wednesday'), dayNameFallback: 'Mercredi'),
      thursday:
          DayHours.fromMap(_safeDay('thursday'), dayNameFallback: 'Jeudi'),
      friday:
          DayHours.fromMap(_safeDay('friday'), dayNameFallback: 'Vendredi'),
      saturday:
          DayHours.fromMap(_safeDay('saturday'), dayNameFallback: 'Samedi'),
      sunday:
          DayHours.fromMap(_safeDay('sunday'), dayNameFallback: 'Dimanche'),
    );
  }
}
