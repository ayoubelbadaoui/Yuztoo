import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/domain/entities/french_commune.dart';

/// What the client already entered in onboarding, saved on the device so an
/// app kill / phone restart mid-onboarding resumes at the same step instead
/// of starting over at « Bienvenue ». Cleared once onboarding is saved.
class ClientOnboardingDraft {
  const ClientOnboardingDraft({
    required this.step,
    this.firstName = '',
    this.lastName = '',
    this.dateOfBirth,
    this.city,
    this.commune,
    this.localImagePath,
  });

  final int step;
  final String firstName;
  final String lastName;
  final DateTime? dateOfBirth;
  final String? city;
  final FrenchCommune? commune;
  final String? localImagePath;

  bool get hasName =>
      firstName.trim().isNotEmpty && lastName.trim().isNotEmpty;

  /// Step to resume at: never past the name step without a name (the last
  /// step needs one to save), never beyond [lastStep].
  int resumeStep(int lastStep) {
    final clamped = step.clamp(0, lastStep);
    if (clamped > 1 && !hasName) return 1;
    return clamped;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'v': 1,
        'step': step,
        'first_name': firstName,
        'last_name': lastName,
        if (dateOfBirth != null) 'dob': dateOfBirth!.toIso8601String(),
        if (city != null) 'city': city,
        if (commune != null) 'commune': commune!.toFirestore(),
        if (localImagePath != null) 'image': localImagePath,
      };

  static ClientOnboardingDraft? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final step = raw['step'];
    if (step is! int) return null;
    String str(String k) => raw[k] is String ? raw[k] as String : '';
    final dob = DateTime.tryParse(str('dob'));
    final city = str('city').trim();
    final communeRaw = raw['commune'];
    final commune = communeRaw is Map
        ? FrenchCommune.fromFirestore(Map<String, dynamic>.from(communeRaw))
        : null;
    final image = str('image').trim();
    return ClientOnboardingDraft(
      step: step,
      firstName: str('first_name'),
      lastName: str('last_name'),
      dateOfBirth: dob,
      city: city.isEmpty ? null : city,
      commune: (commune != null && commune.name.isNotEmpty) ? commune : null,
      localImagePath: image.isEmpty ? null : image,
    );
  }
}

/// SharedPreferences storage, one draft per account.
class ClientOnboardingDraftStore {
  const ClientOnboardingDraftStore._();

  static String _key(String uid) => 'client_onboarding_draft_$uid';

  static Future<ClientOnboardingDraft?> load(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(uid));
      if (raw == null) return null;
      final draft = ClientOnboardingDraft.fromJson(jsonDecode(raw));
      if (draft == null) return null;
      // A picked photo lives in a temp/cache file the OS may have purged.
      final image = draft.localImagePath;
      if (image != null && !File(image).existsSync()) {
        return ClientOnboardingDraft(
          step: draft.step,
          firstName: draft.firstName,
          lastName: draft.lastName,
          dateOfBirth: draft.dateOfBirth,
          city: draft.city,
          commune: draft.commune,
        );
      }
      return draft;
    } catch (_) {
      return null; // corrupt / unreadable: start fresh
    }
  }

  static Future<void> save(String uid, ClientOnboardingDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(uid), jsonEncode(draft.toJson()));
    } catch (_) {}
  }

  static Future<void> clear(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(uid));
    } catch (_) {}
  }
}
