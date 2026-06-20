import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/debug/nfc_debug_flags.dart';
import '../../../../core/debug/nfc_debug_ui_helpers.dart';
import '../../../../core/shared/constants/merchant_colors.dart';
import '../../../client_home/application/providers.dart';
import '../../../merchant/application/providers.dart' as merchant_providers;
import '../../../merchant/domain/entities/merchant.dart';
import '../../../store_profile/application/providers.dart'
    as store_profile_providers;
import '../../application/nfc_debug_passage_emulator.dart';
import '../../application/nfc_debug_scenarios.dart';

/// Full NFC debug emulator — tag read/write + forced vitrine funnel UI.
Future<void> showNfcDebugEmulatorSheet(
  BuildContext context, {
  required void Function(String merchantId) onNavigateToVitrine,
  String? initialMerchantId,
  int initialTabIndex = 0,
}) {
  assert(kNfcDebugEnabled);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MerchantColors.bgMain,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _NfcDebugEmulatorSheet(
      onNavigateToVitrine: onNavigateToVitrine,
      initialMerchantId: initialMerchantId,
      initialTabIndex: initialTabIndex,
    ),
  );
}

class _NfcDebugEmulatorSheet extends ConsumerStatefulWidget {
  const _NfcDebugEmulatorSheet({
    required this.onNavigateToVitrine,
    this.initialMerchantId,
    this.initialTabIndex = 0,
  });

  final void Function(String merchantId) onNavigateToVitrine;
  final String? initialMerchantId;
  final int initialTabIndex;

  @override
  ConsumerState<_NfcDebugEmulatorSheet> createState() =>
      _NfcDebugEmulatorSheetState();
}

