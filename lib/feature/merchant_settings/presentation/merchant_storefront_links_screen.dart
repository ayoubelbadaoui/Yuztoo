import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../merchant/domain/entities/merchant_storefront_link.dart';
import '../application/providers.dart';
import '../../store_profile/application/providers.dart'
    as store_profile_providers;

/// Lets merchants add custom vitrine entries (reservation link, menu, etc.).
class MerchantStorefrontLinksScreen extends ConsumerStatefulWidget {
  const MerchantStorefrontLinksScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  static const int maxLinks = 8;

  @override
  ConsumerState<MerchantStorefrontLinksScreen> createState() =>
      _MerchantStorefrontLinksScreenState();
}

class _MerchantStorefrontLinksScreenState
    extends ConsumerState<MerchantStorefrontLinksScreen> {
  static const _overlay = SystemUiOverlayStyle(
    statusBarColor: MerchantColors.bgHeader,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: MerchantColors.bgMain,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  final List<_LinkDraft> _drafts = [];
  bool _seeded = false;
  bool _saving = false;

  void _seed(List<MerchantStorefrontLink> links) {
    if (_seeded) return;
    _seeded = true;
    _drafts
      ..clear()
      ..addAll(
        links.map(
          (l) => _LinkDraft(
            labelCtrl: TextEditingController(text: l.label),
            valueCtrl: TextEditingController(text: l.value),
          ),
        ),
      );
  }

  @override
  void dispose() {
    for (final d in _drafts) {
      d.labelCtrl.dispose();
      d.valueCtrl.dispose();
    }
    super.dispose();
  }

  void _addLink() {
    if (_drafts.length >= MerchantStorefrontLinksScreen.maxLinks) {
      _snack('Maximum ${MerchantStorefrontLinksScreen.maxLinks} liens.');
      return;
    }
    setState(() {
      _drafts.add(
        _LinkDraft(
          labelCtrl: TextEditingController(),
          valueCtrl: TextEditingController(),
        ),
      );
    });
  }

  void _removeLink(int index) {
    setState(() {
      final removed = _drafts.removeAt(index);
      removed.labelCtrl.dispose();
      removed.valueCtrl.dispose();
    });
  }

  List<MerchantStorefrontLink> _collectLinks() {
    return _drafts
        .map(
          (d) => MerchantStorefrontLink(
            label: d.labelCtrl.text,
            value: d.valueCtrl.text,
          ),
        )
        .where((l) => l.isValid)
        .toList(growable: false);
  }

  Future<void> _save() async {
    final merchantId = ref.read(currentMerchantIdProvider);
    if (merchantId == null) return;

    for (final d in _drafts) {
      final hasLabel = d.labelCtrl.text.trim().isNotEmpty;
      final hasValue = d.valueCtrl.text.trim().isNotEmpty;
      if (hasLabel != hasValue) {
        _snack('Renseignez le nom et le contenu pour chaque lien.');
        return;
      }
    }

    setState(() => _saving = true);
    final result = await ref.read(updateMerchantStorefrontLinksProvider).call(
          merchantId: merchantId,
          links: _collectLinks(),
        );
    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (f) => _snack(f.message, error: true),
      (_) {
        ref.invalidate(currentMerchantForOwnerProvider);
        ref.invalidate(store_profile_providers.storeProfilePageDataProvider);
        _snack('Liens enregistrés', success: true);
      },
    );
  }

  void _snack(String msg, {bool error = false, bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: error
            ? Colors.red.shade700
            : success
                ? const Color(0xFF1B7A4B)
                : MerchantColors.navyCard,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final merchantAsync = ref.watch(currentMerchantForOwnerProvider);
    merchantAsync.whenData((merchant) {
      if (merchant != null) _seed(merchant.storefrontLinks);
    });
    if (!_seeded) _seed(const []);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlay,
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    24,
                    8,
                    24,
                    MediaQuery.paddingOf(context).bottom + 24,
                  ),
                  children: [
                    Text(
                      'Ajoutez des liens ou infos visibles sur votre vitrine '
                      '(réservation, carte, réseaux sociaux…). Les URLs '
                      's\'ouvrent au tap.',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: MerchantColors.textGrey,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_drafts.isEmpty)
                      _emptyHint()
                    else
                      ...List.generate(_drafts.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _linkCard(_drafts[i], i),
                        );
                      }),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _addLink,
                      icon: const Icon(Icons.add_link_rounded, size: 20),
                      label: Text(
                        'Ajouter un lien',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MerchantColors.gold,
                        side: BorderSide(
                          color: MerchantColors.gold.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      color: MerchantColors.bgHeader,
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          Expanded(
            child: Text(
              'Liens personnalisés',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: MerchantColors.gold,
                    ),
                  )
                : Text(
                    'Enregistrer',
                    style: GoogleFonts.outfit(
                      color: MerchantColors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHint() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MerchantColors.gold.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        'Aucun lien pour le moment. Exemple : « Réserver une table » → '
        'https://…',
        style: GoogleFonts.outfit(
          fontSize: 13,
          color: MerchantColors.textGrey,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _linkCard(_LinkDraft draft, int index) {
    final preview = draft.valueCtrl.text.trim();
    final isUrl = MerchantStorefrontLink.looksLikeUrl(preview);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MerchantColors.gold.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Lien ${index + 1}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: MerchantColors.gold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _saving ? null : () => _removeLink(index),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: MerchantColors.textGrey, size: 20),
                tooltip: 'Supprimer',
              ),
            ],
          ),
          _field(
            controller: draft.labelCtrl,
            label: 'Nom affiché',
            hint: 'Réservation en ligne',
            icon: Icons.label_outline_rounded,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _field(
            controller: draft.valueCtrl,
            label: 'Lien ou texte',
            hint: 'https://… ou info libre',
            icon: Icons.link_rounded,
            keyboardType: TextInputType.url,
            onChanged: (_) => setState(() {}),
          ),
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              isUrl
                  ? 'Sera cliquable sur la vitrine'
                  : 'Affiché comme texte (non cliquable)',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: isUrl
                    ? const Color(0xFF6BCB9A)
                    : MerchantColors.textGrey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: MerchantColors.textGrey,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(
              color: MerchantColors.textGrey.withValues(alpha: 0.7),
            ),
            prefixIcon: Icon(icon, color: MerchantColors.gold, size: 20),
            filled: true,
            fillColor: MerchantColors.bgMain,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _LinkDraft {
  _LinkDraft({
    required this.labelCtrl,
    required this.valueCtrl,
  });

  final TextEditingController labelCtrl;
  final TextEditingController valueCtrl;
}
