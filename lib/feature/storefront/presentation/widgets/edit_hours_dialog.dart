import 'package:flutter/material.dart';
import '../../domain/entities/business_hours.dart';
import 'storefront_colors.dart';

/// Dialog for editing business hours for a day
class EditHoursDialog extends StatefulWidget {
  const EditHoursDialog({
    super.key,
    required this.dayHours,
    required this.onSave,
  });

  final DayHours dayHours;
  final ValueChanged<List<TimeSlot>> onSave;

  @override
  State<EditHoursDialog> createState() => _EditHoursDialogState();
}

class _EditHoursDialogState extends State<EditHoursDialog> {
  late List<TimeSlot> _timeSlots;
  final List<TextEditingController> _startControllers = [];
  final List<TextEditingController> _endControllers = [];
  final List<FocusNode> _focusNodes = [];

  @override
  void initState() {
    super.initState();
    _timeSlots = List.from(widget.dayHours.timeSlots);
    // If day is closed or has no time slots, start with one default slot
    if (_timeSlots.isEmpty) {
      _timeSlots.add(const TimeSlot(start: '8h', end: '12h'));
    }
    _initializeControllers();
  }

  void _initializeControllers() {
    for (final slot in _timeSlots) {
      _startControllers.add(TextEditingController(text: slot.start));
      _endControllers.add(TextEditingController(text: slot.end));
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (final controller in _startControllers) {
      controller.dispose();
    }
    for (final controller in _endControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _addTimeSlot() {
    setState(() {
      _timeSlots.add(const TimeSlot(start: '8h', end: '12h'));
      _startControllers.add(TextEditingController(text: '8h'));
      _endControllers.add(TextEditingController(text: '12h'));
      _focusNodes.add(FocusNode());
    });
    // Focus on the new time slot's start field
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_focusNodes.isNotEmpty) {
        _focusNodes.last.requestFocus();
      }
    });
  }

  void _removeTimeSlot(int index) {
    if (_timeSlots.length > 1) {
      setState(() {
        _timeSlots.removeAt(index);
        _startControllers[index].dispose();
        _endControllers[index].dispose();
        _focusNodes[index].dispose();
        _startControllers.removeAt(index);
        _endControllers.removeAt(index);
        _focusNodes.removeAt(index);
      });
    }
  }

  void _save() {
    final updatedSlots = <TimeSlot>[];
    for (int i = 0; i < _timeSlots.length; i++) {
      final start = _startControllers[i].text.trim();
      final end = _endControllers[i].text.trim();
      if (start.isNotEmpty && end.isNotEmpty) {
        updatedSlots.add(TimeSlot(start: start, end: end));
      }
    }
    if (updatedSlots.isEmpty) {
      // Show error if no valid slots
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins un créneau horaire'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    widget.onSave(updatedSlots);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.dayHours.isClosed
                          ? Colors.grey[200]!
                          : StorefrontColors.primaryGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.dayHours.isClosed ? Icons.event_busy : Icons.access_time,
                      color: widget.dayHours.isClosed
                          ? Colors.grey[600]
                          : StorefrontColors.primaryGold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modifier les horaires',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: StorefrontColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              widget.dayHours.dayName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: StorefrontColors.textSecondary,
                              ),
                            ),
                            if (widget.dayHours.isClosed) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Fermé',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Créneaux horaires',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (widget.dayHours.isClosed) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(Ajoutez des horaires pour ouvrir ce jour)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[500],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_timeSlots.length, (index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: index < _timeSlots.length - 1 ? 16 : 0),
                        child: _TimeSlotCard(
                          index: index,
                          startController: _startControllers[index],
                          endController: _endControllers[index],
                          focusNode: _focusNodes[index],
                          canDelete: _timeSlots.length > 1,
                          onDelete: () => _removeTimeSlot(index),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    // Add button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _addTimeSlot,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: StorefrontColors.primaryGold.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: StorefrontColors.primaryGold.withValues(alpha: 0.2),
                              width: 1.5,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                size: 20,
                                color: StorefrontColors.primaryGold,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ajouter un créneau',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: StorefrontColors.primaryGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer buttons
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: StorefrontColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StorefrontColors.primaryGold,
                      foregroundColor: StorefrontColors.navyDark,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Enregistrer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSlotCard extends StatelessWidget {
  const _TimeSlotCard({
    required this.index,
    required this.startController,
    required this.endController,
    required this.focusNode,
    required this.canDelete,
    required this.onDelete,
  });

  final int index;
  final TextEditingController startController;
  final TextEditingController endController;
  final FocusNode focusNode;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Index badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: StorefrontColors.primaryGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: StorefrontColors.primaryGold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Time inputs
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _TimeInputField(
                    controller: startController,
                    label: 'Début',
                    focusNode: focusNode,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                ),
                Expanded(
                  child: _TimeInputField(
                    controller: endController,
                    label: 'Fin',
                    focusNode: null,
                  ),
                ),
              ],
            ),
          ),
          if (canDelete) ...[
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeInputField extends StatelessWidget {
  const _TimeInputField({
    required this.controller,
    required this.label,
    this.focusNode,
  });

  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: StorefrontColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: StorefrontColors.primaryGold,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}
