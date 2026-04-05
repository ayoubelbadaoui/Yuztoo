import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../domain/entities/promotion.dart';

part 'promo_card.part.dart';

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

  @override
  Widget build(BuildContext context) => _buildPromoCard(context);
}
