import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../../client_list/application/providers.dart' as crm_providers;
import '../../../client_list/domain/entities/merchant_client_row.dart';
import '../../../merchant/domain/entities/merchant.dart';
import '../../../auth/core/application/providers.dart' as auth_providers;
import '../../../auth/core/application/state/auth_state.dart';
import '../../application/active_validation_providers.dart';
import '../../domain/entities/active_validation_request.dart';
import '../../infrastructure/active_validation_repository_provider.dart';
import '../../presentation/merchant_passage_validation_flow.dart';

bool get isMerchantPassageDebugEnabled =>
    kDebugMode ||
    const bool.fromEnvironment(
      'SHOW_PASSAGE_SIMULATOR',
      defaultValue: false,
    );

/// Debug: pick a client — simulates them tapping « Valider » on your vitrine.
Future<void> showMerchantPassageDebugSimulateSheet(
  BuildContext context, {
  required Merchant merchant,
}) {
  if (!isMerchantPassageDebugEnabled) return Future.value();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MerchantColors.bgMain,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _MerchantPassageDebugSimulateSheet(merchant: merchant),
  );
}

class _MerchantPassageDebugSimulateSheet extends ConsumerStatefulWidget {
  const _MerchantPassageDebugSimulateSheet({required this.merchant});

  final Merchant merchant;

  @override
  ConsumerState<_MerchantPassageDebugSimulateSheet> createState() =>
      _MerchantPassageDebugSimulateSheetState();
}

enum _PassageSimulateMode { vitrine, ble }

