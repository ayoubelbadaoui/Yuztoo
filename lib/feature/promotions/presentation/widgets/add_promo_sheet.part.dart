part of 'add_promo_sheet.dart';

extension _AddPromoSheetUi on _AddPromoSheetState {
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
        onTap: () => _onClientTypeSelected(type),
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
