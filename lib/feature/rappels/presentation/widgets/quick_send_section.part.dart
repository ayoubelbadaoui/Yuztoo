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
          const SizedBox(height: 16),
          _buildCompose(context),
          const SizedBox(height: 14),
          _buildAudienceChips(),
          const SizedBox(height: 10),
          _buildQuotaRow(),
          const SizedBox(height: 16),
          _buildSendButton(context),
          if (widget.history.isNotEmpty || widget.historyLoading) ...[
            const SizedBox(height: 20),
            _buildHistory(context),
          ],
        ],
      ),
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
        style: GoogleFonts.outfit(fontSize: 14, color: Colors.white, height: 1.5),
        cursorColor: MerchantColors.gold,
        decoration: InputDecoration(
          hintText: 'Écrivez votre message ici…',
          hintStyle: GoogleFonts.outfit(
            fontSize: 14,
            color: MerchantColors.textGrey,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          filled: true,
          fillColor: Colors.transparent,
          counterStyle: GoogleFonts.outfit(
            fontSize: 10,
            color: MerchantColors.textGrey,
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
          onTap: () => _rebuildWith(() => _audienceIndex = i),
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
        Text(
          exceeded
              ? 'Quota hebdomadaire atteint (${widget.quotaLabel})'
              : 'Quota hebdo : ${widget.quotaLabel} envois',
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: exceeded ? Colors.red[300] : MerchantColors.textGrey,
          ),
        ),
      ],
    );
  }

  // ── Send button ───────────────────────────────────────────────────────────

  Widget _buildSendButton(BuildContext context) {
    final canSend = _ctrl.text.trim().isNotEmpty && !_sending && !widget.quotaExceeded;
    return GestureDetector(
      onTap: canSend ? _onSendTap : null,
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
}
