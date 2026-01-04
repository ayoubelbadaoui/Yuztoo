import 'package:flutter/material.dart';
import '../theme.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key, required this.onBack, required this.onVerify, required this.phone});

  final VoidCallback onBack;
  final VoidCallback onVerify;
  final String phone;

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 6) {
      Future.delayed(const Duration(milliseconds: 300), widget.onVerify);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: IconButton(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: YColors.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Text('Y', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 18),
              Text('Vérification', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Entrez le code envoyé au ${widget.phone}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: YColors.muted),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    child: TextField(
                      controller: _controllers[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      onChanged: (_) => _onChanged(),
                      decoration: const InputDecoration(counterText: ''),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: YColors.muted),
                child: const Text('Renvoyer le code'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
