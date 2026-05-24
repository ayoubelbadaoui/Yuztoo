import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../../auth/core/application/providers.dart' as auth_providers;
import '../../../auth/core/application/state/auth_state.dart';
import '../../../merchant/domain/entities/loyalty_program_config.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../../storefront/presentation/widgets/storefront_colors.dart';
import '../../application/active_validation_providers.dart';
import '../../application/client_loyalty_providers.dart';
import '../../domain/entities/active_validation_request.dart';
import '../../domain/loyalty_passage_program_policy.dart';
import '../../infrastructure/active_validation_repository_provider.dart';

/// Modal bottom sheet for merchant passage validation. Form rules use the same
/// programme resolution as [ConfirmActiveValidation] (enrolled, else snapshot).
class ActiveValidationSheet extends ConsumerStatefulWidget {
  const ActiveValidationSheet({
    super.key,
    required this.merchant,
    required this.session,
  });

  final Merchant merchant;
  final ActiveValidationRequest session;

  @override
  ConsumerState<ActiveValidationSheet> createState() =>
      _ActiveValidationSheetState();
}

class _ActiveValidationSheetState extends ConsumerState<ActiveValidationSheet> {
  final TextEditingController _spendController = TextEditingController();
  bool _submitting = false;
  String? _error;

  LoyaltyProgramConfig get _config {
    final progress = ref
        .watch(
          merchantClientLoyaltyProgressProvider(
            (
              merchantId: widget.merchant.id,
              clientUid: widget.session.clientUid,
            ),
          ),
        )
        .valueOrNull;
    return resolveLoyaltyProgramForPassage(
      merchant: widget.merchant,
      session: widget.session,
      clientProgress: progress,
    );
  }

  bool get _spendRequired =>
      _config.triggerType == LoyaltyTriggerType.purchaseTotal ||
      _config.rewardKind == LoyaltyRewardKind.loyaltyPoints;

  bool get _spendOptional =>
      !_spendRequired && _config.optionalAskClientPurchaseAmount;

  bool get _spendVisible => _spendRequired || _spendOptional;

  double? get _minimumPerVisitEuros => (_config.minimumPerVisitEnabled &&
          _config.minimumPerVisitEuros != null &&
          _config.minimumPerVisitEuros! > 0)
      ? _config.minimumPerVisitEuros
      : null;

