import 'package:flutter/material.dart';

/// « Quitter l'inscription ? » — the only way out of an onboarding wizard
/// for a signed-in user (wrong Google / Apple account, changed their mind).
/// Progress stays saved on the device for that account.
///
/// Returns `true` when the user confirms signing out.
Future<bool> confirmLeaveOnboarding(
  BuildContext context, {
  String? accountLabel,
}) async {
  final account = accountLabel?.trim();
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF152A40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      title: const Text(
        'Quitter l\'inscription ?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      content: Text(
        '${account != null && account.isNotEmpty ? 'Vous êtes connecté avec $account.\n\n' : ''}'
        'Vous serez déconnecté. Ce que vous avez déjà rempli reste enregistré '
        'sur ce téléphone si vous revenez avec ce compte.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          height: 1.45,
          fontSize: 14,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            'Rester',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37),
            foregroundColor: const Color(0xFF0E2A44),
          ),
          child: const Text('Se déconnecter'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
