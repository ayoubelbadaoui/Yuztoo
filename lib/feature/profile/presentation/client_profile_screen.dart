import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/shared/widgets/logout_confirm_dialog.dart';
import '../../auth/core/application/providers.dart';

class ClientProfileScreen extends ConsumerStatefulWidget {
  const ClientProfileScreen({super.key});

  static String get path => '/client-profile';

  @override
  ConsumerState<ClientProfileScreen> createState() =>
      _ClientProfileScreenState();
}

class _ClientProfileScreenState extends ConsumerState<ClientProfileScreen> {
  bool pushEnabled = true;
  bool emailEnabled = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: YColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.myProfile,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                        color: YColors.secondary, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Text('M',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mohammed Ali',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('mohammed@email.com',
                          style: TextStyle(color: Colors.white70)),
                      SizedBox(height: 2),
                      Text('+212 6XX XXX XXX',
                          style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _Section(
          title: AppLocalizations.of(context)!.account,
          children: [
            _NavRow(
              icon: Icons.person_outline,
              label: AppLocalizations.of(context)!.personalInfo,
            ),
            _NavRow(
              icon: Icons.credit_card,
              label: AppLocalizations.of(context)!.paymentMethods,
            ),
          ],
        ),
        _Section(
          title: AppLocalizations.of(context)!.preferences,
          children: [
            _SwitchRow(
              icon: Icons.notifications_none,
              label: AppLocalizations.of(context)!.pushNotifications,
              value: pushEnabled,
              onChanged: (val) => setState(() => pushEnabled = val),
            ),
            _SwitchRow(
              icon: Icons.email_outlined,
              label: AppLocalizations.of(context)!.emailNotifications,
              value: emailEnabled,
              onChanged: (val) => setState(() => emailEnabled = val),
            ),
            _NavRow(
              icon: Icons.settings_outlined,
              label: AppLocalizations.of(context)!.settings,
            ),
          ],
        ),
        _Section(
          title: l10n.support,
          children: [
            _NavRow(
              icon: Icons.help_outline,
              label: l10n.helpCenter,
            ),
            _NavRow(
              icon: Icons.description_outlined,
              label: l10n.termsOfUse,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showLogoutConfirmationDialog(context);
              if (confirm) {
                // Real logout via AuthController
                await ref.read(authControllerProvider.notifier).signOut();
              }
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: Text(
              AppLocalizations.of(context)!.disconnect,
              style: const TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.version('1.0.0'),
              style: const TextStyle(color: YColors.muted),
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: YColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: List.generate(children.length * 2 - 1, (index) {
                if (index.isOdd) return const Divider(height: 1);
                return children[index ~/ 2];
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: YColors.muted),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: YColors.muted),
      onTap: () {},
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.onChanged});

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(label),
      secondary: Icon(icon, color: YColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      activeThumbColor: YColors.secondary,
    );
  }
}
