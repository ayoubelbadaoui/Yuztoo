import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../merchant/domain/entities/client_gratification_config.dart';
import '../application/providers.dart';

class ClientGratificationConfigScreen extends ConsumerStatefulWidget {
  const ClientGratificationConfigScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  ConsumerState<ClientGratificationConfigScreen> createState() =>
      _ClientGratificationConfigScreenState();
}

class _ClientGratificationConfigScreenState
    extends ConsumerState<ClientGratificationConfigScreen> {
  late ClientGratificationConfig _config;
  bool _seeded = false;
  bool _saving = false;

  void _seed(ClientGratificationConfig config) {
    if (_seeded) return;
    _seeded = true;
    _config = config;
  }

  Future<void> _save() async {
    final merchantId = ref.read(currentMerchantIdProvider);
    if (merchantId == null) return;

    setState(() => _saving = true);
    final result = await ref
        .read(updateGratificationConfigProvider)
        .call(merchantId: merchantId, config: _config);
    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(f.message, style: GoogleFonts.outfit()),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      ),
      (_) {
        ref.invalidate(currentMerchantForOwnerProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Configuration enregistrée',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
            backgroundColor: MerchantColors.gold,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final merchantAsync = ref.watch(currentMerchantForOwnerProvider);
    merchantAsync.whenData((merchant) {
      if (merchant != null) _seed(merchant.effectiveGratificationConfig);
    });

    if (!_seeded) {
      _seed(ClientGratificationConfig.defaults);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: MerchantColors.bgMain,
        systemNavigationBarIconBrightness: Brightness.light,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  MediaQuery.of(context).padding.bottom + 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Seuils de passage'),
                    const SizedBox(height: 6),
                    Text(
                      'Définissez combien de passages validés sont nécessaires pour atteindre chaque niveau.',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: MerchantColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ThresholdRow(
                      tier: _config.nouveauLabel,
                      color: Colors.blueGrey,
                      icon: Icons.star_outline_rounded,
                      description:
                          '0 — ${_config.habituelThreshold - 1} passages',
                    ),
                    const SizedBox(height: 12),
                    _ThresholdRow(
                      tier: _config.habituelLabel,
                      color: Colors.amber,
                      icon: Icons.star_half_rounded,
                      description:
                          '${_config.habituelThreshold} — ${_config.vipThreshold - 1} passages',
                      trailing: _IntStepper(
                        value: _config.habituelThreshold,
                        min: 1,
                        max: _config.vipThreshold - 1,
                        onChanged: (v) => setState(
                          () => _config =
                              _config.copyWith(habituelThreshold: v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ThresholdRow(
                      tier: _config.vipLabel,
                      color: MerchantColors.gold,
                      icon: Icons.star_rounded,
                      description: '≥ ${_config.vipThreshold} passages',
                      trailing: _IntStepper(
                        value: _config.vipThreshold,
                        min: _config.habituelThreshold + 1,
                        max: 200,
                        onChanged: (v) => setState(
                          () => _config = _config.copyWith(vipThreshold: v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _sectionLabel('Inactivité'),
                    const SizedBox(height: 14),
                    _SwitchRow(
                      label: 'Inactif après',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _IntStepper(
                            value: _config.inactifAfterDays,
                            min: 14,
                            max: 365,
                            step: 7,
                            onChanged: (v) => setState(
                              () => _config =
                                  _config.copyWith(inactifAfterDays: v),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'jours',
                            style: GoogleFonts.outfit(
                              color: MerchantColors.textGrey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _sectionLabel('Visibilité client'),
                    const SizedBox(height: 6),
                    Text(
                      'Autoriser les clients à voir leur niveau de fidélité sur votre vitrine.',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: MerchantColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SwitchRow(
                      label: 'Afficher le niveau aux clients',
                      value: _config.showTierToClient,
                      onChanged: (v) => setState(
                        () => _config =
                            _config.copyWith(showTierToClient: v),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Paint behind the status bar (battery / clock area) — not white.
    return ColoredBox(
      color: MerchantColors.bgHeader,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderStronger),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onBack ?? () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: MerchantColors.gold, width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: MerchantColors.gold,
                      size: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Gratification client',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
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

  Widget _sectionLabel(String text) => Text(
        text.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: MerchantColors.textGrey,
          letterSpacing: 0.8,
        ),
      );

  Widget _buildSaveButton() => GestureDetector(
        onTap: _saving ? null : _save,
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [MerchantColors.gold, Color(0xFFD4AF37)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: MerchantColors.gold.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: MerchantColors.bgHeader,
                    ),
                  )
                : Text(
                    'Enregistrer',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: MerchantColors.bgHeader,
                    ),
                  ),
          ),
        ),
      );
}

class _ThresholdRow extends StatelessWidget {
  const _ThresholdRow({
    required this.tier,
    required this.color,
    required this.icon,
    required this.description,
    this.trailing,
  });

  final String tier;
  final Color color;
  final IconData icon;
  final String description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MerchantColors.bgHeader,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MerchantColors.gold.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier,
                  style: GoogleFonts.outfit(
                    color: MerchantColors.textWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    color: MerchantColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    this.value,
    this.onChanged,
    this.trailing,
  });

  final String label;
  final bool? value;
  final ValueChanged<bool>? onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MerchantColors.bgHeader,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MerchantColors.gold.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: MerchantColors.textWhite,
                fontSize: 14,
              ),
            ),
          ),
          if (trailing != null)
            trailing!
          else if (value != null && onChanged != null)
            GestureDetector(
              onTap: () => onChanged!(!value!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 48,
                height: 28,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color:
                      value! ? MerchantColors.gold : const Color(0xFF444444),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  alignment:
                      value! ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
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

class _IntStepper extends StatelessWidget {
  const _IntStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(
          Icons.remove_rounded,
          value > min
              ? () => onChanged((value - step).clamp(min, max))
              : null,
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 34,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: MerchantColors.textWhite,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 6),
        _btn(
          Icons.add_rounded,
          value < max ? () => onChanged((value + step).clamp(min, max)) : null,
        ),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onTap != null
                ? MerchantColors.gold.withValues(alpha: 0.15)
                : MerchantColors.gold.withValues(alpha: 0.05),
            border: Border.all(
              color: onTap != null
                  ? MerchantColors.gold.withValues(alpha: 0.5)
                  : MerchantColors.gold.withValues(alpha: 0.15),
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: onTap != null
                ? MerchantColors.gold
                : MerchantColors.gold.withValues(alpha: 0.3),
          ),
        ),
      );
}
