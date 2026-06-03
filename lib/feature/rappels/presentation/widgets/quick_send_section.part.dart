part of 'quick_send_section.dart';

// The UI extension keeps the part file pattern but calls setState via a
// helper that is not @protected from the main class context.
extension _QuickSendSectionUi on _QuickSendSectionState {
  // Workaround: call setState via a non-protected wrapper.
  void _rebuildWith(VoidCallback fn) => setState(fn); // ignore: invalid_use_of_protected_member
  Widget _buildBody(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RappelsSectionHeader(
            icon: Icons.send_rounded,
            title: 'Notification rapide',
            subtitle: 'envoi immédiat à vos clients',
          ),
          const SizedBox(height: 12),
          _buildTemplateToolbar(context),
          const SizedBox(height: 10),
          _buildCompose(context),
          const SizedBox(height: 14),
          _buildAudienceChips(),
          const SizedBox(height: 10),
          _buildQuotaRow(),
          const SizedBox(height: 12),
          _buildScheduleRow(context),
          const SizedBox(height: 16),
          _buildSendButton(context),
          const SizedBox(height: 16),
          _buildPendingScheduledList(context),
          if (widget.history.isNotEmpty || widget.historyLoading) ...[
            const SizedBox(height: 20),
            _buildHistory(context),
          ],
        ],
      ),
    );
  }

  // ── Templates toolbar ─────────────────────────────────────────────────────
  // Two-button row above the compose field. Loading is the primary
  // affordance (saves typing); save is gated on the field being non-empty
  // to avoid creating empty templates by accident.
  Widget _buildTemplateToolbar(BuildContext context) {
    final hasText = _ctrl.text.trim().isNotEmpty;
    return Row(
      children: [
        _TemplateChip(
          icon: Icons.folder_open_rounded,
          label: 'Charger un template',
          onTap: _openTemplatesPicker,
        ),
        const SizedBox(width: 8),
        _TemplateChip(
          icon: Icons.bookmark_add_outlined,
          label: 'Enregistrer',
          onTap: hasText ? _saveCurrentAsTemplate : null,
        ),
      ],
    );
  }

  // ── Compose ──────────────────────────────────────────────────────────────

  Widget _buildCompose(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MerchantColors.navyCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MerchantColors.gold
              .withValues(alpha: MerchantColors.goldBorderAlpha),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _ctrl,
        maxLines: 3,
        minLines: 2,
        maxLength: 280,
        onTapOutside: (_) =>
            FocusManager.instance.primaryFocus?.unfocus(),
        style: GoogleFonts.outfit(fontSize: 14, color: Colors.white, height: 1.5),
        cursorColor: MerchantColors.gold,
        decoration: MerchantColors.inputDecorationOnDarkSurface(
          InputDecoration(
            hintText: 'Écrivez votre message ici…',
            hintStyle: GoogleFonts.outfit(
              fontSize: 14,
              color: MerchantColors.textGrey,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            counterStyle: GoogleFonts.outfit(
              fontSize: 10,
              color: MerchantColors.textGrey,
            ),
          ),
        ),
        onChanged: (_) => _rebuildWith(() {}),
      ),
    );
  }

  // ── Audience chips ────────────────────────────────────────────────────────

  Widget _buildAudienceChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_QuickSendSectionState._audienceOptions.length, (i) {
          final opt = _QuickSendSectionState._audienceOptions[i];
          final selected = _audienceIndex == i;
          return Padding(
            padding: EdgeInsets.only(right: i < _QuickSendSectionState._audienceOptions.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
                _rebuildWith(() => _audienceIndex = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? MerchantColors.gold.withValues(alpha: 0.15)
                      : MerchantColors.navyCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? MerchantColors.gold
                        : MerchantColors.gold
                            .withValues(alpha: MerchantColors.goldBorderAlpha),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      opt.icon,
                      size: 14,
                      color: selected
                          ? MerchantColors.gold
                          : MerchantColors.textGrey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      opt.label,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? MerchantColors.gold
                            : MerchantColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Quota row ─────────────────────────────────────────────────────────────

  Widget _buildQuotaRow() {
    final exceeded = widget.quotaExceeded;
    return Row(
      children: [
        Icon(
          exceeded ? Icons.lock_outline_rounded : Icons.bolt_rounded,
          size: 13,
          color: exceeded ? Colors.red[300] : MerchantColors.textGrey,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            // Earlier feedback read the "2/5" label as "stuck at 2 max".
            // We lead with the cap and use plain words ("envois utilisés",
            // "plafond 5") so the ratio can't be misread as the limit.
            exceeded
                ? 'Limite hebdomadaire atteinte (${widget.quotaLabel} envois '
                    'utilisés sur 5 max). Patientez — la fenêtre glissante '
                    'de 7 jours libère un envoi à la fois.'
                : 'Quota hebdomadaire : ${widget.quotaLabel} envois utilisés '
                    '— plafond 5 sur une fenêtre glissante de 7 jours.',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: exceeded ? Colors.red[300] : MerchantColors.textGrey,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  // ── Send button ───────────────────────────────────────────────────────────

  Widget _buildSendButton(BuildContext context) {
    final canSend = _ctrl.text.trim().isNotEmpty && !_sending && !widget.quotaExceeded;
    return GestureDetector(
      onTap: canSend
          ? () {
              FocusManager.instance.primaryFocus?.unfocus();
              _onSendTap();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: canSend
              ? const LinearGradient(
                  colors: [MerchantColors.gold, Color(0xFFD4AF37)],
                )
              : null,
          color: canSend ? null : MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(12),
          border: canSend
              ? null
              : Border.all(
                  color: MerchantColors.gold
                      .withValues(alpha: MerchantColors.goldBorderAlpha),
                ),
        ),
        child: Center(
          child: _sending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: MerchantColors.darkOverlay,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.send_rounded,
                      size: 16,
                      color: canSend
                          ? MerchantColors.darkOverlay
                          : MerchantColors.textGrey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Envoyer la notification',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: canSend
                            ? MerchantColors.darkOverlay
                            : MerchantColors.textGrey,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Schedule row + pending list ───────────────────────────────────────────
  // When _scheduledAt is null the toggle reads "Programmer plus tard"; when
  // set, it shows the chosen instant + a clear-affordance. The send button's
  // label flips to "Programmer" / "Envoyer" based on the same flag.
  Widget _buildScheduleRow(BuildContext context) {
    final scheduled = _scheduledAt;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        if (scheduled == null) {
          _toggleScheduleOn();
        } else {
          _toggleScheduleOff();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: scheduled != null
                ? MerchantColors.gold.withValues(alpha: 0.55)
                : MerchantColors.gold
                    .withValues(alpha: MerchantColors.goldBorderAlpha),
          ),
        ),
        child: Row(
          children: [
            Icon(
              scheduled != null
                  ? Icons.event_available_rounded
                  : Icons.schedule_rounded,
              size: 16,
              color: MerchantColors.gold,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                scheduled != null
                    ? 'Programmé le ${_formatScheduled(scheduled)}'
                    : 'Programmer plus tard',
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: scheduled != null
                      ? Colors.white
                      : MerchantColors.textLightGrey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              scheduled != null ? 'Annuler' : 'Choisir',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: MerchantColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingScheduledList(BuildContext context) {
    final repo = ref.watch(scheduledNotificationRepositoryProvider);
    return StreamBuilder<List<ScheduledNotification>>(
      stream: repo.watchAll(widget.merchantId),
      builder: (context, snap) {
        if (snap.hasError) return const SizedBox.shrink();
        final all = snap.data ?? const <ScheduledNotification>[];
        // Only pending entries get UI surface here. Sent/cancelled/failed
        // entries are deliberately hidden — a future "historique
        // programmation" tab would surface them.
        final pending = all.where((s) => s.isPending).toList();
        if (pending.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Programmées',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: MerchantColors.textGrey,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            ...pending.map((s) => _scheduledRow(s)),
          ],
        );
      },
    );
  }

  Widget _scheduledRow(ScheduledNotification s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded,
                color: MerchantColors.gold, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatScheduled(s.scheduledAt.toLocal()),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: MerchantColors.gold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s.text,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => _cancelScheduled(s),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 28),
              ),
              child: Text(
                'Annuler',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatScheduled(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)} à ${two(dt.hour)}:${two(dt.minute)}';
  }

  // ── History ───────────────────────────────────────────────────────────────

  Widget _buildHistory(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Historique',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: MerchantColors.textGrey,
              letterSpacing: 0.6,
            ),
          ),
        ),
        if (widget.historyLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: MerchantColors.gold,
              ),
            ),
          )
        else
          ...widget.history.take(5).map((n) => _historyRow(n)),
      ],
    );
  }

  Widget _historyRow(SentNotification n) {
    final diff = DateTime.now().difference(n.sentAt);
    final String timeLabel;
    if (diff.inMinutes < 1) {
      timeLabel = "À l'instant";
    } else if (diff.inHours < 1) {
      timeLabel = 'Il y a ${diff.inMinutes} min';
    } else if (diff.inDays < 1) {
      timeLabel = 'Il y a ${diff.inHours} h';
    } else if (diff.inDays == 1) {
      timeLabel = 'Hier';
    } else {
      timeLabel = 'Il y a ${diff.inDays} j';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                MerchantColors.gold.withValues(alpha: MerchantColors.goldBorderAlpha),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people_outline_rounded,
                          size: 11, color: MerchantColors.textGrey),
                      const SizedBox(width: 3),
                      Text(
                        '${n.sentCount} client${n.sentCount > 1 ? 's' : ''}',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: MerchantColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              timeLabel,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: MerchantColors.gold.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Surfaced when the merchant types a personalised birthday wish
  // ("Joyeux anniversaire …") and broadcasts it to "Tous mes clients".
  // Most of the time they meant the per-DOB auto-trigger, not a blast.
  // The dialog explains the difference and lets them either bail out
  // (so they can switch to the auto-notification screen) or confirm
  // they really meant a broadcast.
  Future<bool?> _confirmPersonalBirthdayBroadcast() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MerchantColors.bgHeader,
        title: Text(
          'Envoyer ce message à tous ?',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Ce message ressemble à un souhait d\'anniversaire personnel. '
          'Envoyé à tous vos clients, il sera reçu par des personnes dont '
          'ce n\'est pas l\'anniversaire.\n\n'
          'Pour souhaiter automatiquement l\'anniversaire à chaque client '
          'le bon jour, utilisez plutôt une notification automatique '
          '(déclencheur "Date anniversaire client").',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: MerchantColors.textLightGrey,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Annuler',
              style: GoogleFonts.outfit(color: MerchantColors.textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Envoyer quand même',
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
}

class _TemplateChip extends StatelessWidget {
  const _TemplateChip({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              FocusManager.instance.primaryFocus?.unfocus();
              onTap!();
            },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: MerchantColors.bgMain,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: MerchantColors.gold.withValues(
                alpha: disabled ? 0.15 : MerchantColors.goldBorderAlpha),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: disabled
                  ? MerchantColors.textGrey
                  : MerchantColors.gold,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: disabled
                    ? MerchantColors.textGrey
                    : MerchantColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
