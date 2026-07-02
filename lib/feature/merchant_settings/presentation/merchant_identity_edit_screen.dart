import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../../core/shared/widgets/cupertino_dob_picker.dart';
import '../../../core/shared/widgets/snackbar.dart';
import '../../auth/core/application/providers.dart' as auth_providers;
import '../../auth/core/application/state/auth_state.dart';
import '../../auth/core/domain/entities/user_profile_basics.dart';
import '../../merchant/application/providers.dart' as merchant_providers;
import '../../merchant/domain/entities/merchant.dart';
import '../../merchant/infrastructure/merchant_repository_provider.dart';
import '../../profile/application/providers.dart'
    show refreshUserProfileCacheWidget;

/// Lets a merchant edit their personal identity (owner first/last name, DOB,
/// professional contact email) and core commerce info (trading name, phone).
///
/// Owner personal data → `users/{uid}` via [UpdateClientBasicInfo].
/// Commerce data       → `merchants/{merchantId}` via [MerchantRepository.updateMerchant].
///
/// Business email (Firebase Auth email) is displayed read-only with a note —
/// changing it requires identity verification that is out of scope here.
class MerchantIdentityEditScreen extends ConsumerStatefulWidget {
  const MerchantIdentityEditScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  ConsumerState<MerchantIdentityEditScreen> createState() =>
      _MerchantIdentityEditScreenState();
}

