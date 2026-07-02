import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/cupertino_dob_picker.dart';
import '../../../core/utils/cities.dart';
import '../../../core/utils/image_crop_utils.dart';
import '../../auth/core/application/providers.dart'
    show updateAuthUserProfileProvider, updateUserCityProvider;
import '../../auth/core/application/user_display_helpers.dart';
import '../../storage/application/providers.dart' show uploadClientAvatarProvider;
import '../application/providers.dart';

part 'personal_information_screen.part.dart';

class PersonalInformationScreen extends ConsumerStatefulWidget {
  const PersonalInformationScreen({
    super.key,
    this.onCreateProAccount,
    this.createOtherRoleLabel,
    this.onBack,
    this.isDualProfile = false,
  });

  /// When true, shows the Yuztoo loyalty preview card (« Présentez votre carte »)
  /// at the bottom — only relevant when the user has both client and merchant
  /// contexts. Single-role users do not see this block.
  final bool isDualProfile;

  /// Tapped when the user wants to add their secondary role.
  ///
  /// The button label auto-adapts to the current role:
  ///  • merchant viewer → "Créer un carnet Yuztoo" (start the client carnet)
  ///  • client viewer   → "Créer un compte pro"    (start merchant onboarding)
  ///
  /// Callers can still override the label via [createOtherRoleLabel] when
  /// they need a specific wording, but the default derivation is the source
  /// of truth — earlier code relied on every caller remembering to pass an
  /// override, which silently regressed the merchant button to "compte pro"
  /// (the user-reported bug) whenever someone added a new entry point.
  final VoidCallback? onCreateProAccount;

  /// Optional explicit override for the secondary-role CTA. When null, the
  /// label is derived from the signed-in user's role (see [onCreateProAccount]).
  final String? createOtherRoleLabel;

  /// When provided, the back button uses this callback instead of
  /// `Navigator.pop`. Used when the screen is rendered as a nested shell
  /// destination (no route to pop) — pass `_handleBackFromNested` so the
  /// shell falls back to its base view.
  final VoidCallback? onBack;

