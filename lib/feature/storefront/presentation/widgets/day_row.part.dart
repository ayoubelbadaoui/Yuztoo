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
            for (int i = 0; i < _editableSlots.length; i++) ...[
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
    final slot = _editableSlots[index];
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
        Expanded(
          child: TimeSlotPicker(
            startTime: slot.start,
            endTime: slot.end,
            onStartChanged: (v) => _updateStart(index, v),
            onEndChanged: (v) => _updateEnd(index, v),
          ),
        ),
        if (_editableSlots.length > 1) ...[
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
}
