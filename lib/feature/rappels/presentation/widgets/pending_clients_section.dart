import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../application/providers.dart' as rappels_providers;
import '../../domain/entities/pending_client_row.dart';
import 'rappels_section_header.dart';

part 'pending_clients_section.part.dart';

/// Section shown on RappelsScreen when auto-client-validation is OFF.
/// Lists new followers awaiting merchant acknowledgement.
class PendingClientsSection extends ConsumerStatefulWidget {
  const PendingClientsSection({
    super.key,
    required this.merchantId,
    required this.isAutoValidation,
  });

  final String merchantId;

  /// When true (auto ON) the section is hidden — auto-handled.
  final bool isAutoValidation;

  @override
  ConsumerState<PendingClientsSection> createState() =>
      _PendingClientsSectionState();
}

class _PendingClientsSectionState extends ConsumerState<PendingClientsSection> {
  final Set<String> _busy = {};
  bool _busyAll = false;

  Future<void> _onAcknowledge(PendingClientRow row) async {
    if (_busy.contains(row.clientUid) || _busyAll) return;
    setState(() => _busy.add(row.clientUid));

    final useCase = ref.read(rappels_providers.acknowledgeNewClientProvider);
    final result = await useCase.call(
      merchantId: widget.merchantId,
      clientUid: row.clientUid,
    );

    if (!mounted) return;
    setState(() => _busy.remove(row.clientUid));

    result.fold(
      (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(f.message, style: GoogleFonts.outfit()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red[700],
          ),
        );
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${row.displayLabel} ajouté à votre base',
              style: GoogleFonts.outfit(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: MerchantColors.gold,
          ),
        );
      },
    );
  }

  Future<void> _onAcknowledgeAll(List<PendingClientRow> rows) async {
    if (_busyAll) return;
    setState(() => _busyAll = true);

    final useCase = ref.read(rappels_providers.acknowledgeNewClientProvider);
    for (final row in rows) {
      await useCase.call(
        merchantId: widget.merchantId,
        clientUid: row.clientUid,
      );
    }

    if (!mounted) return;
    setState(() => _busyAll = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${rows.length} nouveau${rows.length > 1 ? 'x' : ''} client${rows.length > 1 ? 's' : ''} acquitté${rows.length > 1 ? 's' : ''}',
          style: GoogleFonts.outfit(),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: MerchantColors.gold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isAutoValidation || widget.merchantId.isEmpty) {
      return const SizedBox.shrink();
    }

    final pendingAsync = ref.watch(
      rappels_providers.pendingClientsForMerchantProvider(widget.merchantId),
    );

    return _buildBody(context, pendingAsync);
  }
}