  @override
  void initState() {
    super.initState();
    // Best-effort: mark this session as 'opened' so the client banner copy
    // can transition from "en attente" to "le commerçant valide votre passage".
    // Don't block the UI on this — failure is silently swallowed in the repo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(activeValidationRepositoryProvider);
      repo.markOpened(
        merchantId: widget.merchant.id,
        clientUid: widget.session.clientUid,
      );
    });
  }

  @override
  void dispose() {
    _spendController.dispose();
    super.dispose();
  }

  String get _initials {
    final name = widget.session.clientDisplayName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts.first.isNotEmpty && parts.last.isNotEmpty) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String? get _photoUrl {
    final url = widget.session.clientPhotoUrl?.trim();
    if (url == null || url.isEmpty) return null;
    return url;
  }

  Widget _buildClientAvatar() {
    final url = _photoUrl;
    if (url != null) {
      return Image.network(
        url,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initialsAvatar(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: MerchantColors.gold.withValues(alpha: 0.7),
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      );
    }
    return _initialsAvatar();
  }

  Widget _initialsAvatar() {
    return Center(
      child: Text(
        _initials,
        style: GoogleFonts.outfit(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: MerchantColors.gold,
        ),
      ),
    );
  }

  String _rewardPreview() {
    final c = _config;
    switch (c.rewardKind) {
      case LoyaltyRewardKind.purchaseVoucher:
        if (c.purchaseVoucherUsesPercent) {
          return 'Bon d\'achat de ${c.purchaseVoucherValue.toStringAsFixed(0)} %';
        }
        return 'Bon d\'achat de ${c.purchaseVoucherValue.toStringAsFixed(0)} €';
      case LoyaltyRewardKind.discountPercent:
        return 'Remise -${c.discountNextPurchasePercent.toStringAsFixed(0)} % sur le prochain achat';
      case LoyaltyRewardKind.freeProduct:
        final label = (c.freeProductSummaryLabel ?? '').trim();
        return label.isEmpty ? 'Produit offert' : '$label offert';
      case LoyaltyRewardKind.loyaltyPoints:
        return '${c.pointsPerEuro.toStringAsFixed(1)} pt par € dépensé';
    }
  }

  String _triggerPreview() {
    switch (_config.triggerType) {
      case LoyaltyTriggerType.visitCount:
        return 'après ${_config.visitsRequired} passages';
      case LoyaltyTriggerType.purchaseTotal:
        return 'après ${_config.cumulativeSpendRequiredEuros.toStringAsFixed(0)} € d\'achats';
    }
  }

  double? _parseSpend() {
    final raw = _spendController.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  Future<void> _confirm() async {
    final spend = _parseSpend();
    if (_spendRequired && (spend == null || spend <= 0)) {
      setState(() => _error = 'Indiquez le montant de l\'achat.');
      return;
    }
    final min = _minimumPerVisitEuros;
    if (spend != null && spend > 0 && min != null && spend < min) {
      setState(
          () => _error = 'Minimum ${min.toStringAsFixed(0)} € par passage.');
      return;
    }
    // Use the live auth uid, not widget.merchant.ownerUid. The merchant entity
    // is loaded from the SDK and could be stale or tampered with locally; the
    // auth uid is the only identity Firebase will accept on the write anyway.
    final authState = ref.read(auth_providers.authStateProvider);
    if (authState is! Authenticated) {
      setState(() => _error = 'Session expirée. Reconnectez-vous.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    final useCase = ref.read(confirmActiveValidationProvider);
    final result = await useCase.call(
      actingOwnerUid: authState.user.id,
      merchant: widget.merchant,
      session: widget.session,
      declaredSpendEuros: spend,
    );
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() {
          _submitting = false;
          _error = failure.message;
        });
      },
      (_) {
        HapticFeedback.heavyImpact();
        Navigator.of(context).pop();
      },
    );
  }

  Future<void> _refuse() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    HapticFeedback.lightImpact();
    final useCase = ref.read(cancelActiveValidationProvider);
    await useCase.byMerchant(
      merchantId: widget.merchant.id,
      clientUid: widget.session.clientUid,
      reason: 'merchant_refused',
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  String get _docStreamKey =>
      '${widget.merchant.id}|${widget.session.clientUid}';

  @override
  Widget build(BuildContext context) {
    ref.listen(
      activeValidationSessionForDocProvider(_docStreamKey),
      (previous, next) {
        next.whenData((session) {
          if (!mounted) return;
          if (session != null && session.isCancelled) {
            Navigator.of(context).maybePop();
          }
        });
      },
    );

    return Container(
      decoration: const BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).padding.bottom + 28,
      ),
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
          // Avatar — photo from session (client vitrine request) or initials.
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: MerchantColors.gold.withValues(alpha: 0.15),
              border: Border.all(
                color: MerchantColors.gold.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildClientAvatar(),
          ),
          const SizedBox(height: 16),
          Text(
            'Validation de passage',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: MerchantColors.textGrey,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.session.clientDisplayName.isNotEmpty
                ? widget.session.clientDisplayName
                : 'Client',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: MerchantColors.textWhite,
            ),
          ),
          const SizedBox(height: 14),
          // Program chip
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: MerchantColors.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: MerchantColors.gold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              '${_rewardPreview()} ${_triggerPreview()}',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: MerchantColors.gold,
              ),
            ),
          ),
          if (_spendVisible) ...[
            const SizedBox(height: 22),
            _SpendField(
              controller: _spendController,
              required: _spendRequired,
              minimumPerVisitEuros: _minimumPerVisitEuros,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
          ] else
            const SizedBox(height: 22),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
              ),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 13, color: Colors.red.shade300),
              ),
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: GestureDetector(
              onTap: _submitting ? null : _confirm,
              child: Container(
                decoration: BoxDecoration(
                  color: _submitting
                      ? MerchantColors.gold.withValues(alpha: 0.4)
                      : MerchantColors.gold,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: StorefrontColors.navyDark,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Valider le passage',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: StorefrontColors.navyDark,
                          ),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _submitting ? null : _refuse,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Refuser',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: MerchantColors.textGrey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendField extends StatelessWidget {
  const _SpendField({
    required this.controller,
    required this.required,
    required this.minimumPerVisitEuros,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool required;
  final double? minimumPerVisitEuros;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required
              ? 'Montant de l\'achat (€)'
              : 'Montant de l\'achat (optionnel)',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: MerchantColors.textWhite,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: MerchantColors.textWhite),
          onChanged: onChanged,
          decoration: const InputDecoration(
            hintText: '0.00',
            hintStyle: TextStyle(color: MerchantColors.textGrey),
            suffixText: '€',
            suffixStyle: TextStyle(
              color: StorefrontColors.primaryGold,
              fontWeight: FontWeight.w600,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: MerchantColors.gold),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: StorefrontColors.primaryGold,
                width: 2,
              ),
            ),
          ),
        ),
        if (minimumPerVisitEuros != null) ...[
          const SizedBox(height: 6),
          Text(
            'Minimum ${minimumPerVisitEuros!.toStringAsFixed(0)} € requis.',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: MerchantColors.textGrey,
            ),
          ),
        ],
      ],
    );
  }
}
