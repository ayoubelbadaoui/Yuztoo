import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../auth/core/application/providers.dart' show authStateProvider;
import '../../auth/core/application/state/auth_state.dart';
import '../../auth/signup/application/providers.dart'
    show deleteCurrentUserProvider;

/// "Confidentialité des données" screen.
class DataPrivacyScreen extends ConsumerStatefulWidget {
  const DataPrivacyScreen({super.key, this.onBack, this.onAccountDeleted});

  final VoidCallback? onBack;
  final VoidCallback? onAccountDeleted;

  @override
  ConsumerState<DataPrivacyScreen> createState() => _DataPrivacyScreenState();
}

class _DataPrivacyScreenState extends ConsumerState<DataPrivacyScreen> {
  bool _analyticsConsent = false;
  bool _loadingConsent = true;
  bool _savingConsent = false;
  bool _requestingExport = false;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadConsent();
  }

  Future<void> _loadConsent() async {
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) {
      setState(() => _loadingConsent = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authState.user.id)
          .get();
      final consent = doc.data()?['analyticsConsent'] as bool? ?? false;
      if (mounted) {
        setState(() {
          _analyticsConsent = consent;
          _loadingConsent = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingConsent = false);
    }
  }

  Future<void> _toggleConsent(bool value) async {
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) return;
    setState(() {
      _analyticsConsent = value;
      _savingConsent = true;
    });
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(authState.user.id)
          .set({'analyticsConsent': value}, SetOptions(merge: true));
    } catch (_) {
      if (mounted) setState(() => _analyticsConsent = !value);
    } finally {
      if (mounted) setState(() => _savingConsent = false);
    }
  }

  Future<void> _requestExport() async {
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) return;
    setState(() => _requestingExport = true);
    try {
      await FirebaseFirestore.instance
          .collection('data_export_requests')
          .doc(authState.user.id)
          .set({
        'uid': authState.user.id,
        'email': authState.user.email ?? '',
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: MerchantColors.navyCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline,
                  color: MerchantColors.gold, size: 48),
              const SizedBox(height: 16),
              Text(
                'Votre demande a été enregistrée.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Vous recevrez un email sous 48h.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 13, color: MerchantColors.textGrey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('D\'accord',
                  style: GoogleFonts.outfit(color: MerchantColors.gold)),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la demande',
              style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _requestingExport = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    FocusScope.of(context).unfocus();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DeleteConfirmSheet(
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isDeletingAccount = true);
    try {
      await ref.read(deleteCurrentUserProvider).call();
      // Auth-state change may have already navigated away; only call back
      // if the route is still active to avoid popping a deactivated context.
      if (mounted && ModalRoute.of(context)?.isActive == true) {
        widget.onAccountDeleted?.call();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reconnectez-vous avant de supprimer le compte',
              style: GoogleFonts.outfit(color: Colors.white)),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    MediaQuery.of(context).padding.bottom + 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Consentements'),
                      const SizedBox(height: 10),
                      _buildConsentCard(),
                      const SizedBox(height: 28),
                      _sectionLabel('Vos données'),
                      const SizedBox(height: 10),
                      _buildInfoItems(),
                      const SizedBox(height: 28),
                      _sectionLabel('Export'),
                      const SizedBox(height: 10),
                      _buildExportCard(),
                      const SizedBox(height: 28),
                      // User feedback: "Zone dangereuse" reads as a scary
                      // warning label and scares users away from a totally
                      // normal "delete account" action. Renamed to a plain
                      // descriptive header.
                      _sectionLabel('Suppression du compte'),
                      const SizedBox(height: 10),
                      _buildDeleteCard(),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: MerchantColors.bgHeader,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: MerchantColors.bgHeader,
            border: Border(
              bottom: BorderSide(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onBack,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: MerchantColors.gold, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Confidentialité des données',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String title) => Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: MerchantColors.textGrey,
          letterSpacing: 0.8,
        ),
      );

  Widget _buildConsentCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: MerchantColors.gold.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistiques anonymisées',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Partager mes stats anonymisées avec Yuztoo pour améliorer le service.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: MerchantColors.textGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _loadingConsent
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: MerchantColors.gold, strokeWidth: 2),
                )
              : Switch(
                  value: _analyticsConsent,
                  onChanged: _savingConsent ? null : _toggleConsent,
                  activeThumbColor: MerchantColors.gold,
                  trackColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? MerchantColors.gold.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildInfoItems() {
    const items = [
      (Icons.lock_outline, 'Données chiffrées',
          'Stockées de manière sécurisée sur les serveurs de Firebase.'),
      (Icons.person_off_outlined, 'Aucune revente',
          'Jamais partagées ou revendues à des tiers.'),
      (Icons.delete_outline, 'Droit à l\'effacement',
          'Supprimer votre compte depuis "Suppression du compte" ci-dessous.'),
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: MerchantColors.gold.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.$1,
                        color: MerchantColors.gold, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$2,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.$3,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: MerchantColors.textGrey,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildExportCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: MerchantColors.gold.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: MerchantColors.gold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.download_outlined,
                color: MerchantColors.gold, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export de données',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Recevez vos données par email sous 48h.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: MerchantColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _requestingExport ? null : _requestExport,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: MerchantColors.gold),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _requestingExport
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: MerchantColors.gold),
                      )
                    : Text(
                        'Demander',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: MerchantColors.gold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.delete_forever_rounded,
                color: Colors.red.shade400, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supprimer mon compte',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade300,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Définitif — toutes les données seront perdues',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: MerchantColors.textGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isDeletingAccount ? null : _confirmDeleteAccount,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _isDeletingAccount
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red.shade400,
                        ),
                      )
                    : Text(
                        'Supprimer',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade400,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteConfirmSheet extends StatelessWidget {
  const _DeleteConfirmSheet({
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: MerchantColors.textGrey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.delete_forever_rounded, color: Colors.red.shade400, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'Supprimer le compte ?',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Cette action est irréversible. Votre compte, vos clients, promotions et données seront définitivement supprimés.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: MerchantColors.textGrey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: GestureDetector(
              onTap: onConfirm,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'Oui, supprimer définitivement',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: GestureDetector(
              onTap: onCancel,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: MerchantColors.gold.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    'Annuler',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: MerchantColors.textGrey,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
