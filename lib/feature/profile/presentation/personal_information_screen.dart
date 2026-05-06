import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/utils/cities.dart';
import '../../auth/core/application/user_display_helpers.dart';
import '../application/providers.dart';

part 'personal_information_screen.part.dart';

class PersonalInformationScreen extends ConsumerStatefulWidget {
  const PersonalInformationScreen({super.key, this.onCreateProAccount});

  final VoidCallback? onCreateProAccount;

  @override
  ConsumerState<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends ConsumerState<PersonalInformationScreen> {
  bool _editing = false;
  bool _saving = false;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  DateTime? _selectedDob;
  bool _seeded = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  /// Seeds controllers once basics have loaded from Firestore.
  void _seed(String? firstName, String? lastName, DateTime? dob) {
    if (_seeded) return;
    _seeded = true;
    _firstNameCtrl.text = firstName ?? '';
    _lastNameCtrl.text = lastName ?? '';
    _selectedDob = dob;
  }

  void _startEdit() => setState(() => _editing = true);

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
    setState(() => _saving = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
      (_) {
        ref.invalidate(userProfileBasicsProvider(uid));
        setState(() {
          _editing = false;
          _seeded = false; // allow re-seeding after invalidation
        });
      },
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _selectedDob ?? DateTime(now.year - 25, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          // ignore: prefer_const_constructors
          colorScheme: ColorScheme.dark(
            primary: MerchantColors.gold,
            surface: MerchantColors.bgHeader,
            onSurface: MerchantColors.textWhite,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: MerchantColors.bgHeader,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDob = picked);
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
      _seed(basics.firstName, basics.lastName, basics.dateOfBirth);
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

    return _buildScaffold(
      context,
      uid: user?.id,
      fullName: fullName,
      email: email,
      phone: phone,
      city: city,
      completionPercent: completionPercent,
      hasPhoto: hasPhoto,
      hasDob: hasDob,
      onCreateProAccount: widget.onCreateProAccount,
    );
  }
}
