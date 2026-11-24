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
                    controller: _scrollCtrl,
                    padding: EdgeInsets.only(
                      bottom: 32 + MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      children: [
                        KeyedSubtree(
                          key: _listKey,
                          child: _buildNotificationsList(
                              merchantId, notificationsAsync),
                        ),
                        KeyedSubtree(key: _formKey, child: _buildFormTitle()),
                        KeyedSubtree(
                          key: _composeKey,
                          child: ComposeSection(
                            controller: _textCtrl,
                            isEditing: _editingIndex != null,
                            onCancelEdit: _cancelEdit,
                          ),
                        ),
                        KeyedSubtree(
                          key: _audienceKey,
                          child: AudienceSection(
                            selectedIndex: _clientSelection,
                            onChanged: _onClientSelectionChanged,
                            targetSegments: _targetSegments,
                            onSegmentToggled: _onSegmentToggled,
                          ),
                        ),
                        KeyedSubtree(
                          key: _triggerKey,
                          child: _buildTriggerSection(),
                        ),
                        KeyedSubtree(
                          key: _saveKey,
                          child: _buildActionButton(merchantId),
                        ),
                        // Live check of the whole chain (permission, device
                        // token, account flag, active notifications) + one-tap
                        // end-to-end test on the merchant's own phone.
                        if (merchantId != null)
                          KeyedSubtree(
                            key: _healthKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle(
                                  icon: Icons.verified_outlined,
                                  title: 'Vérifier l’envoi',
                                  subtitle:
                                      'Assurez-vous que les notifications arrivent bien.',
                                ),
                                AutoNotificationHealthPanel(
                                  merchantId: merchantId,
                                  merchantName: ref
                                          .watch(storefront_providers
                                              .storefrontProvider)
                                          .valueOrNull
                                          ?.merchantName ??
                                      'Votre commerce',
                                ),
                              ],
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
              if (widget.onBack != null)
                YBackButton(onPressed: widget.onBack!)
              else
                const SizedBox(width: 44),
              const Expanded(
                child: Center(
                  child: YuztooGradientTitle('Notifications auto.'),
                ),
              ),
              SizedBox(
                width: 44,
                child: IconButton(
                  tooltip: 'Guide de la page',
                  onPressed: _showPageGuide,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.info_outline_rounded,
                      color: MerchantColors.gold, size: 19),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── layout helpers ─────────────────────────────────────────────────────────

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: MerchantColors.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      color: MerchantColors.textGrey,
                      height: 1.35,
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

  Widget _buildFormTitle() {
    if (_editingNotification != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: EditNotificationHelpCard(
          triggerLabel: _editingNotification!.trigger,
          onCancel: _cancelEdit,
          onShowGuide: _showEditGuide,
        ),
      );
    }
    return _sectionTitle(
      icon: Icons.add_circle_outline_rounded,
      title: 'Nouvelle notification',
      subtitle: 'En 3 étapes : le message, à qui, et quand l’envoyer.',
    );
  }

  Widget _buildNotificationsList(
    String? merchantId,
    AsyncValue<List<ActiveNotification>> notificationsAsync,
  ) {
    return notificationsAsync.when(
      data: (notifications) => ActiveNotificationsList(
        notifications: notifications,
        onToggle: (i, v) => _onToggle(merchantId ?? '', notifications[i], v),
        onEdit: (i) => _edit(notifications, i),
        onDelete: (i) => _delete(merchantId ?? '', notifications, i),
        onTest: (i) => _onTest(merchantId ?? '', notifications[i]),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: MerchantColors.gold),
        ),
      ),
      error: (err, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red.shade900.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Colors.red.shade400.withValues(alpha: 0.5)),
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
                      fontSize: 13, color: Colors.red.shade200),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── guides (coachmarks) ────────────────────────────────────────────────────

  static const String _pageGuideSeenKey = 'coach_notif_auto_page_seen_v2';

  Future<void> _maybeAutoShowPageGuide() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_pageGuideSeenKey) ?? false) return;
      await prefs.setBool(_pageGuideSeenKey, true);
    } on Object {
      return; // Never risk replaying it every visit.
    }
    // Let the list / layout settle before measuring targets.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted || _editingNotification != null) return;
    _showPageGuide();
  }

  /// Full walkthrough of the page: what it is, the list (switch, edit, test,
  /// delete), the 3 creation steps, saving, and the delivery check.
  void _showPageGuide() {
    _editTour?.dismiss();
    _editTour = CoachmarkTour.show(
      context,
      steps: [
        CoachmarkStep(
          targetKey: _listKey,
          icon: Icons.auto_awesome_rounded,
          title: 'Les notifications automatiques',
          message: 'Vous écrivez un message une fois, YuzToo l’envoie tout '
              'seul à vos clients au bon moment (anniversaire, nouveau '
              'client, client inactif…). Pas besoin de garder '
              'l’application ouverte.',
        ),
        CoachmarkStep(
          targetKey: _listKey,
          icon: Icons.notifications_active_rounded,
          title: 'Vos notifications',
          message: 'Chaque carte est une notification. L’interrupteur la met '
              'en marche ou en pause. « Modifier » pour la changer, '
              '« Supprimer » pour l’effacer.',
        ),
        CoachmarkStep(
          targetKey: _listKey,
          icon: Icons.science_outlined,
          title: 'Tester avant vos clients',
          message: '« Tester » envoie la notification uniquement sur votre '
              'téléphone pour voir le rendu. Vos clients ne reçoivent rien.',
        ),
        CoachmarkStep(
          targetKey: _composeKey,
          icon: Icons.edit_note_rounded,
          title: '1. Votre message',
          message: 'Écrivez le texte que vos clients recevront '
              '(200 caractères maximum). Court et clair, c’est mieux.',
        ),
        CoachmarkStep(
          targetKey: _audienceKey,
          icon: Icons.groups_rounded,
          title: '2. À qui l’envoyer',
          message: 'Tous vos clients, ou seulement certains : nouveaux, '
              'habitués, VIP…',
        ),
        CoachmarkStep(
          targetKey: _triggerKey,
          icon: Icons.bolt_rounded,
          title: '3. Quand l’envoyer',
          message: 'Le déclencheur choisit le moment. Exemple : « Date '
              'anniversaire » part le jour de l’anniversaire de chaque client.',
        ),
        CoachmarkStep(
          targetKey: _saveKey,
          icon: Icons.check_circle_outline_rounded,
          title: 'Ajoutez',
          message: 'Appuyez ici : la notification est active tout de suite '
              'et apparaît dans « Mes notifications ».',
        ),
        if (_healthKey.currentContext != null)
          CoachmarkStep(
            targetKey: _healthKey,
            icon: Icons.verified_outlined,
            title: 'Tout fonctionne ?',
            message: 'Vert = tout est prêt. « Tester l’envoi maintenant » '
                'vous envoie une notification pour vérifier que votre '
                'téléphone la reçoit bien.',
          ),
      ],
      onFinish: () {
        _editTour = null;
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      },
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
          ref.invalidate(
              rappels_providers.autoNotificationsProvider(merchantId));
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
          ref.invalidate(
              rappels_providers.autoNotificationsProvider(merchantId));
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

  /// Coachmark tour over the real form: message → audience → trigger → save.
  void _showEditGuide() {
    _editTour?.dismiss();
    _editTour = CoachmarkTour.show(
      context,
      steps: [
        CoachmarkStep(
          targetKey: _composeKey,
          icon: Icons.edit_note_rounded,
          title: 'Modifiez votre message',
          message: 'Changez ici le texte que vos clients recevront.',
        ),
        CoachmarkStep(
          targetKey: _audienceKey,
          icon: Icons.groups_rounded,
          title: 'Choisissez à qui l’envoyer',
          message: 'Tous vos clients, ou seulement certains (VIP, habitués…).',
        ),
        CoachmarkStep(
          targetKey: _triggerKey,
          icon: Icons.bolt_rounded,
          title: 'Choisissez quand l’envoyer',
          message:
              'Le déclencheur décide du moment d’envoi. Changez-le si besoin.',
        ),
        CoachmarkStep(
          targetKey: _saveKey,
          icon: Icons.check_circle_outline_rounded,
          title: 'Enregistrez',
          message:
              'Appuyez sur « Enregistrer la modification ». Rien n’est changé avant.',
        ),
      ],
      onFinish: () {
        _editTour = null;
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      },
    );
  }

  void _cancelEdit() {
    _editTour?.dismiss();
    _editTour = null;
    _withSetState(() {
      _editingIndex = null;
      _editingNotification = null;
      _textCtrl.clear();
      _targetSegments = const [];
    });
  }

  void _edit(List<ActiveNotification> notifications, int i) {
    final notif = notifications[i];
    // Demo / placeholder rows are not persisted — same rule as delete.
    if (notif.id.startsWith('dummy_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Données de démo — non modifiable. Créez une notification réelle.',
            style: merchantSnackBarTextOnDark(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: MerchantColors.navyCard,
        ),
      );
      return;
    }
    // Restore trigger index from the saved label string
    final triggerIdx = triggerLabels.indexOf(notif.trigger);
    // Restore audience index: 0 = Tous, 1 = Certains
    final audienceIdx = notif.audience == 'Tous mes clients' ? 0 : 1;
    _withSetState(() {
      _editingIndex = i;
      _editingNotification = notif;
      _textCtrl.text = notif.text;
      _selectedTrigger = triggerIdx >= 0 ? triggerIdx : 0;
      _clientSelection = audienceIdx;
      _targetSegments = List<String>.from(notif.targetSegments);
    });
    // Compose form lives above the list — bring it into view so Modifier
    // feels responsive instead of "dead".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final formCtx = _formKey.currentContext;
      if (formCtx == null) return;
      Scrollable.ensureVisible(
        formCtx,
        alignment: 0.02,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
    // Guide automatically the first time only; « ? » replays it any time.
    unawaited(_maybeAutoShowEditGuide());
  }

  static const String _editGuideCountKey = 'coach_edit_auto_notif_count_v2';
  static const int _editGuideAutoTimes = 1;

  Future<void> _maybeAutoShowEditGuide() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getInt(_editGuideCountKey) ?? 0;
      if (seen >= _editGuideAutoTimes) return;
      await prefs.setInt(_editGuideCountKey, seen + 1);
    } on Object {
      // No prefs → still show the guide.
    }
    // Let the scroll-to-top settle so step 1 is measured in place.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted || _editingNotification == null) return;
    _showEditGuide();
  }

  Future<void> _onToggle(
    String merchantId,
    ActiveNotification notification,
    bool v,
  ) async {
    if (notification.id.startsWith('dummy_')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Données de démo — créez une notification réelle pour l\'activer.',
            style: merchantSnackBarTextOnDark(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: MerchantColors.navyCard,
        ),
      );
      return;
    }
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
      (_) => ref
          .invalidate(rappels_providers.autoNotificationsProvider(merchantId)),
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
            child:
                Text('Supprimer', style: GoogleFonts.outfit(color: Colors.red)),
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
