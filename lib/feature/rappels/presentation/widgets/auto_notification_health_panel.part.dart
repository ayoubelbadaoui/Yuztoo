part of 'auto_notification_health_panel.dart';

extension _AutoNotificationHealthPanelUi
    on _AutoNotificationHealthPanelState {
  // Ignored because we explicitly want to call setState from a part-file
  // extension while keeping the build in this file too.
  void _rebuildWith(VoidCallback fn) =>
      setState(fn); // ignore: invalid_use_of_protected_member

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: MerchantColors.navyCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: MerchantColors.gold.withValues(
              alpha: MerchantColors.goldBorderStronger,
            ),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: FutureBuilder<AutoNotificationHealthReport>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return _buildLoading();
            }
            final report = snap.data;
            if (report == null) {
              return _buildErrorState(snap.error);
            }
            return _buildLoaded(context, report);
          },
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Row(
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            color: MerchantColors.gold,
            strokeWidth: 2,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Diagnostic du pipeline en cours…',
          style: GoogleFonts.outfit(
            color: MerchantColors.textLightGrey,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(Object? err) {
    return Row(
      children: [
        Icon(Icons.error_outline_rounded,
            color: Colors.red.shade300, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Diagnostic indisponible. ${err ?? ''}'.trim(),
            style: GoogleFonts.outfit(
              color: MerchantColors.textLightGrey,
              fontSize: 12,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: MerchantColors.gold, size: 18),
          onPressed: _refresh,
        ),
      ],
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    AutoNotificationHealthReport report,
  ) {
    final allGreen = report.isFullyOperational;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryRow(report, allGreen),
        if (_expanded || !allGreen) ...[
          const SizedBox(height: 12),
          Divider(
            color: MerchantColors.gold.withValues(alpha: 0.15),
            height: 1,
          ),
          const SizedBox(height: 12),
          ..._buildCheckRows(report),
          const SizedBox(height: 14),
          _buildTestButton(context, report),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(AutoNotificationHealthReport report, bool allGreen) {
    final icon = allGreen ? Icons.check_circle_rounded : Icons.error_outline;
    final iconColor = allGreen ? const Color(0xFF66BB6A) : Colors.amber;
    final label = allGreen
        ? 'Pipeline auto-notifications opérationnel'
        : 'Le pipeline n\'est pas complètement opérationnel';

    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Rafraîchir',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: const Icon(Icons.refresh,
              color: MerchantColors.gold, size: 18),
          onPressed: _refresh,
        ),
        IconButton(
          tooltip: _expanded ? 'Réduire' : 'Détails',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: Icon(
            _expanded ? Icons.expand_less : Icons.expand_more,
            color: MerchantColors.gold,
            size: 22,
          ),
          onPressed: () => _rebuildWith(() => _expanded = !_expanded),
        ),
      ],
    );
  }

  List<Widget> _buildCheckRows(AutoNotificationHealthReport report) {
    return [
      _checkRow(
        ok: report.pushAllowed,
        title: 'Notifications autorisées sur cet appareil',
        subWhenFailing: _pushFailureHint(report.pushPermission),
      ),
      _checkRow(
        ok: report.fcmTokenRegistered,
        title: 'Token de notification enregistré',
        subWhenFailing:
            'L\'appareil n\'est pas enregistré côté serveur. Connectez-vous '
            'à nouveau ou redémarrez l\'application — l\'enregistrement est '
            'automatique au démarrage.',
      ),
      _checkRow(
        ok: report.merchantAutoEnabled,
        title: 'Auto-notifications activées sur le compte',
        subWhenFailing:
            'Vous avez désactivé les notifications automatiques dans les '
            'paramètres du compte. Réactivez-les pour relancer le pipeline.',
      ),
      _checkRow(
        ok: report.enabledTemplates > 0,
        title: report.enabledTemplates > 0
            ? '${report.enabledTemplates} template(s) actif(s) '
                'sur ${report.totalTemplates}'
            : 'Aucun template actif',
        subWhenFailing:
            'Créez au moins un template ci-dessous et activez-le. Le serveur '
            'ne déclenche que les templates dont l\'interrupteur est ON.',
      ),
      _lastSentRow(report.lastAutoSentAt),
    ];
  }

  Widget _checkRow({
    required bool ok,
    required String title,
    String? subWhenFailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: ok ? const Color(0xFF66BB6A) : Colors.amber.shade400,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!ok && subWhenFailing != null && subWhenFailing.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subWhenFailing,
                      style: GoogleFonts.outfit(
                        color: MerchantColors.textLightGrey,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lastSentRow(DateTime? lastSentAt) {
    final label = lastSentAt == null
        ? 'Aucun envoi automatique enregistré pour le moment'
        : 'Dernier envoi automatique : ${_formatDateTime(lastSentAt)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.history_rounded,
            size: 18,
            color: MerchantColors.gold.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: MerchantColors.textLightGrey,
                fontSize: 12.5,
                fontStyle: lastSentAt == null
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _pushFailureHint(PushPermissionStatus status) {
    switch (status) {
      case PushPermissionStatus.granted:
      case PushPermissionStatus.provisional:
        return null;
      case PushPermissionStatus.denied:
        return 'Vous avez refusé les notifications. Allez dans Réglages > '
            'Yuztoo > Notifications pour les réactiver.';
      case PushPermissionStatus.notDetermined:
        return 'Le système n\'a pas encore demandé l\'autorisation. '
            'Tapez "Tester l\'envoi" pour déclencher la demande.';
      case PushPermissionStatus.unknown:
        return 'Impossible de lire l\'état des permissions. Vérifiez '
            'manuellement dans les réglages système.';
    }
  }

  Widget _buildTestButton(
      BuildContext context, AutoNotificationHealthReport report) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            _sendingTest ? null : () => _sendTestNotification(context, report),
        icon: _sendingTest
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.send_rounded, size: 16),
        label: Text(
          _sendingTest ? 'Envoi en cours…' : 'Tester l\'envoi maintenant',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: MerchantColors.gold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // Validates the full pipeline on this device:
  //   1. Re-prompts for permission if needed (covers "notDetermined").
  //   2. Writes a fake notification doc to the merchant's own inbox.
  //   3. The Cloud Function `onNotificationCreated` then sends a real push.
  // The merchant should observe BOTH a system push (banner / lock-screen)
  // AND a new entry in the in-app notification bell.
  Future<void> _sendTestNotification(
    BuildContext context,
    AutoNotificationHealthReport report,
  ) async {
    _rebuildWith(() => _sendingTest = true);

    try {
      // Re-prompt OS for permission when we know it hasn't been asked yet.
      // Granting it here means the same tap covers permission + delivery.
      if (report.pushPermission == PushPermissionStatus.notDetermined) {
        try {
          await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
        } catch (_) {}
      }

      final authState = ref.read(auth_providers.authStateProvider);
      if (authState is! Authenticated) {
        if (!context.mounted) return;
        _showError(context, 'Vous devez être connecté pour tester l\'envoi.');
        return;
      }

      final ownerUid = authState.user.id;
      final notifRepo = ref.read(clientNotificationRepositoryProvider);
      final result = await notifRepo.create(
        ClientNotification(
          id: '',
          clientId: ownerUid,
          merchantId: widget.merchantId,
          merchantName: widget.merchantName,
          type: ClientNotificationType.auto,
          title: widget.merchantName,
          body: 'Notification de test du pipeline auto-notifications. '
              'Si vous voyez ce message, tout fonctionne.',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      );

      if (!context.mounted) return;

      result.fold(
        (failure) => _showError(
          context,
          'Échec de l\'envoi : ${failure.message}.',
        ),
        (_) => _showSuccess(context),
      );
    } finally {
      if (mounted) _rebuildWith(() => _sendingTest = false);
      // Refresh the diagnostic so the "Last sent" row updates after
      // the Cloud Function increments sent_count + last_sent_at.
      // We don't await here — the CF can take a second or two.
      Future<void>.delayed(const Duration(seconds: 2)).then((_) {
        if (mounted) _refresh();
      });
    }
  }

  void _showSuccess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Notification de test envoyée. Regardez l\'écran d\'accueil de '
          'votre téléphone et la cloche de notifications.',
          style: merchantSnackBarTextOnGold(),
        ),
        backgroundColor: MerchantColors.gold,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: merchantSnackBarTextOnWarmAccent(),
        ),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${local.year} à $hh:$mi';
  }
}
