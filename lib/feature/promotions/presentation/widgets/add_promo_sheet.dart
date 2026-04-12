import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/shared/constants/merchant_colors.dart';
import '../../domain/entities/promotion.dart';
import 'client_type_details.dart';

part 'add_promo_sheet.part.dart';

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
        id: '',
        merchantId: '',
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

  void _onTargetChanged(int i) {
    setState(() => _selectedTargetIndex = i);
  }

  void _onDistanceChanged(int i) {
    setState(() => _selectedDistanceIndex = i);
  }

  void _onClientTypeSelected(ClientType type) {
    setState(() => _clientType = type);
  }

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
                    onTargetChanged: _onTargetChanged,
                    onDistanceChanged: _onDistanceChanged,
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
}
