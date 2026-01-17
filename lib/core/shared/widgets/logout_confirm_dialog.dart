import 'package:flutter/material.dart';

import '../../../theme.dart';

/// Shows a confirmation dialog before logging out.
Future<bool> showLogoutConfirmationDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: YColors.primary),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
