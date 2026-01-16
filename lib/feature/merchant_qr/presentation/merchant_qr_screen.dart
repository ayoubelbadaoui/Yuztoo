import 'dart:math';
import 'package:flutter/material.dart';
import '../../../theme.dart';

class MerchantQRCodeScreen extends StatelessWidget {
  const MerchantQRCodeScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final pattern = _generatePattern();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                      onPressed: onBack, icon: const Icon(Icons.arrow_back)),
                  const SizedBox(width: 8),
                  Text('Mon QR Code',
                      style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Code de connexion',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  const Text(
                    'Les clients scannent ce code pour se connecter à votre commerce',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: YColors.muted),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border:
                                  Border.all(color: YColors.primary, width: 8),
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.white,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: SizedBox(
                                width: 220,
                                height: 220,
                                child: GridView.builder(
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 8,
                                          mainAxisSpacing: 2,
                                          crossAxisSpacing: 2),
                                  itemCount: pattern.length,
                                  itemBuilder: (context, index) => Container(
                                    color: pattern[index]
                                        ? YColors.primary
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: YColors.secondary,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 12,
                                    offset: Offset(0, 6))
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Text('Y',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: YColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('CAFE-CENTRAL-2024',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download_outlined),
                          label: const Text('Télécharger'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('Partager'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Card(
                    color: YColors.accent,
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.qr_code_2, color: YColors.secondary),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '• Imprimez et affichez à la caisse\n• Partagez sur vos réseaux sociaux\n• Ajoutez-le à vos cartes de visite',
                              style: TextStyle(color: YColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<bool> _generatePattern() {
    final random = Random(7);
    return List<bool>.generate(64, (_) => random.nextBool());
  }
}
