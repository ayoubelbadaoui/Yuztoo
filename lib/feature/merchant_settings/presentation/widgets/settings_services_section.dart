import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';

/// Service toggle item data.
class ServiceToggle {
  final IconData? icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTap;
  /// When true, the toggle thumb is hidden and the row acts as a pure nav link.
  final bool navOnly;

  const ServiceToggle({
    this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onTap,
    this.navOnly = false,
  });
}

/// "SERVICES YUZTOO" section with toggle switches.
class SettingsServicesSection extends StatelessWidget {
  const SettingsServicesSection({super.key, required this.services});

  final List<ServiceToggle> services;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SERVICES YUZTOO',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: MerchantColors.textGrey,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < services.length; i++)
            _serviceItem(
              service: services[i],
              isLast: i == services.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _serviceItem({
    required ServiceToggle service,
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: service.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: MerchantColors.gold
                        .withValues(alpha: MerchantColors.goldBorderAlpha),
                    width: 1,
                  ),
                ),
        ),
        child: Row(
          children: [
            if (service.icon != null) ...[
              Icon(service.icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                service.label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
            if (service.navOnly)
              const Icon(Icons.chevron_right_rounded,
                  color: MerchantColors.textGrey, size: 20)
            else
              GestureDetector(
                onTap: () => service.onChanged(!service.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 48,
                  height: 28,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: service.value
                        ? MerchantColors.gold
                        : const Color(0xFF444444),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 300),
                    alignment: service.value
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

