import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/shared/constants/merchant_colors.dart';
import '../domain/entities/active_notification.dart';
import 'widgets/active_notifications_list.dart';
import 'widgets/audience_section.dart';
import 'widgets/compose_section.dart';
import 'widgets/step_header.dart';
import 'widgets/trigger_grid.dart';

/// Notifications automatiques screen – thin orchestrator.
///
/// Delegates UI to:
///  • [ComposeSection]  – step 1: write message
///  • [AudienceSection] – step 2: pick audience
///  • [TriggerGrid]     – step 3: pick trigger
///  • [ActiveNotificationsList] – step 4: manage existing
class NotificationsAutoScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const NotificationsAutoScreen({super.key, this.onBack});

  @override
  State<NotificationsAutoScreen> createState() =>
      _NotificationsAutoScreenState();
}

class _NotificationsAutoScreenState extends State<NotificationsAutoScreen> {
  final TextEditingController _textCtrl = TextEditingController();

  int _clientSelection = 0;
  int _selectedTrigger = 0;
  int? _editingIndex;

  final List<ActiveNotification> _active = [
    ActiveNotification(
        text: 'Bon anniversaire!', trigger: 'Date anniversaire client'),
    ActiveNotification(
        text: 'Merci pour votre visite', trigger: 'Visite client détectée'),
    ActiveNotification(
        text: 'On ne vous voit plus? A très vite.',
        trigger: 'Retour d\'un client inactif'),
  ];

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    // Step 1
                    ComposeSection(
                      controller: _textCtrl,
                      isEditing: _editingIndex != null,
                      onCancelEdit: _cancelEdit,
                    ),
                    // Step 2
                    AudienceSection(
                      selectedIndex: _clientSelection,
                      onChanged: (v) =>
                          setState(() => _clientSelection = v),
                    ),
                    // Step 3
                    _buildTriggerSection(),
                    // Action button
                    _buildActionButton(),
                    // Step 4
                    ActiveNotificationsList(
                      notifications: _active,
                      onToggle: (i, v) =>
                          setState(() => _active[i].isEnabled = v),
                      onEdit: _edit,
                      onDelete: _delete,
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

  Widget _buildActionButton() {
    final isEditing = _editingIndex != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: GestureDetector(
        onTap: _onSend,
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

  void _onSend() {
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

    final triggerLabel = triggerLabels[_selectedTrigger];
    final audienceLabel =
        _clientSelection == 0 ? 'Tous mes clients' : 'Certains clients';

    setState(() {
      if (_editingIndex != null) {
        _active[_editingIndex!] = ActiveNotification(
          text: _textCtrl.text.trim(),
          trigger: triggerLabel,
          audience: audienceLabel,
        );
        _editingIndex = null;
      } else {
        _active.add(ActiveNotification(
          text: _textCtrl.text.trim(),
          trigger: triggerLabel,
          audience: audienceLabel,
        ));
      }
      _textCtrl.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification ajoutée', style: GoogleFonts.outfit()),
        backgroundColor: MerchantColors.gold,
      ),
    );
  }

  void _cancelEdit() {
    setState(() {
      _editingIndex = null;
      _textCtrl.clear();
    });
  }

  void _edit(int i) {
    setState(() {
      _editingIndex = i;
      _textCtrl.text = _active[i].text;
    });
  }

  void _delete(int i) {
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
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _active.removeAt(i));
            },
            child: Text('Supprimer',
                style: GoogleFonts.outfit(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