  @override
  ConsumerState<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends ConsumerState<PersonalInformationScreen> {
  bool _editing = false;
  bool _saving = false;
  bool _photoUploading = false;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _picker = ImagePicker();
  DateTime? _selectedDob;
  String? _selectedCity;
  bool _seeded = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  /// Seeds controllers once basics have loaded from Firestore.
  void _seed(String? firstName, String? lastName, DateTime? dob, String? city) {
    if (_seeded) return;
    _seeded = true;
    _firstNameCtrl.text = firstName ?? '';
    _lastNameCtrl.text = lastName ?? '';
    _selectedDob = dob;
    _selectedCity = city?.isNotEmpty == true ? city : null;
  }

  void _startEdit() => setState(() => _editing = true);

  void _setCity(String city) => setState(() => _selectedCity = city);

  void _setPhotoUploading(bool v) => setState(() => _photoUploading = v);

  void _cancelEdit() {
    setState(() {
      _editing = false;
      // Reset seeded flag so controllers re-populate from Firestore on the
      // next edit open (prevents stale cancelled changes appearing again).
      _seeded = false;
    });
  }

  Future<void> _save(String uid) async {
    final fn = _firstNameCtrl.text.trim();
    final ln = _lastNameCtrl.text.trim();
    if (fn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le prénom est requis')),
      );
      return;
    }
    setState(() => _saving = true);
    final result = await ref.read(updateClientBasicInfoProvider).call(
          uid: uid,
          firstName: fn.isNotEmpty ? fn : null,
          lastName: ln.isNotEmpty ? ln : null,
          dateOfBirth: _selectedDob,
        );
    if (!mounted) return;

    // Persist city change independently — non-fatal if it fails.
    if (_selectedCity != null && _selectedCity!.isNotEmpty) {
      await ref
          .read(updateUserCityProvider)
          .call(uid: uid, city: _selectedCity!);
    }

    setState(() => _saving = false);
    await result.fold(
      (f) async => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) async {
        // Mirror the new name into Firebase Auth so any UI that reads
        // user.displayName from authStateProvider (e.g. the shell header)
        // reflects it without a re-sign-in. Failure here is non-fatal —
        // Firestore is the source of truth.
        final newDisplay = ln.isNotEmpty ? '$fn $ln' : fn;
        if (newDisplay.isNotEmpty) {
          await ref
              .read(updateAuthUserProfileProvider)
              .call(displayName: newDisplay);
        }
        final cityChanged =
            _selectedCity != null && _selectedCity!.isNotEmpty;
        await refreshUserProfileCacheWidget(
          ref,
          uid: uid,
          cityChanged: cityChanged,
        );
        if (!mounted) return;
        setState(() {
          _editing = false;
          _seeded = false; // allow re-seeding after invalidation
        });
      },
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    // Open on today; the picker clamps to max-allowed (today − 13y).
    final initial = _selectedDob ?? now;
    final picked = await showCupertinoDobPicker(
      context: context,
      initial: initial,
      minimum: DateTime(1920),
      maximum: DateTime(now.year - 13, now.month, now.day),
    );
    if (picked != null && mounted) setState(() => _selectedDob = picked);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState is Authenticated ? authState.user : null;
    final basics = user == null
        ? null
        : ref.watch(userProfileBasicsProvider(user.id)).valueOrNull;
    final storefront =
        user == null ? null : ref.watch(storefrontProvider).valueOrNull;

    // Seed controllers once data arrives.
    if (basics != null) {
      _seed(basics.firstName, basics.lastName, basics.dateOfBirth, basics.city);
    }

    final fullName =
        user == null ? 'Utilisateur' : resolveDisplayName(user, basics);
    final email = user == null ? '—' : resolveEmail(user, basics);
    final phone = user == null ? '—' : resolvePhone(user, basics);
    final cityRaw = user == null
        ? ''
        : resolveCityForProfile(
            basics,
            isMerchant: user.isMerchant,
            storefront: storefront,
          );
    final city = cityRaw.isNotEmpty ? cityRaw : '—';

    final hasDob = basics?.dateOfBirth != null;
    int completionPercent = 0;
    if (fullName != 'Utilisateur' && fullName.isNotEmpty) completionPercent += 20;
    if (email != '—') completionPercent += 15;
    if (phone != '—') completionPercent += 15;
    if (city != '—') completionPercent += 10;
    if (hasDob) completionPercent += 20;
    final hasPhoto = user?.photoUrl != null && user!.photoUrl!.isNotEmpty;
    if (hasPhoto) completionPercent += 20;

    final uid = user?.id;
    // Decide whether to surface the secondary-role CTA AT ALL.
    //
    // Rule: a user who already holds both roles ("dual profile") has
    // nothing to create — the previous code always rendered the button,
    // which is the regression the user reported ("Une fois le carnet
    // Yuztoo créé cette proposition doit disparaître").
    //
    // When a CTA is appropriate we derive its label from the current
    // role so callers can no longer silently regress wording by adding
    // a new entry point that forgets to pass the override.
    final hasBothRoles = user?.hasBothRoles ?? false;
    final isMerchant = user?.isMerchant ?? false;
    String? resolvedLabel;
    if (!hasBothRoles && user != null) {
      resolvedLabel = widget.createOtherRoleLabel ??
          (isMerchant ? 'Créer un carnet Yuztoo' : 'Créer un compte pro');
    }
    return _buildScaffold(
      context,
      uid: uid,
      fullName: fullName,
      email: email,
      phone: phone,
      city: city,
      completionPercent: completionPercent,
      hasPhoto: hasPhoto,
      hasDob: hasDob,
      photoUrl: user?.photoUrl,
      photoUploading: _photoUploading,
      onPhotoTap: uid != null
          ? () => _pickAndUploadPhoto(uid)
          : null,
      onCreateProAccount: resolvedLabel == null
          ? null
          : widget.onCreateProAccount,
      createOtherRoleLabel: resolvedLabel,
      isDualProfile: widget.isDualProfile,
    );
  }
}
