part of 'stores_screen.dart';

String _roleDescription(OrganizationRole role) => switch (role) {
      OrganizationRole.owner =>
        'Tous les points de vente, équipe et abonnement',
      OrganizationRole.manager =>
        'Vitrine, promotions, notifications et clients de ses points de vente',
      OrganizationRole.employee => 'Scan et validation des passages uniquement',
    };

/// Gérants and employés of the enseigne, with their stores.
class TeamScreen extends ConsumerWidget {
  const TeamScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(multiStoreDemoProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: StoresScreen._overlay,
      child: Scaffold(
        backgroundColor: MerchantColors.bgMain,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ScreenHeader(title: 'Équipe', onBack: onBack),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    MediaQuery.paddingOf(context).bottom + 24,
                  ),
                  children: [
                    Text(
                      'Invitez vos gérants et employés. Chacun accède '
                      'uniquement aux points de vente que vous lui confiez.',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: MerchantColors.textGrey,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _GoldOutlinedButton(
                      icon: Icons.person_add_alt_1_rounded,
                      label: 'Inviter un membre',
                      onPressed: () => _openMemberSheet(context),
                    ),
                    for (final role in OrganizationRole.values) ...[
                      const SizedBox(height: 24),
                      _SectionLabel(switch (role) {
                        OrganizationRole.owner => 'PROPRIÉTAIRE',
                        OrganizationRole.manager => 'GÉRANTS',
                        OrganizationRole.employee => 'EMPLOYÉS',
                      }),
                      const SizedBox(height: 4),
                      Text(
                        _roleDescription(role),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: MerchantColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final m in demo.members.where((m) => m.role == role))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MemberTile(
                            member: m,
                            demo: demo,
                            onTap: role == OrganizationRole.owner
                                ? null
                                : () => _openMemberSheet(context, member: m),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openMemberSheet(
    BuildContext context, {
    DemoMember? member,
  }) async {
    final message = await _showDarkSheet<String>(
      context,
      (_) => _MemberSheet(member: member),
    );
    if (message != null && context.mounted) _snack(context, message);
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.demo,
    required this.onTap,
  });

  final DemoMember member;
  final MultiStoreDemoState demo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final stores = member.role == OrganizationRole.owner
        ? 'Tous les points de vente'
        : demo.stores
            .where((s) => member.storeIds.contains(s.id))
            .map((s) => s.label)
            .join(', ');
    final initials = member.name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: MerchantColors.gold.withValues(alpha: 0.18),
                child: Text(
                  initials,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    color: MerchantColors.gold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.name,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (member.isPending) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  MerchantColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Invitation envoyée',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: MerchantColors.gold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stores.isEmpty ? 'Aucun point de vente' : stores,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: MerchantColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: MerchantColors.textGrey,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Invite a new member, or edit / remove an existing one.
class _MemberSheet extends ConsumerStatefulWidget {
  const _MemberSheet({this.member});

  final DemoMember? member;

  @override
  ConsumerState<_MemberSheet> createState() => _MemberSheetState();
}

class _MemberSheetState extends ConsumerState<_MemberSheet> {
  late final _nameCtrl = TextEditingController(text: widget.member?.name);
  late final _contactCtrl = TextEditingController(text: widget.member?.contact);
  late OrganizationRole _role =
      widget.member?.role ?? OrganizationRole.employee;
  late final Set<String> _storeIds = {...?widget.member?.storeIds};

  bool get _isEdit => widget.member != null;

  bool get _canSubmit =>
      _storeIds.isNotEmpty && (_isEdit || _contactCtrl.text.trim().isNotEmpty);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final notifier = ref.read(multiStoreDemoProvider.notifier);
    final member = widget.member;
    if (member != null) {
      notifier.updateMember(
        member.id,
        role: _role,
        storeIds: _storeIds.toList(),
      );
      Navigator.of(context).pop('${member.name} mis à jour');
    } else {
      notifier.invite(
        name: _nameCtrl.text,
        contact: _contactCtrl.text,
        role: _role,
        storeIds: _storeIds.toList(),
      );
      Navigator.of(context).pop(
        'Invitation envoyée à ${_contactCtrl.text.trim()}',
      );
    }
  }

  void _remove() {
    final member = widget.member!;
    ref.read(multiStoreDemoProvider.notifier).removeMember(member.id);
    Navigator.of(context).pop('${member.name} retiré de l\'équipe');
  }

  @override
  Widget build(BuildContext context) {
    final stores = ref.watch(multiStoreDemoProvider).stores;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        _sheetBottomInset(context),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sheetTitle(
              _isEdit ? widget.member!.name : 'Inviter un membre',
              _isEdit
                  ? widget.member!.contact
                  : 'Il recevra un lien pour rejoindre votre équipe.',
            ),
            if (!_isEdit) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                style: GoogleFonts.outfit(color: Colors.white),
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration('Nom', Icons.person_rounded),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contactCtrl,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.outfit(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(
                  'Téléphone ou email',
                  Icons.alternate_email_rounded,
                ),
              ),
            ],
            const SizedBox(height: 18),
            const _SectionLabel('RÔLE'),
            const SizedBox(height: 10),
            for (final role in const [
              OrganizationRole.manager,
              OrganizationRole.employee,
            ]) ...[
              _ChoiceTile(
                selected: _role == role,
                title: role.label,
                subtitle: _roleDescription(role),
                onTap: () => setState(() => _role = role),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
            const _SectionLabel('POINTS DE VENTE'),
            const SizedBox(height: 6),
            for (final s in stores)
              CheckboxListTile(
                value: _storeIds.contains(s.id),
                onChanged: (v) => setState(() {
                  if (v ?? false) {
                    _storeIds.add(s.id);
                  } else {
                    _storeIds.remove(s.id);
                  }
                }),
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeColor: MerchantColors.gold,
                checkColor: MerchantColors.bgHeader,
                side: const BorderSide(color: MerchantColors.textGrey),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  s.label,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                ),
                subtitle: Text(
                  s.city,
                  style: GoogleFonts.outfit(
                    color: MerchantColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _GoldFilledButton(
              label: _isEdit ? 'Enregistrer' : 'Envoyer l\'invitation',
              onPressed: _canSubmit ? _submit : null,
            ),
            if (_isEdit) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _remove,
                child: Text(
                  'Retirer de l\'équipe',
                  style: GoogleFonts.outfit(
                    color: Colors.red.shade300,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