class _NfcDebugEmulatorSheetState extends ConsumerState<_NfcDebugEmulatorSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final TextEditingController _merchantIdCtrl;
  int? _selectedRead;
  int? _selectedWrite;
  int? _selectedFunnel;
  NfcDebugPassagePreflight? _passagePreflight;
  bool _passagePreflightLoading = false;
  String? _passageDryRunSummary;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
    _tabs.addListener(_onTabChanged);
    _merchantIdCtrl = TextEditingController(
      text: widget.initialMerchantId ?? '',
    );
    if (widget.initialTabIndex == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshPassagePreflight();
      });
    }
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    _merchantIdCtrl.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    if (_tabs.index == 3) {
      _refreshPassagePreflight();
    }
  }

  Future<void> _refreshPassagePreflight() async {
    setState(() {
      _passagePreflightLoading = true;
      _passageDryRunSummary = null;
    });
    final preflight = await NfcDebugPassageEmulator.preflight(
      ref,
      _merchantIdCtrl.text,
    );
    if (!mounted) return;
    setState(() {
      _passagePreflight = preflight;
      _passagePreflightLoading = false;
    });
  }

  Future<void> _runPassageDryRun() async {
    final merchantId = _merchantIdOrWarn();
    if (merchantId == null) return;
    setState(() => _passageDryRunSummary = 'Calcul en cours…');
    final result = await NfcDebugPassageEmulator.runRealPassageInProcess(
      ref: ref,
      merchantId: merchantId,
    );
    if (!mounted) return;
    setState(
      () => _passageDryRunSummary =
          NfcDebugPassageEmulator.resultSummary(result),
    );
  }

  void _runPassageNfcTap() {
    final merchantId = _merchantIdOrWarn();
    if (merchantId == null) return;
    if (_passagePreflight?.canEmulatePassage != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Préconditions non remplies — vérifiez la checklist.',
            style: GoogleFonts.outfit(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    NfcDebugPassageEmulator.emulateNfcTapNavigateToRealPassage(
      ref: ref,
      merchantId: merchantId,
      onNavigateToVitrine: widget.onNavigateToVitrine,
    );
    Navigator.of(context).pop();
  }

  String? _merchantIdOrWarn() {
    final id = _merchantIdCtrl.text.trim();
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saisissez ou choisissez un ID commerce',
            style: GoogleFonts.outfit(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }
    return id;
  }

  void _runTagRead() {
    if (_selectedRead == null) return;
    final scenario = NfcDebugScenarioCatalog.tagReadScenarioAt(_selectedRead!);
    final merchantId = _merchantIdCtrl.text.trim().isEmpty
        ? NfcDebugScenarioCatalog.placeholderMerchantId
        : _merchantIdCtrl.text.trim();
    final result = NfcDebugScenarioCatalog.tagReadResult(
      scenario,
      merchantId: merchantId,
    );
    Navigator.of(context).pop();
    applyNfcReadResult(
      context,
      result,
      onValidMerchantId: widget.onNavigateToVitrine,
    );
  }

  void _runTagWrite() {
    if (_selectedWrite == null) return;
    final scenario =
        NfcDebugScenarioCatalog.tagWriteScenarioAt(_selectedWrite!);
    final result = NfcDebugScenarioCatalog.tagWriteResult(scenario);
    Navigator.of(context).pop();
    applyNfcWriteResult(context, result);
  }

  void _runFunnel() {
    if (_selectedFunnel == null) return;
    final merchantId = _merchantIdOrWarn();
    if (merchantId == null) return;
    final scenario =
        NfcDebugScenarioCatalog.funnelScenarioAt(_selectedFunnel!);
    ref
        .read(store_profile_providers.nfcDebugForcedScanVisitResultProvider
            .notifier)
        .state = NfcDebugScenarioCatalog.funnelResult(scenario);
    Navigator.of(context).pop();
    widget.onNavigateToVitrine(merchantId);
  }

  void _runRealScanPath() {
    final merchantId = _merchantIdOrWarn();
    if (merchantId == null) return;
    ref.read(store_profile_providers.nfcDebugForcedScanVisitResultProvider
        .notifier)
      .state = null;
    Navigator.of(context).pop();
    widget.onNavigateToVitrine(merchantId);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final feedAsync = ref.watch(clientHomeFeedProvider);
    final merchantAsync =
        ref.watch(merchant_providers.currentMerchantForOwnerProvider);
    final carnet = feedAsync.valueOrNull?.merchants ?? <Merchant>[];
    final own = merchantAsync.valueOrNull;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  nfcDebugBanner(label: 'NFC DEBUG'),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Emulateur tags NFC',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: MerchantColors.textWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Text(
                'Tous les scenarios sans sticker : lecture, ecriture, funnel, passage Firestore.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: MerchantColors.textGrey,
                  height: 1.4,
                ),
              ),
            ),
            _MerchantIdField(
              controller: _merchantIdCtrl,
              ownMerchant: own,
              carnetMerchants: carnet,
              onPick: (id) => setState(() => _merchantIdCtrl.text = id),
            ),
            TabBar(
              controller: _tabs,
              labelStyle: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              indicatorColor: Colors.orange.shade400,
              labelColor: Colors.orange.shade200,
              unselectedLabelColor: MerchantColors.textGrey,
              tabs: const [
                Tab(text: 'Lecture'),
                Tab(text: 'Ecriture'),
                Tab(text: 'Funnel'),
                Tab(text: 'Passage'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _ScenarioList(
                    scrollController: scrollController,
                    options: NfcDebugScenarioCatalog.tagReadOptions()
                        .map((o) => (title: o.title, subtitle: o.subtitle))
                        .toList(),
                    selectedIndex: _selectedRead,
                    onSelect: (i) => setState(() => _selectedRead = i),
                    actionLabel: 'Emuler lecture NFC',
                    onAction: _selectedRead == null ? null : _runTagRead,
                    extraFooter: _RealScanFooter(onRun: _runRealScanPath),
                  ),
                  _ScenarioList(
                    scrollController: scrollController,
                    options: NfcDebugScenarioCatalog.tagWriteOptions()
                        .map((o) => (title: o.title, subtitle: o.subtitle))
                        .toList(),
                    selectedIndex: _selectedWrite,
                    onSelect: (i) => setState(() => _selectedWrite = i),
                    actionLabel: 'Emuler ecriture NFC',
                    onAction: _selectedWrite == null ? null : _runTagWrite,
                  ),
                  _FunnelScenarioList(
                    scrollController: scrollController,
                    selectedIndex: _selectedFunnel,
                    onSelect: (i) => setState(() => _selectedFunnel = i),
                    onAction: _selectedFunnel == null ? null : _runFunnel,
                  ),
                  _PassageNfcTab(
                    scrollController: scrollController,
                    preflight: _passagePreflight,
                    loading: _passagePreflightLoading,
                    dryRunSummary: _passageDryRunSummary,
                    onRefresh: _refreshPassagePreflight,
                    onDryRun: _runPassageDryRun,
                    onEmulateTap: _runPassageNfcTap,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 12),
              child: Text(
                'debug ou --dart-define=SHOW_NFC_DEBUG=true',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: MerchantColors.textGrey.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MerchantIdField extends StatelessWidget {
  const _MerchantIdField({
    required this.controller,
    required this.ownMerchant,
    required this.carnetMerchants,
    required this.onPick,
  });

  final TextEditingController controller;
  final Merchant? ownMerchant;
  final List<Merchant> carnetMerchants;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            style: GoogleFonts.outfit(color: MerchantColors.textWhite),
            decoration: InputDecoration(
              labelText: 'ID commerce',
              labelStyle: GoogleFonts.outfit(color: MerchantColors.textGrey),
              filled: true,
              fillColor: MerchantColors.inputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (ownMerchant != null) ...[
            const SizedBox(height: 8),
            _Chip(
              label: ownMerchant!.displayName?.isNotEmpty == true
                  ? ownMerchant!.displayName!
                  : ownMerchant!.name,
              onTap: () => onPick(ownMerchant!.id),
            ),
          ],
          if (carnetMerchants.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final m in carnetMerchants.take(6))
                  _Chip(
                    label: m.displayName?.isNotEmpty == true
                        ? m.displayName!
                        : m.name,
                    onTap: () => onPick(m.id),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: GoogleFonts.outfit(fontSize: 12)),
      onPressed: onTap,
      backgroundColor: MerchantColors.bgHeader,
      side: BorderSide(color: MerchantColors.gold.withValues(alpha: 0.35)),
    );
  }
}

class _ScenarioList extends StatelessWidget {
  const _ScenarioList({
    required this.scrollController,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
    required this.actionLabel,
    required this.onAction,
    this.extraFooter,
  });

  final ScrollController scrollController;
  final List<({String title, String subtitle})> options;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final String actionLabel;
  final VoidCallback? onAction;
  final Widget? extraFooter;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      children: [
        for (var i = 0; i < options.length; i++)
          _ScenarioTile(
            title: options[i].title,
            subtitle: options[i].subtitle,
            selected: selectedIndex == i,
            onTap: () => onSelect(i),
          ),
        if (extraFooter != null) ...[
          const SizedBox(height: 16),
          extraFooter!,
        ],
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.nfc_rounded, size: 20),
            label: Text(
              actionLabel,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _FunnelScenarioList extends StatelessWidget {
  const _FunnelScenarioList({
    required this.scrollController,
    required this.selectedIndex,
    required this.onSelect,
    required this.onAction,
  });

  final ScrollController scrollController;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final options = NfcDebugScenarioCatalog.funnelOptions();
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      children: [
        for (var i = 0; i < options.length; i++)
          _ScenarioTile(
            title: options[i].title,
            subtitle: options[i].subtitle,
            footnote: options[i].precondition,
            selected: selectedIndex == i,
            onTap: () => onSelect(i),
          ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.storefront_rounded, size: 20),
            label: Text(
              'Ouvrir vitrine + scenario force',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _PassageNfcTab extends StatelessWidget {
  const _PassageNfcTab({
    required this.scrollController,
    required this.preflight,
    required this.loading,
    required this.dryRunSummary,
    required this.onRefresh,
    required this.onDryRun,
    required this.onEmulateTap,
  });

  final ScrollController scrollController;
  final NfcDebugPassagePreflight? preflight;
  final bool loading;
  final String? dryRunSummary;
  final VoidCallback onRefresh;
  final VoidCallback onDryRun;
  final VoidCallback onEmulateTap;

  @override
  Widget build(BuildContext context) {
    final p = preflight;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      children: [
        Text(
          'Simule un tap NFC sur la vitrine et enregistre un vrai passage '
          'dans Firestore (sans forçage UI).',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: MerchantColors.textGrey,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: loading ? null : onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'Actualiser checklist',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (p != null) ...[
          for (final check in p.checks)
            _PassageCheckRow(check: check),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MerchantColors.bgHeader,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: MerchantColors.gold.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Résultat attendu',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade200,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p.expectedOutcome,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: MerchantColors.textWhite,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (dryRunSummary != null) ...[
          const SizedBox(height: 12),
          Text(
            'Dry-run (sans navigation)',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: MerchantColors.textGrey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dryRunSummary!,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textWhite,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: loading ? null : onDryRun,
          style: OutlinedButton.styleFrom(
            foregroundColor: MerchantColors.gold,
            side: BorderSide(color: MerchantColors.gold.withValues(alpha: 0.5)),
          ),
          icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
          label: Text(
            'Dry-run ProcessVitrineScanVisit',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: p?.canEmulatePassage == true ? onEmulateTap : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              disabledBackgroundColor: Colors.grey.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.nfc_rounded, size: 20),
            label: Text(
              'Simuler tap NFC → passage réel (Firestore)',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _PassageCheckRow extends StatelessWidget {
  const _PassageCheckRow({required this.check});

  final NfcDebugPassageCheck check;

  @override
  Widget build(BuildContext context) {
    final color = check.ok ? Colors.green.shade400 : Colors.red.shade300;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            check.ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.label,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MerchantColors.textWhite,
                  ),
                ),
                if (check.detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    check.detail!,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: MerchantColors.textGrey,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RealScanFooter extends StatelessWidget {
  const _RealScanFooter({required this.onRun});

  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onRun,
      style: OutlinedButton.styleFrom(
        foregroundColor: MerchantColors.gold,
        side: BorderSide(color: MerchantColors.gold.withValues(alpha: 0.5)),
      ),
      child: Text(
        'Tag valide : funnel reel (sans forçage)',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ScenarioTile extends StatelessWidget {
  const _ScenarioTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.footnote,
  });

  final String title;
  final String subtitle;
  final String? footnote;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? Colors.orange.withValues(alpha: 0.12)
            : MerchantColors.bgHeader,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? Colors.orange.shade400
                    : MerchantColors.gold.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MerchantColors.textWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: MerchantColors.textGrey,
                    height: 1.35,
                  ),
                ),
                if (footnote != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    footnote!,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Colors.orange.shade200,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
