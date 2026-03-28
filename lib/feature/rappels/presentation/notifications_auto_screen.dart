import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../../storefront/application/providers.dart' as storefront_providers;
import '../application/providers.dart' as rappels_providers;
import '../domain/entities/active_notification.dart';
import 'widgets/active_notifications_list.dart';
import 'widgets/audience_section.dart';
import 'widgets/compose_section.dart';
import 'widgets/step_header.dart';
import 'widgets/trigger_grid.dart';

/// Notifications automatiques screen – all data saved to Firestore.
class NotificationsAutoScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const NotificationsAutoScreen({super.key, this.onBack});

  @override
  ConsumerState<NotificationsAutoScreen> createState() =>
      _NotificationsAutoScreenState();
}

class _NotificationsAutoScreenState
    extends ConsumerState<NotificationsAutoScreen> {
  final TextEditingController _textCtrl = TextEditingController();

  int _clientSelection = 0;
  int _selectedTrigger = 0;
  int? _editingIndex;
  ActiveNotification? _editingNotification;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storefrontAsync = ref.watch(storefront_providers.storefrontProvider);
    final merchantId = storefrontAsync.value?.id;
    final notificationsAsync = merchantId != null
        ? ref.watch(rappels_providers.autoNotificationsProvider(merchantId))
        : const AsyncValue<List<ActiveNotification>>.data([]);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: MerchantColors.bgHeader,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  children: [
                    ComposeSection(
                      controller: _textCtrl,
                      isEditing: _editingIndex != null,
                      onCancelEdit: _cancelEdit,
                    ),
                    AudienceSection(
                      selectedIndex: _clientSelection,
                      onChanged: (v) =>
                          setState(() => _clientSelection = v),
                    ),
                    _buildTriggerSection(),
                    _buildActionButton(merchantId),
                    notificationsAsync.when(
                      data: (notifications) => ActiveNotificationsList(
                        notifications: notifications,
                        onToggle: (i, v) => _onToggle(merchantId!, notifications[i], v),
                        onEdit: (i) => _edit(notifications, i),
                        onDelete: (i) => _delete(merchantId!, notifications, i),
                      ),
                      loading: () => ActiveNotificationsList(
                        notifications: const [],
                        onToggle: (_, __) {},
                        onEdit: (_) {},
                        onDelete: (_) {},
                      ),
                      error: (_, __) => ActiveNotificationsList(
                        notifications: const [],
                        onToggle: (_, __) {},
                        onEdit: (_) {},
                        onDelete: (_) {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: MerchantColors.gold, width: 2),
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_back_ios_new,
                        color: MerchantColors.gold, size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Notifications auto.',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── trigger section (small – stays inline) ─────────────────────────────────

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
            onSelected: (i) => setState(() => _selectedTrigger = i),
          ),
        ],
      ),
    );
  }

  // ── action button (small – stays inline) ───────────────────────────────────

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
          content:
              Text('Veuillez écrire un message', style: GoogleFonts.outfit()),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }
    if (merchantId == null || merchantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Commerce non chargé', style: GoogleFonts.outfit()),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }

    final triggerLabel = triggerLabels[_selectedTrigger];
    final audienceLabel =
        _clientSelection == 0 ? 'Tous mes clients' : 'Certains clients';
    final text = _textCtrl.text.trim();

    if (_editingNotification != null) {
      final updateUseCase = ref.read(rappels_providers.updateAutoNotificationProvider);
      final updated = _editingNotification!.copyWith(
        text: text,
        trigger: triggerLabel,
        audience: audienceLabel,
      );
      final result = await updateUseCase.call(updated);
      result.fold(
        (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de l\'enregistrement',
                    style: GoogleFonts.outfit()),
                backgroundColor: Colors.red[400],
              ),
            );
          }
        },
        (_) {
          ref.invalidate(rappels_providers.autoNotificationsProvider(merchantId));
          setState(() {
            _editingIndex = null;
            _editingNotification = null;
            _textCtrl.clear();
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Modification enregistrée', style: GoogleFonts.outfit()),
                backgroundColor: MerchantColors.gold,
              ),
            );
          }
        },
      );
    } else {
      final createUseCase = ref.read(rappels_providers.createAutoNotificationProvider);
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
        ),
      );
      result.fold(
        (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur lors de l\'ajout', style: GoogleFonts.outfit()),
                backgroundColor: Colors.red[400],
              ),
            );
          }
        },
        (_) {
          ref.invalidate(rappels_providers.autoNotificationsProvider(merchantId));
          setState(() => _textCtrl.clear());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Notification ajoutée', style: GoogleFonts.outfit()),
                backgroundColor: MerchantColors.gold,
              ),
            );
          }
        },
      );
    }
  }

  void _cancelEdit() {
    setState(() {
      _editingIndex = null;
      _editingNotification = null;
      _textCtrl.clear();
    });
  }

  void _edit(List<ActiveNotification> notifications, int i) {
    setState(() {
      _editingIndex = i;
      _editingNotification = notifications[i];
      _textCtrl.text = notifications[i].text;
    });
  }

  Future<void> _onToggle(
    String merchantId,
    ActiveNotification notification,
    bool v,
  ) async {
    final updateUseCase = ref.read(rappels_providers.updateAutoNotificationProvider);
    final result = await updateUseCase.call(notification.copyWith(isEnabled: v));
    result.fold(
      (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la mise à jour', style: GoogleFonts.outfit()),
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
                        content: Text('Erreur lors de la suppression',
                            style: GoogleFonts.outfit()),
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
}
