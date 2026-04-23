import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../auth/core/application/providers.dart'
    show authStateProvider, updateAuthUserProfileProvider;
import '../../auth/core/application/state/auth_state.dart';
import '../../auth/login/application/providers.dart'
    show sendPasswordResetEmailProvider;
import '../../auth/signup/application/providers.dart'
    show deleteCurrentUserProvider;

/// Identification & Sécurité screen for the merchant account.
/// Allows editing display name, sending a password reset, and deleting the account.
class IdentificationSecurityScreen extends ConsumerStatefulWidget {
  const IdentificationSecurityScreen(
      {super.key, this.onBack, this.onAccountDeleted});

  final VoidCallback? onBack;
  final VoidCallback? onAccountDeleted;

  @override
  ConsumerState<IdentificationSecurityScreen> createState() =>
      _IdentificationSecurityScreenState();
}

class _IdentificationSecurityScreenState
    extends ConsumerState<IdentificationSecurityScreen> {
  late TextEditingController _nameCtrl;
  final FocusNode _nameFocus = FocusNode();

  bool _editingName = false;
  bool _isSavingName = false;
  bool _nameEmpty = false;

  bool _isSendingReset = false;
  bool _resetSent = false;

  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authStateProvider);
    _nameCtrl = TextEditingController(
      text:
          authState is Authenticated ? (authState.user.displayName ?? '') : '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _startEditName() {
    setState(() {
      _editingName = true;
      _nameEmpty = false;
    });
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _nameFocus.requestFocus());
  }

  void _cancelEditName() {
    final authState = ref.read(authStateProvider);
    setState(() {
      _editingName = false;
      _nameEmpty = false;
      _nameCtrl.text =
          authState is Authenticated ? (authState.user.displayName ?? '') : '';
    });
    _nameFocus.unfocus();
  }

  Future<void> _saveName() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) {
      setState(() => _nameEmpty = true);
      return;
    }

    setState(() {
      _isSavingName = true;
      _nameEmpty = false;
    });
    final result =
        await ref.read(updateAuthUserProfileProvider).call(displayName: newName);
    if (!mounted) return;
    setState(() {
      _isSavingName = false;
      _editingName = false;
    });
    _nameFocus.unfocus();

    result.fold(
      (_) => _showSnack('Erreur lors de la mise à jour du nom', isError: true),
      (_) => _showSnack('Nom mis à jour'),
    );
  }

  Future<void> _sendPasswordReset() async {
    final authState = ref.read(authStateProvider);
    if (authState is! Authenticated) return;
    final email = authState.user.email;
    if (email == null || email.isEmpty) {
      _showSnack('Aucune adresse email associée à ce compte', isError: true);
      return;
    }

    setState(() => _isSendingReset = true);
    final result =
        await ref.read(sendPasswordResetEmailProvider).call(email: email);
    if (!mounted) return;
    setState(() {
      _isSendingReset = false;
      if (result.isRight) _resetSent = true;
    });

    result.fold(
      (_) => _showSnack('Erreur lors de l\'envoi de l\'email', isError: true),
      (_) {},
    );
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
      if (mounted) widget.onAccountDeleted?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeletingAccount = false);
      _showSnack(
        'Reconnectez-vous avant de supprimer le compte',
        isError: true,
      );
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        backgroundColor:
            isError ? Colors.red.shade700 : const Color(0xFF1B7A4B),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final email =
        authState is Authenticated ? (authState.user.email ?? '') : '';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: MerchantColors.bgMain,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: MerchantColors.bgMain,
          body: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    bottomInset + MediaQuery.of(context).padding.bottom + 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Identité'),
                      const SizedBox(height: 10),
                      _buildNameCard(),
                      const SizedBox(height: 28),
                      _sectionLabel('Mot de passe'),
                      const SizedBox(height: 10),
                      _buildPasswordCard(email),
                      const SizedBox(height: 28),
                      _sectionLabel('Zone dangereuse'),
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
                onTap: widget.onBack,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: MerchantColors.gold, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        color: MerchantColors.gold, size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Identification et sécurité',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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

  // ── name card ──────────────────────────────────────────────────────────────
  Widget _buildNameCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _editingName
              ? MerchantColors.gold.withValues(alpha: 0.6)
              : MerchantColors.gold.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline,
                  color: MerchantColors.gold, size: 18),
              const SizedBox(width: 10),
              Text(
                'Nom affiché',
                style: GoogleFonts.outfit(
                    fontSize: 12, color: MerchantColors.textGrey),
              ),
              const Spacer(),
              if (!_editingName)
                GestureDetector(
                  onTap: _startEditName,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.centerRight,
                    child: const Icon(Icons.edit_outlined,
                        color: MerchantColors.gold, size: 18),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_editingName) ...[
            TextField(
              controller: _nameCtrl,
              focusNode: _nameFocus,
              style: GoogleFonts.outfit(fontSize: 16, color: Colors.white),
              cursorColor: MerchantColors.gold,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                border: InputBorder.none,
                hintText: 'Votre nom complet',
                hintStyle: GoogleFonts.outfit(
                    color: MerchantColors.textGrey.withValues(alpha: 0.4)),
              ),
            ),
            if (_nameEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Le nom ne peut pas être vide',
                style: GoogleFonts.outfit(fontSize: 11, color: Colors.red),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _cancelEditName,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: MerchantColors.gold.withValues(alpha: 0.4)),
                      ),
                      child: Center(
                        child: Text(
                          'Annuler',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: MerchantColors.textGrey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _isSavingName ? null : _saveName,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [MerchantColors.gold, Color(0xFFD4AF37)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: _isSavingName
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: MerchantColors.bgHeader,
                                ),
                              )
                            : Text(
                                'Sauvegarder',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: MerchantColors.bgHeader,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              _nameCtrl.text.isEmpty ? 'Non défini' : _nameCtrl.text,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _nameCtrl.text.isEmpty
                    ? MerchantColors.textGrey.withValues(alpha: 0.5)
                    : Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── password card ──────────────────────────────────────────────────────────
  Widget _buildPasswordCard(String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _resetSent
              ? const Color(0xFF1B7A4B).withValues(alpha: 0.5)
              : MerchantColors.gold.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: (_resetSent
                      ? const Color(0xFF1B7A4B)
                      : MerchantColors.gold)
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _resetSent ? Icons.check_circle_outline : Icons.lock_reset_rounded,
              color: _resetSent ? const Color(0xFF4CAF50) : MerchantColors.gold,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _resetSent ? 'Email envoyé !' : 'Changer le mot de passe',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _resetSent
                      ? 'Vérifiez votre boîte $email'
                      : email.isNotEmpty
                          ? 'Envoi à $email'
                          : 'Email de réinitialisation',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: _resetSent
                        ? const Color(0xFF4CAF50)
                        : MerchantColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!_resetSent)
            GestureDetector(
              onTap: _isSendingReset ? null : _sendPasswordReset,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: MerchantColors.gold),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _isSendingReset
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: MerchantColors.gold,
                          ),
                        )
                      : Text(
                          'Envoyer',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
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

  // ── delete card ────────────────────────────────────────────────────────────
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
                  'Supprimer le compte',
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

// ── Delete confirmation bottom sheet ──────────────────────────────────────────

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
            child: Icon(Icons.delete_forever_rounded,
                color: Colors.red.shade400, size: 28),
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
