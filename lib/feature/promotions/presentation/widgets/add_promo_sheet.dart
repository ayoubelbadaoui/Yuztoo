import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../domain/entities/promotion.dart';
import 'client_type_details.dart';

/// Bottom sheet for creating a new promotion.
class AddPromoSheet extends StatefulWidget {
  const AddPromoSheet({super.key});

  @override
  State<AddPromoSheet> createState() => _AddPromoSheetState();
}

class _AddPromoSheetState extends State<AddPromoSheet> {
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  DateTime _dateFrom = DateTime.now();
  DateTime _dateTo = DateTime.now().add(const Duration(days: 14));
  ClientType _clientType = ClientType.gratuit;
  String? _imagePath;
  int _selectedTargetIndex = 0;
  int _selectedDistanceIndex = 0;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    super.dispose();
  }

  // ── actions ────────────────────────────────────────────────────────────────

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _dateFrom : _dateTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: MerchantColors.gold,
            surface: MerchantColors.navyCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => isFrom ? _dateFrom = picked : _dateTo = picked);
    }
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: MerchantColors.navyCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: MerchantColors.gold),
                title: Text('Galerie',
                    style: GoogleFonts.outfit(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: MerchantColors.gold),
                title: Text('Caméra',
                    style: GoogleFonts.outfit(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final picked = await _picker.pickImage(
          source: source, maxWidth: 800, maxHeight: 800, imageQuality: 80);
      if (picked != null && mounted) {
        setState(() => _imagePath = picked.path);
      }
    } catch (_) {}
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: MerchantColors.navyCard,
          content: Text('Veuillez entrer un titre',
              style: GoogleFonts.outfit(color: Colors.white)),
        ),
      );
      return;
    }
    final subtitle = _subtitleCtrl.text.trim().isNotEmpty
        ? _subtitleCtrl.text.trim()
        : 'Valide du ${_fmtD(_dateFrom)} au ${_fmtD(_dateTo)}';

    Navigator.pop(
      context,
      Promotion(
        title: title,
        subtitle: subtitle,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        selectedClientType: _clientType,
        isOnline: false,
        imagePath: _imagePath,
      ),
    );
  }

  String _fmtD(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 80),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: MerchantColors.bgMain,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSheetHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImagePicker(),
                  const SizedBox(height: 20),
                  _buildField(_titleCtrl, 'Titre de la promotion'),
                  const SizedBox(height: 12),
                  _buildField(_subtitleCtrl, 'Description (optionnel)'),
                  const SizedBox(height: 20),
                  _buildDateSection(),
                  const SizedBox(height: 20),
                  _buildClientTypeChips(),
                  const SizedBox(height: 16),
                  ClientTypeDetails(
                    clientType: _clientType,
                    selectedTargetIndex: _selectedTargetIndex,
                    selectedDistanceIndex: _selectedDistanceIndex,
                    onTargetChanged: (i) =>
                        setState(() => _selectedTargetIndex = i),
                    onDistanceChanged: (i) =>
                        setState(() => _selectedDistanceIndex = i),
                  ),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── sheet header ───────────────────────────────────────────────────────────

  Widget _buildSheetHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: MerchantColors.textGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Nouvelle promotion',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: MerchantColors.gold
                .withValues(alpha: MerchantColors.goldBorderAlpha),
          ),
        ],
      ),
    );
  }

  // ── image picker ───────────────────────────────────────────────────────────

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: MerchantColors.cream,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: _imagePath != null
            ? Image.file(File(_imagePath!), fit: BoxFit.cover)
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_photo_alternate_outlined,
                        color: Color(0xFF8B7355), size: 36),
                    const SizedBox(height: 4),
                    Text(
                      'Choisir une image',
                      style: GoogleFonts.outfit(
                          fontSize: 12, color: const Color(0xFF8B7355)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ── date section ───────────────────────────────────────────────────────────

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Validité',
            style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _pickDate(isFrom: true),
                child: _buildDateBox('Du ${_fmtD(_dateFrom)}'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _pickDate(isFrom: false),
                child: _buildDateBox('au ${_fmtD(_dateTo)}'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── client type chips ──────────────────────────────────────────────────────

  Widget _buildClientTypeChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Type de clients',
            style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        const SizedBox(height: 12),
        Row(
          children: [
            _chip('Gratuit', ClientType.gratuit),
            const SizedBox(width: 8),
            _chip('Premium', ClientType.premium),
            const SizedBox(width: 8),
            _chip('Payant', ClientType.payant),
          ],
        ),
      ],
    );
  }

  // ── submit ─────────────────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: MerchantColors.gold,
          foregroundColor: MerchantColors.darkOverlay,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(
          'Créer la promotion',
          style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: MerchantColors.darkOverlay),
        ),
      ),
    );
  }

  // ── reusable helpers ───────────────────────────────────────────────────────

  Widget _buildField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.outfit(color: MerchantColors.textGrey, fontSize: 14),
        filled: true,
        fillColor: MerchantColors.navyCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: MerchantColors.gold
                  .withValues(alpha: MerchantColors.goldBorderStronger)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: MerchantColors.gold
                  .withValues(alpha: MerchantColors.goldBorderStronger)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MerchantColors.gold),
        ),
      ),
    );
  }

  Widget _buildDateBox(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: MerchantColors.gold,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: MerchantColors.darkOverlay),
        ),
      ),
    );
  }

  Widget _chip(String label, ClientType type) {
    final isActive = _clientType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _clientType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? MerchantColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? MerchantColors.gold
                  : MerchantColors.textGrey.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? MerchantColors.darkOverlay
                    : MerchantColors.textLightGrey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
