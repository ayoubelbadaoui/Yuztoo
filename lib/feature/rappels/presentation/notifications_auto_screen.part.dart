part of 'notifications_auto_screen.dart';

extension _NotificationsAutoScreenUi on _NotificationsAutoScreenState {
  Widget _buildNotificationsAutoRoot(
    String? merchantId,
    AsyncValue<List<ActiveNotification>> notificationsAsync,
  ) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: MerchantColors.bgMain,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.of(context).maybePop();
            }
          }
        },
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: MerchantColors.bgMain,
            body: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: 32 +
                          MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      children: [
                        ComposeSection(
                          controller: _textCtrl,
                          isEditing: _editingIndex != null,
                          onCancelEdit: _cancelEdit,
                        ),
                        AudienceSection(
                          selectedIndex: _clientSelection,
                          onChanged: _onClientSelectionChanged,
                          targetSegments: _targetSegments,
                          onSegmentToggled: _onSegmentToggled,
                        ),
                        _buildTriggerSection(),
                        _buildActionButton(merchantId),
                        notificationsAsync.when(
                          data: (notifications) {
                            return ActiveNotificationsList(
                              notifications: notifications,
                              onToggle: (i, v) => _onToggle(
                                  merchantId ?? '', notifications[i], v),
                              onEdit: (i) => _edit(notifications, i),
                              onDelete: (i) =>
                                  _delete(merchantId ?? '', notifications, i),
                              onTest: (i) =>
                                  _onTest(merchantId ?? '', notifications[i]),
                            );
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: MerchantColors.gold),
                            ),
                          ),
                          error: (err, __) => Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade900.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.red.shade400.withValues(alpha: 0.5)),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline_rounded,
                                      color: Colors.red.shade300, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Impossible de charger les notifications automatiques.',
                                      style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          color: Colors.red.shade200),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: MerchantColors.bgHeader,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
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
                behavior: HitTestBehavior.opaque,
                onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: MerchantColors.gold, size: 20),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Notifications auto.',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),
        ),
      ),
    );
  }

  // ── trigger section ──────────────────────────────────────────────────────

  Widget _buildTriggerSection() {
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
          const StepHeader(
            step: 3,
            title: 'Déclencheur',
            icon: Icons.bolt_rounded,
          ),
          const SizedBox(height: 4),
          Text(
            'Quand envoyer cette notification ?',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textGrey,
            ),
          ),
          const SizedBox(height: 16),
          TriggerGrid(
            selectedIndex: _selectedTrigger,
            onSelected: _onTriggerSelected,
          ),
        ],
      ),
    );
  }

  // ── action button ──────────────────────────────────────────────────────────

  Widget _buildActionButton(String? merchantId) {
    final isEditing = _editingIndex != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: GestureDetector(
        onTap: () => _onSend(merchantId),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: MerchantColors.gold,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isEditing ? Icons.check_rounded : Icons.add_rounded,
                color: MerchantColors.darkOverlay,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isEditing
                    ? 'Enregistrer la modification'
                    : 'Ajouter la notification',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: MerchantColors.darkOverlay,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── actions ────────────────────────────────────────────────────────────────

  Future<void> _onSend(String? merchantId) async {
    if (_textCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veuillez écrire un message',
            style: merchantSnackBarTextOnWarmAccent(),
          ),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }
    if (merchantId == null || merchantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Commerce non chargé',
            style: merchantSnackBarTextOnWarmAccent(),
          ),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }

    final triggerLabel = triggerLabels[_selectedTrigger];
    if (!AutoNotificationTriggers.isWiredInCloud(triggerLabel)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ce déclencheur sera disponible prochainement. '
            'Choisissez un autre événement pour l’instant.',
            style: merchantSnackBarTextOnWarmAccent(),
          ),
          backgroundColor: Colors.orange[800],
        ),
      );
      return;
    }
    final audienceLabel =
        _clientSelection == 0 ? 'Tous mes clients' : 'Certains clients';
    final text = _textCtrl.text.trim();
    final segments = _clientSelection == 1 ? _targetSegments : const <String>[];

    if (_editingNotification != null) {
      final updateUseCase =
          ref.read(rappels_providers.updateAutoNotificationProvider);
      final updated = _editingNotification!.copyWith(
        text: text,
        trigger: triggerLabel,
        audience: audienceLabel,
        targetSegments: segments,
      );
      final result = await updateUseCase.call(updated);
      result.fold(
        (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Erreur lors de l\'enregistrement',
                  style: merchantSnackBarTextOnWarmAccent(),
                ),
                backgroundColor: Colors.red[400],
              ),
            );
          }
        },
        (_) {
          ref.invalidate(rappels_providers.autoNotificationsProvider(merchantId));
          _withSetState(() {
            _editingIndex = null;
            _editingNotification = null;
            _textCtrl.clear();
            _targetSegments = const [];
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Modification enregistrée',
                  style: merchantSnackBarTextOnGold(),
                ),
                backgroundColor: MerchantColors.gold,
              ),
            );
          }
        },
      );
    } else {
      final createUseCase =
          ref.read(rappels_providers.createAutoNotificationProvider);
      const draft = ActiveNotification(
        id: '',
        merchantId: '',
        text: '',
      );
      final result = await createUseCase.call(
        merchantId: merchantId,
        notification: draft.copyWith(
          text: text,
          trigger: triggerLabel,
          audience: audienceLabel,
          targetSegments: segments,
        ),
      );
      result.fold(
        (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Erreur lors de l\'ajout',
                  style: merchantSnackBarTextOnWarmAccent(),
                ),
                backgroundColor: Colors.red[400],
              ),
            );
          }
        },
        (_) {
          ref.invalidate(rappels_providers.autoNotificationsProvider(merchantId));
          _withSetState(() {
            _textCtrl.clear();
            _targetSegments = const [];
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Notification ajoutée',
                  style: merchantSnackBarTextOnGold(),
                ),
                backgroundColor: MerchantColors.gold,
              ),
            );
          }
        },
      );
    }
  }

  void _cancelEdit() {
    _withSetState(() {
      _editingIndex = null;
      _editingNotification = null;
      _textCtrl.clear();
      _targetSegments = const [];
    });
  }

  void _edit(List<ActiveNotification> notifications, int i) {
    final notif = notifications[i];
    // Restore trigger index from the saved label string
    final triggerIdx = triggerLabels.indexOf(notif.trigger);
    // Restore audience index: 0 = Tous, 1 = Certains
    final audienceIdx = notif.audience == 'Tous mes clients' ? 0 : 1;
    _withSetState(() {
      _editingIndex = i;
      // Only set _editingNotification for real (non-dummy) entries.
      _editingNotification = notif.id.startsWith('dummy_') ? null : notif;
      _textCtrl.text = notif.text;
      _selectedTrigger = triggerIdx >= 0 ? triggerIdx : 0;
      _clientSelection = audienceIdx;
      _targetSegments = List<String>.from(notif.targetSegments);
    });
  }

  Future<void> _onToggle(
    String merchantId,
    ActiveNotification notification,
    bool v,
  ) async {
    final updateUseCase =
        ref.read(rappels_providers.updateAutoNotificationProvider);
    final result =
        await updateUseCase.call(notification.copyWith(isEnabled: v));
    result.fold(
      (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erreur lors de la mise à jour',
                style: merchantSnackBarTextOnWarmAccent(),
              ),
              backgroundColor: Colors.red[400],
            ),
          );
        }
      },
      (_) =>
          ref.invalidate(rappels_providers.autoNotificationsProvider(merchantId)),
    );
  }

  void _delete(
    String merchantId,
    List<ActiveNotification> notifications,
    int i,
  ) {
    final notification = notifications[i];
    // Dummy entries can't be deleted from Firestore.
    if (notification.id.startsWith('dummy_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Données de démo — non supprimable',
            style: merchantSnackBarTextOnDark(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: MerchantColors.navyCard,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MerchantColors.navyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w600)),
        content: Text('Voulez-vous supprimer cette notification ?',
            style: GoogleFonts.outfit(color: MerchantColors.textGrey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: GoogleFonts.outfit(color: MerchantColors.textGrey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final deleteUseCase =
                  ref.read(rappels_providers.deleteAutoNotificationProvider);
              final result = await deleteUseCase.call(
                merchantId: merchantId,
                notificationId: notification.id,
              );
              result.fold(
                (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Erreur lors de la suppression',
                          style: merchantSnackBarTextOnWarmAccent(),
                        ),
                        backgroundColor: Colors.red[400],
                      ),
                    );
                  }
                },
                (_) {
                  ref.invalidate(
                      rappels_providers.autoNotificationsProvider(merchantId));
                },
              );
            },
            child: Text('Supprimer',
                style: GoogleFonts.outfit(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Sends a test notification to the merchant's own device.
  Future<void> _onTest(
    String merchantId,
    ActiveNotification notification,
  ) async {
    final auth = ref.read(firebaseAuthProvider);
    final ownerUid = auth.currentUser?.uid;
    if (ownerUid == null || ownerUid.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Utilisateur non connecté',
            style: merchantSnackBarTextOnWarmAccent(),
          ),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }

    // Fetch merchant name for the notification title.
    final storefrontAsync =
        ref.read(storefront_providers.storefrontProvider).valueOrNull;
    final merchantName = storefrontAsync?.merchantName ?? 'Votre commerce';

    final notifRepo = ref.read(clientNotificationRepositoryProvider);
    final result = await notifRepo.create(
      ClientNotification(
        id: '',
        clientId: ownerUid,
        merchantId: merchantId,
        merchantName: merchantName,
        type: ClientNotificationType.auto,
        title: merchantName,
        body: notification.text,
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    result.fold(
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur lors de l\'envoi du test',
            style: merchantSnackBarTextOnWarmAccent(),
          ),
          backgroundColor: Colors.red[400],
        ),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Notification test envoyée sur votre téléphone 📱',
            style: merchantSnackBarTextOnGold(),
          ),
          backgroundColor: MerchantColors.gold,
        ),
      ),
    );
  }
}
