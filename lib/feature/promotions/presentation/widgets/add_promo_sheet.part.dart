part of 'add_promo_sheet.dart';

const int _kTitleMax = 40;
const int _kDescMax = 80;

extension _AddPromoSheetUi on _AddPromoSheetState {
  // ── sheet header ───────────────────────────────────────────────────────────

  Widget _buildSheetHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          const SizedBox(height: 14),
          Row(
            children: [
              // Icon pill
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: MerchantColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(Icons.local_offer_rounded,
                      color: MerchantColors.gold, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nouvelle promotion',
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              // Close ×
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: MerchantColors.textGrey.withValues(alpha: 0.4),
                        width: 1),
                  ),
                  child: const Center(
                    child: Icon(Icons.close_rounded,
                        color: MerchantColors.textGrey, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
    return Stack(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: _imagePath != null
                  ? Colors.transparent
                  : MerchantColors.navyCard,
              borderRadius: BorderRadius.circular(12),
              border: _imagePath == null
                  ? Border.all(
                      color: MerchantColors.gold.withValues(alpha: 0.35),
                      width: 1.5,
                      strokeAlign: BorderSide.strokeAlignCenter,
                    )
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: _imagePath != null
                ? Image.file(File(_imagePath!), fit: BoxFit.cover)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: MerchantColors.gold.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            color: MerchantColors.gold,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Ajouter une image',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: MerchantColors.gold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Recommandé : 800 × 800 px',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: MerchantColors.textGrey,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        // Remove image button overlay
        if (_imagePath != null)
          Positioned(
            top: 8,
            right: 8,
              child: GestureDetector(
                  onTap: _clearImage,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.close_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
        // Change image overlay (bottom right)
        if (_imagePath != null)
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_rounded,
                        size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Modifier',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── date section ───────────────────────────────────────────────────────────

  Widget _buildDateSection() {
    final invalid = !_dateTo.isAfter(_dateFrom);
    final duration = _dateTo.difference(_dateFrom).inDays + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Validité',
                style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            const Spacer(),
            if (!invalid)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: MerchantColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Durée : $duration jour${duration > 1 ? 's' : ''}',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: MerchantColors.gold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _pickDate(isFrom: true),
                child: _buildDateBox('Du ${_fmtD(_dateFrom)}',
                    isError: false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => _pickDate(isFrom: false),
                child: _buildDateBox('au ${_fmtD(_dateTo)}',
                    isError: invalid),
              ),
            ),
          ],
        ),
        if (invalid) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 12, color: Colors.redAccent),
              const SizedBox(width: 4),
              Text(
                'La fin doit être après le début',
                style: GoogleFonts.outfit(
                    fontSize: 10, color: Colors.redAccent),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── client type chips ──────────────────────────────────────────────────────

  Widget _buildClientTypeChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Audience',
            style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        const SizedBox(height: 4),
        Text('Qui recevra cette promotion ?',
            style: GoogleFonts.outfit(
                fontSize: 11,
                color: MerchantColors.textGrey)),
        const SizedBox(height: 12),
        Row(
          children: [
            _chip('Mes clients', ClientType.gratuit, Icons.people_outline_rounded,
                subtitle: 'Gratuit'),
            const SizedBox(width: 8),
            _chip('Ciblés', ClientType.premium, Icons.tune_rounded,
                subtitle: '5 € HT'),
            const SizedBox(width: 8),
            _chip('Yuztoo', ClientType.payant, Icons.public_rounded,
                subtitle: '0.10 €/client'),
          ],
        ),
      ],
    );
  }

  // ── submit ─────────────────────────────────────────────────────────────────

  Widget _buildSubmitButton() {
    final canSubmit = _titleCtrl.text.trim().isNotEmpty &&
        _dateTo.isAfter(_dateFrom);
    return GestureDetector(
      onTap: canSubmit ? _submit : null,
      child: AnimatedOpacity(
        opacity: canSubmit ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 180),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [MerchantColors.gold, Color(0xFFD4AF37)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: canSubmit
                ? [
                    BoxShadow(
                      color: MerchantColors.gold.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_rounded,
                    color: MerchantColors.darkOverlay, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Créer la promotion',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: MerchantColors.darkOverlay,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── reusable helpers ───────────────────────────────────────────────────────

  Widget _buildField(
    TextEditingController controller,
    String hint, {
    required int maxLength,
    String? label,
  }) {
    final count = controller.text.length;
    final nearLimit = count >= (maxLength * 0.8).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
          maxLength: maxLength,
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
              null, // Hide default counter; we draw our own below
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                GoogleFonts.outfit(color: MerchantColors.textGrey, fontSize: 14),
            filled: true,
            fillColor: MerchantColors.inputFill,
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
        ),
        // Custom char counter
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 4, right: 2),
            child: Text(
              '$count / $maxLength',
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: nearLimit
                    ? Colors.redAccent
                    : MerchantColors.textGrey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubtitlePreview() {
    if (_subtitleCtrl.text.trim().isNotEmpty) return const SizedBox.shrink();
    final preview =
        'Valide du ${_fmtD(_dateFrom)} au ${_fmtD(_dateTo)}';
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded,
              size: 11, color: MerchantColors.gold),
          const SizedBox(width: 5),
          Text(
            'Aperçu → $preview',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: MerchantColors.textLightGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBox(String label, {required bool isError}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isError
            ? Colors.redAccent.withValues(alpha: 0.08)
            : MerchantColors.gold,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError ? Colors.redAccent : MerchantColors.gold,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isError ? Colors.redAccent : MerchantColors.darkOverlay,
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, ClientType type, IconData icon,
      {required String subtitle}) {
    final isActive = _clientType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onClientTypeSelected(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? MerchantColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? MerchantColors.gold
                  : MerchantColors.textGrey.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? MerchantColors.darkOverlay
                    : MerchantColors.textLightGrey,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? MerchantColors.darkOverlay
                      : MerchantColors.textLightGrey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  color: isActive
                      ? MerchantColors.darkOverlay.withValues(alpha: 0.65)
                      : MerchantColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
