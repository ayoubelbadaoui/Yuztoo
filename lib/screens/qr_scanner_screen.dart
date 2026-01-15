import 'package:flutter/material.dart';
import '../theme.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key, required this.onBack, required this.onScanSuccess});

  final VoidCallback onBack;
  final VoidCallback onScanSuccess;

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  @override
  Widget build(BuildContext context) {
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
                  IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back)),
                  const SizedBox(width: 8),
                  Text('Scanner QR Code', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Card(
                    color: YColors.accent,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Center(
                        child: SizedBox(
                          width: 260,
                          height: 260,
                          child: Stack(
                            children: [
                              const Positioned.fill(
                                child: CustomPaint(
                                  painter: _CornerPainter(color: YColors.secondary),
                                ),
                              ),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(seconds: 2),
                                curve: Curves.easeInOut,
                                onEnd: () => setState(() {}),
                                builder: (context, value, child) {
                                  final dy = (260 - 4) * value;
                                  return Positioned(
                                    top: dy,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 4,
                                      color: YColors.secondary.withValues(alpha: 0.9),
                                    ),
                                  );
                                },
                              ),
                              const Center(
                                child: Icon(Icons.qr_code_2, size: 64, color: Colors.black26),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Scannez le QR code du commerce', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  const Text(
                    'Positionnez le QR code dans le cadre pour vous connecter',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: YColors.muted),
                  ),
                  const SizedBox(height: 18),
                  const Card(
                    color: YColors.accent,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: YColors.secondary),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Le QR code est généralement affiché à la caisse ou à l\'entrée du commerce. Demandez au commerçant si vous ne le trouvez pas.',
                              style: TextStyle(color: YColors.muted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onScanSuccess,
                      child: const Text('Scanner un code de test'),
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
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    const radius = 18.0;
    const length = 32.0;

    // top-left
    canvas.drawPath(_cornerPath(const Offset(0, 0), radius, length, Corner.topLeft), paint);
    // top-right
    canvas.drawPath(
        _cornerPath(Offset(size.width, 0), radius, length, Corner.topRight), paint);
    // bottom-left
    canvas.drawPath(
        _cornerPath(Offset(0, size.height), radius, length, Corner.bottomLeft), paint);
    // bottom-right
    canvas.drawPath(
        _cornerPath(Offset(size.width, size.height), radius, length, Corner.bottomRight), paint);
  }

  Path _cornerPath(Offset origin, double radius, double length, Corner corner) {
    final path = Path();
    switch (corner) {
      case Corner.topLeft:
        path.moveTo(origin.dx + radius, origin.dy);
        path.lineTo(origin.dx + length, origin.dy);
        path.moveTo(origin.dx, origin.dy + radius);
        path.lineTo(origin.dx, origin.dy + length);
        break;
      case Corner.topRight:
        path.moveTo(origin.dx - radius, origin.dy);
        path.lineTo(origin.dx - length, origin.dy);
        path.moveTo(origin.dx, origin.dy + radius);
        path.lineTo(origin.dx, origin.dy + length);
        break;
      case Corner.bottomLeft:
        path.moveTo(origin.dx + radius, origin.dy);
        path.lineTo(origin.dx + length, origin.dy);
        path.moveTo(origin.dx, origin.dy - radius);
        path.lineTo(origin.dx, origin.dy - length);
        break;
      case Corner.bottomRight:
        path.moveTo(origin.dx - radius, origin.dy);
        path.lineTo(origin.dx - length, origin.dy);
        path.moveTo(origin.dx, origin.dy - radius);
        path.lineTo(origin.dx, origin.dy - length);
        break;
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

enum Corner { topLeft, topRight, bottomLeft, bottomRight }
