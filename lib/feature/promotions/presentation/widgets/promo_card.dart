import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../domain/entities/promotion.dart';

/// A single promotion card displaying image, title, validity, client type,
/// toggle and delete action.
class PromoCard extends StatelessWidget {
  const PromoCard({
    super.key,
    required this.promo,
    required this.onToggle,
    required this.onDelete,
    required this.onPickImage,
  });

  final Promotion promo;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onPickImage;

  // ── helpers ────────────────────────────────────────────────────────────────

  String _fmt(DateTime d, {String prefix = ''}) =>
      '$prefix${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  Widget _datePill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: MerchantColors.gold,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: MerchantColors.darkOverlay,
        ),
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MerchantColors.bgHeader,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MerchantColors.gold
              .withValues(alpha: MerchantColors.goldBorderStronger),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(),
          _buildValidityRow(),
          _buildClientsRow(),
          _buildActions(),
        ],
      ),
    );
  }

  // ── header: image + title ──────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onPickImage,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: MerchantColors.bgHeader,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: MerchantColors.gold.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: promo.imagePath != null
                  ? Image.file(
                      File(promo.imagePath!),
                      fit: BoxFit.cover,
                      width: 60,
                      height: 60,
                    )
                  : const Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: MerchantColors.gold,
                        size: 28,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: MerchantColors.bgHeader,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: MerchantColors.gold.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    promo.title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    promo.subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: MerchantColors.textGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── validity row ───────────────────────────────────────────────────────────

  Widget _buildValidityRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
              color: MerchantColors.gold.withValues(alpha: 0.2), width: 1),
          bottom: BorderSide(
              color: MerchantColors.gold.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Validité',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          _datePill(_fmt(promo.dateFrom, prefix: 'Du ')),
          const SizedBox(width: 12),
          _datePill(_fmt(promo.dateTo, prefix: 'au ')),
        ],
      ),
    );
  }

  // ── clients row ────────────────────────────────────────────────────────────

  Widget _buildClientsRow() {
    final typeLabel = switch (promo.selectedClientType) {
      ClientType.gratuit => 'Gratuit',
      ClientType.premium => 'Premium',
      ClientType.payant => 'Payant',
    };
    final pillLabel = switch (promo.selectedClientType) {
      ClientType.gratuit => 'Tous mes clients',
      ClientType.premium => 'Ciblées',
      ClientType.payant => 'Clients Yuztoo',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: MerchantColors.gold.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Clients',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            typeLabel,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: MerchantColors.gold,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: MerchantColors.gold,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              pillLabel,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: MerchantColors.darkOverlay,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── actions: toggle + delete ───────────────────────────────────────────────

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildToggle(),
              const SizedBox(width: 8),
              Text(
                'Mettre en ligne',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: MerchantColors.textGrey,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.delete_outline,
                color: MerchantColors.gold,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return GestureDetector(
      onTap: () => onToggle(!promo.isOnline),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 40,
        height: 24,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: promo.isOnline
              ? MerchantColors.gold
              : const Color(0xFF444444),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 300),
          alignment:
              promo.isOnline ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
