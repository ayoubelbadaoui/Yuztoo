part of 'day_row.dart';

extension _DayRowStateUi on _DayRowState {
  Widget _buildSummaryPill() {
    final label = _expanded
        ? 'Masquer'
        : 'Voir ($_slotCount créneau${_slotCount > 1 ? 'x' : ''})';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: StorefrontColors.primaryGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: StorefrontColors.primaryGold,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            _expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 14,
            color: StorefrontColors.primaryGold,
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          children: [
            for (int i = 0; i < _startCtrls.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _buildSlotRow(i),
            ],
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _addSlot,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color:
                      StorefrontColors.primaryGold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        StorefrontColors.primaryGold.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded,
                        size: 18, color: StorefrontColors.primaryGold),
                    SizedBox(width: 4),
                    Text(
                      'Ajouter un créneau',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: StorefrontColors.primaryGold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _saveChanges,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: StorefrontColors.primaryGold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'Enregistrer',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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

  Widget _buildSlotRow(int index) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: StorefrontColors.primaryGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: StorefrontColors.primaryGold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: _buildTimeField(_startCtrls[index])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward_rounded,
              size: 14, color: Colors.grey[400]),
        ),
        Expanded(child: _buildTimeField(_endCtrls[index])),
        if (_startCtrls.length > 1) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _removeSlot(index),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 14, color: Colors.red),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeField(TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: StorefrontColors.textPrimary,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
              color: StorefrontColors.primaryGold, width: 2),
        ),
      ),
    );
  }
}