class _MerchantIdentityEditScreenState
    extends ConsumerState<MerchantIdentityEditScreen> {
  // ── controllers ────────────────────────────────────────────────────────────
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _ownerEmailCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  DateTime? _selectedDob;
  bool _seeded = false;
  bool _saving = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _ownerEmailCtrl.dispose();
    _displayNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── seed once Firestore data is available ──────────────────────────────────
  void _seed(UserProfileBasics? basics, Merchant? merchant) {
    if (_seeded) return;
    if (basics == null && merchant == null) return;
    _seeded = true;
    _firstNameCtrl.text = basics?.firstName ?? '';
    _lastNameCtrl.text = basics?.lastName ?? '';
    _selectedDob = basics?.dateOfBirth;
    _displayNameCtrl.text = merchant?.displayName ?? merchant?.name ?? '';
    _phoneCtrl.text = merchant?.phone ?? '';
  }

  // ── DOB picker ─────────────────────────────────────────────────────────────
  Future<void> _pickDob() async {
    final now = DateTime.now();
    // Open on today; the picker clamps to max-allowed (today − 16y).
    final initial = _selectedDob ?? now;
    final picked = await showCupertinoDobPicker(
      context: context,
      initial: initial,
      minimum: DateTime(1920),
      maximum: DateTime(now.year - 16, now.month, now.day),
    );
    if (picked != null && mounted) setState(() => _selectedDob = picked);
  }

  // ── save ───────────────────────────────────────────────────────────────────
  Future<void> _save(String uid, String merchantId) async {
    final fn = _firstNameCtrl.text.trim();
    final ln = _lastNameCtrl.text.trim();
    final oe = _ownerEmailCtrl.text.trim();
    final dn = _displayNameCtrl.text.trim();
    final ph = _phoneCtrl.text.trim();

    if (fn.isEmpty) {
      _showError('Le prénom est requis.');
      return;
    }

    if (oe.isNotEmpty && !_isValidEmail(oe)) {
      _showError('L\'adresse e-mail professionnelle n\'est pas valide.');
      return;
    }

    setState(() => _saving = true);

    // Run both updates concurrently — they write to different documents.
    final results = await Future.wait([
      ref.read(auth_providers.updateClientBasicInfoProvider).call(
            uid: uid,
            firstName: fn,
            lastName: ln.isNotEmpty ? ln : null,
            dateOfBirth: _selectedDob,
            ownerEmail: oe.isNotEmpty ? oe : null,
          ),
      if (merchantId.isNotEmpty && (dn.isNotEmpty || ph.isNotEmpty))
        ref.read(merchantRepositoryProvider).updateMerchant(
              merchantId: merchantId,
              displayName: dn.isNotEmpty ? dn : null,
              phone: ph.isNotEmpty ? ph : null,
            ),
    ]);

    if (!mounted) return;
    setState(() => _saving = false);

    final hasError = results.any((r) => r.isLeft);
    if (hasError) {
      final msg = results
          .where((r) => r.isLeft)
          .map((r) => r.leftOrNull?.message ?? 'Erreur inconnue')
          .join(' — ');
      _showError(msg);
      return;
    }

    await refreshUserProfileCacheWidget(
      ref,
      uid: uid,
      isMerchant: true,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profil mis à jour ✓',
          style: merchantSnackBarTextOnGold(),
        ),
        backgroundColor: MerchantColors.gold,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.onBack?.call();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: merchantSnackBarTextOnWarmAccent()),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static bool _isValidEmail(String v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(auth_providers.authStateProvider);
    final uid = authState is Authenticated ? authState.user.id : '';

    final basicsAsync = ref.watch(auth_providers.userProfileBasicsProvider(uid));
    final merchantAsync =
        ref.watch(merchant_providers.currentMerchantForOwnerProvider);

    final basics = basicsAsync.valueOrNull;
    final merchant = merchantAsync.valueOrNull;
    final authEmail =
        authState is Authenticated ? (authState.user.email ?? '') : '';
    final merchantId = merchant?.id ?? '';

    // Seed controllers once data lands.
    _seed(basics, merchant);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: MerchantColors.bgMain,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) widget.onBack?.call();
          },
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: (basicsAsync.isLoading && basics == null) ||
                        (merchantAsync.isLoading && merchant == null)
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: MerchantColors.gold,
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 24,
                          bottom:
                              MediaQuery.of(context).padding.bottom + 40,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionLabel('Identité du gérant'),
                            const SizedBox(height: 14),
                            _field(
                              controller: _firstNameCtrl,
                              label: 'Prénom',
                              hint: 'Jean',
                              icon: Icons.person_outline,
                              textCapitalization:
                                  TextCapitalization.words,
                            ),
                            const SizedBox(height: 12),
                            _field(
                              controller: _lastNameCtrl,
                              label: 'Nom',
                              hint: 'Dupont',
                              icon: Icons.person_outline,
                              textCapitalization:
                                  TextCapitalization.words,
                            ),
                            const SizedBox(height: 12),
                            _dobRow(),
                            const SizedBox(height: 12),
                            _field(
                              controller: _ownerEmailCtrl,
                              label: 'E-mail professionnel personnel',
                              hint: 'jean.dupont@exemple.fr',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              helperText:
                                  'E-mail de facturation ou de contact direct (facultatif)',
                            ),
                            const SizedBox(height: 28),
                            _sectionLabel('Informations commerciales'),
                            const SizedBox(height: 14),
                            _field(
                              controller: _displayNameCtrl,
                              label: 'Nom commercial',
                              hint: 'Boulangerie Dupont',
                              icon: Icons.storefront_outlined,
                              textCapitalization:
                                  TextCapitalization.words,
                            ),
                            const SizedBox(height: 12),
                            _field(
                              controller: _phoneCtrl,
                              label: 'Téléphone du commerce',
                              hint: '+33 6 12 34 56 78',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 12),
                            _readOnlyField(
                              label: 'E-mail de connexion',
                              value: authEmail,
                              icon: Icons.lock_outline,
                              note:
                                  'Modifiable uniquement via le support Yuztoo',
                            ),
                            const SizedBox(height: 32),
                            _saveButton(uid, merchantId),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── sub-widgets ────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: MerchantColors.bgHeader,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: const BoxDecoration(
            color: MerchantColors.bgHeader,
            border: Border(
              bottom: BorderSide(
                color: Color(0xFF1E3A5F),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: MerchantColors.textWhite, size: 20),
                onPressed: widget.onBack,
              ),
              Expanded(
                child: Text(
                  'Informations personnelles',
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: MerchantColors.textWhite,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: MerchantColors.gold,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: MerchantColors.textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: GoogleFonts.outfit(
              fontSize: 15, color: MerchantColors.textWhite),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(
                fontSize: 14,
                color: MerchantColors.textGrey.withValues(alpha: 0.6)),
            prefixIcon: Icon(icon,
                color: MerchantColors.textGrey, size: 18),
            helperText: helperText,
            helperStyle: GoogleFonts.outfit(
                fontSize: 11,
                color: MerchantColors.textGrey.withValues(alpha: 0.7)),
            helperMaxLines: 2,
            filled: true,
            fillColor: MerchantColors.inputFill,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1E3A5F)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: MerchantColors.gold, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dobRow() {
    final dob = _selectedDob;
    final dobText = dob != null
        ? '${dob.day.toString().padLeft(2, '0')}/'
            '${dob.month.toString().padLeft(2, '0')}/'
            '${dob.year}'
        : 'JJ/MM/AAAA';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date de naissance',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: MerchantColors.textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickDob,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: MerchantColors.bgHeader,
              borderRadius: BorderRadius.circular(12),
              border: const Border.fromBorderSide(
                BorderSide(color: Color(0xFF1E3A5F)),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.cake_outlined,
                    color: MerchantColors.textGrey, size: 18),
                const SizedBox(width: 12),
                Text(
                  dobText,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: dob != null
                        ? MerchantColors.textWhite
                        : MerchantColors.textGrey.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    color: MerchantColors.textGrey, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _readOnlyField({
    required String label,
    required String value,
    required IconData icon,
    String? note,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: MerchantColors.textGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: MerchantColors.bgHeader.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.fromBorderSide(
              BorderSide(
                  color: const Color(0xFF1E3A5F).withValues(alpha: 0.5)),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon,
                  color: MerchantColors.textGrey.withValues(alpha: 0.6),
                  size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value.isEmpty ? '—' : value,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: MerchantColors.textGrey.withValues(alpha: 0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.lock_outline,
                  color: MerchantColors.textGrey, size: 16),
            ],
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: 4),
          Text(
            note,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: MerchantColors.textGrey.withValues(alpha: 0.65),
            ),
          ),
        ],
      ],
    );
  }

  Widget _saveButton(String uid, String merchantId) {
    final isReady = uid.isNotEmpty && merchantId.isNotEmpty;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: (_saving || !isReady) ? null : () => _save(uid, merchantId),
        style: ElevatedButton.styleFrom(
          backgroundColor: MerchantColors.gold,
          foregroundColor: MerchantColors.bgHeader,
          disabledBackgroundColor:
              MerchantColors.gold.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _saving
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: MerchantColors.bgHeader,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'Enregistrer',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