class _MerchantPassageDebugSimulateSheetState
    extends ConsumerState<_MerchantPassageDebugSimulateSheet> {
  final _clientUidCtrl = TextEditingController();
  bool _busy = false;
  _PassageSimulateMode _mode = _PassageSimulateMode.vitrine;

  @override
  void dispose() {
    _clientUidCtrl.dispose();
    super.dispose();
  }

  Future<void> _simulate(MerchantClientRow client) async {
    await _simulateWith(
      clientUid: client.clientUid,
      displayName: client.displayLabel,
      photoUrl: client.photoUrl,
    );
  }

  Future<void> _simulateManual() async {
    final uid = _clientUidCtrl.text.trim();
    if (uid.isEmpty) {
      _snack('Saisissez un UID client');
      return;
    }
    await _simulateWith(
      clientUid: uid,
      displayName: 'Client test',
    );
  }

  Future<void> _simulateWith({
    required String clientUid,
    required String displayName,
    String? photoUrl,
  }) async {
    if (_busy) return;
    final auth = ref.read(auth_providers.authStateProvider);
    if (auth is Authenticated && clientUid == auth.user.id) {
      _snack(
        'Choisissez l\'UID d\'un autre compte client (pas le vôtre). '
        'En solo, saisissez l\'UID d\'un second téléphone.',
      );
      return;
    }
    setState(() => _busy = true);
    final result = _mode == _PassageSimulateMode.ble
        ? await ref.read(simulateBleClientPassageProvider).call(
              merchant: widget.merchant,
              clientUid: clientUid,
              clientDisplayName: displayName,
              clientPhotoUrl: photoUrl,
            )
        : await ref.read(simulateClientActiveValidationProvider).call(
              merchant: widget.merchant,
              clientUid: clientUid,
              clientDisplayName: displayName,
              clientPhotoUrl: photoUrl,
            );
    if (!mounted) return;
    setState(() => _busy = false);
    await result.fold(
      (f) async => _snack(f.message),
      (_) async {
        if (!mounted) return;
        Navigator.of(context).pop();
        await _openValidationAfterSimulate(
          clientUid: clientUid,
          displayName: displayName,
        );
      },
    );
  }

  Future<void> _openValidationAfterSimulate({
    required String clientUid,
    required String displayName,
  }) async {
    ActiveValidationRequest? session;
    try {
      session = await ref
          .read(activeValidationRepositoryProvider)
          .watchClientSession(
            merchantId: widget.merchant.id,
            clientUid: clientUid,
          )
          .first;
    } catch (_) {
      session = null;
    }
    if (!mounted || session == null) {
      _snack('Session créée mais introuvable — réessayez.');
      return;
    }

    final opened = await openMerchantPassageValidation(
      ref: ref,
      context: context,
      merchant: widget.merchant,
      session: session,
    );
    if (!mounted) return;
    if (opened) {
      _snack(
        _mode == _PassageSimulateMode.ble
            ? 'Validation BLE simulée terminée'
            : 'Validation vitrine simulée terminée',
        success: true,
      );
    }
    if (!mounted) return;
    _snack('Validation vitrine simulée terminée', success: true);
  }

  void _snack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? Colors.green.shade800 : Colors.red.shade900,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync =
        ref.watch(crm_providers.merchantClientsProvider(widget.merchant.id));
    final clients = clientsAsync.valueOrNull ?? const <MerchantClientRow>[];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.paddingOf(context).bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _debugBadge(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Simuler demande client',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: MerchantColors.textWhite,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SegmentedButton<_PassageSimulateMode>(
                segments: const [
                  ButtonSegment(
                    value: _PassageSimulateMode.vitrine,
                    label: Text('Vitrine'),
                  ),
                  ButtonSegment(
                    value: _PassageSimulateMode.ble,
                    label: Text('BLE'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: _busy
                    ? null
                    : (s) => setState(() => _mode = s.first),
                style: ButtonStyle(
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return MerchantColors.bgMain;
                    }
                    return MerchantColors.textWhite;
                  }),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _mode == _PassageSimulateMode.ble
                    ? 'Comme si le client avait confirmé la connexion BLE. '
                        'Puis validez depuis l\'écran BLE ou la file d\'attente.'
                    : 'Comme si le client avait appuyé sur « Valider » après le scan. '
                        'Vous verrez la file d\'attente, l\'alerte et la feuille de validation.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: MerchantColors.textGrey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _clientUidCtrl,
                enabled: !_busy,
                style: GoogleFonts.outfit(color: MerchantColors.textWhite),
                decoration: InputDecoration(
                  labelText: 'UID client (optionnel)',
                  labelStyle:
                      GoogleFonts.outfit(color: MerchantColors.textGrey),
                  filled: true,
                  fillColor: MerchantColors.bgHeader,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: _busy ? null : _simulateManual,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade200,
                    side: BorderSide(color: Colors.orange.shade700),
                  ),
                  child: Text(
                    'Simuler avec cet UID',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Vos clients',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: MerchantColors.textGrey,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: clientsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: MerchantColors.gold),
                  ),
                  error: (_, __) => Center(
                    child: Text(
                      'Impossible de charger la liste',
                      style: GoogleFonts.outfit(color: MerchantColors.textGrey),
                    ),
                  ),
                  data: (_) {
                    if (clients.isEmpty) {
                      return Center(
                        child: Text(
                          'Aucun client — utilisez l\'UID ci-dessus',
                          style: GoogleFonts.outfit(
                            color: MerchantColors.textGrey,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: clients.length,
                      itemBuilder: (_, i) {
                        final c = clients[i];
                        return ListTile(
                          enabled: !_busy,
                          leading: CircleAvatar(
                            backgroundColor:
                                MerchantColors.gold.withValues(alpha: 0.2),
                            backgroundImage: c.photoUrl != null &&
                                    c.photoUrl!.isNotEmpty
                                ? NetworkImage(c.photoUrl!)
                                : null,
                            child: c.photoUrl == null || c.photoUrl!.isEmpty
                                ? Text(
                                    c.displayLabel.isNotEmpty
                                        ? c.displayLabel[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      color: MerchantColors.gold,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            c.displayLabel,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${c.validatedPassages} passage(s) validé(s)',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: MerchantColors.textGrey,
                            ),
                          ),
                          trailing: _busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: MerchantColors.gold,
                                  ),
                                )
                              : Icon(Icons.play_arrow_rounded,
                                  color: Colors.orange.shade400),
                          onTap: _busy ? null : () => _simulate(c),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _debugBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange.shade700),
      ),
      child: Text(
        'DEBUG',
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.orange.shade200,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
