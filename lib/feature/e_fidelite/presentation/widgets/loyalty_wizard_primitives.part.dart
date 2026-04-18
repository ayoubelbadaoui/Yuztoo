part of 'loyalty_configuration_wizard.dart';

// ─── Shared utility ───────────────────────────────────────────────────────────

/// Snaps [current] to the nearest value in [options] (by absolute distance).
/// Used by chip pickers and dropdown defaults to avoid out-of-range selections.
T _nearest<T extends num>(T current, List<T> options) {
  if (options.contains(current)) return current;
  T best = options.first;
  var bestDist = (current - best).abs();
  for (final o in options) {
    final d = (current - o).abs();
    if (d < bestDist) {
      best = o;
      bestDist = d;
    }
  }
  return best;
}

// ─── Step section scaffold ────────────────────────────────────────────────────
//
// Renders the bold question headline + optional subtitle + child content with
// consistent spacing. Every wizard step wraps its content in this.

class _StepSection extends StatelessWidget {
  const _StepSection({
    required this.question,
    this.subtitle,
    required this.child,
  });

  final String question;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          question,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.35,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: MerchantColors.textLightGrey,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 20),
        child,
      ],
    );
  }
}

// ─── Big choice card ──────────────────────────────────────────────────────────
//
// Full-width tappable card for binary / multi-choice steps (Activation,
// Trigger type, Validation). Features icon, title, description and an
// animated gold border + checkmark when selected.

class _BigChoiceCard extends StatelessWidget {
  const _BigChoiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  /// When true and not selected, the icon renders in grey (lower visual weight).
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected
        ? MerchantColors.gold
        : (muted ? MerchantColors.textLightGrey : MerchantColors.gold);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected
                ? MerchantColors.gold.withValues(alpha: 0.1)
                : MerchantColors.bgHeader.withValues(alpha: 0.55),
            border: Border.all(
              color: selected
                  ? MerchantColors.gold
                  : MerchantColors.gold.withValues(alpha: muted ? 0.15 : 0.25),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (selected
                          ? MerchantColors.gold
                          : (muted
                              ? MerchantColors.textLightGrey
                              : MerchantColors.gold))
                      .withValues(alpha: selected ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: MerchantColors.textLightGrey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedOpacity(
                opacity: selected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: MerchantColors.gold,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Value chip picker ────────────────────────────────────────────────────────
//
// Chip grid replacing dropdowns for threshold / validity / percentage pickers.
// Wraps items in a Wrap so they reflow naturally. Selected chip turns gold-fill.

class _ValueChipPicker<T> extends StatelessWidget {
  const _ValueChipPicker({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    this.unit,
  });

  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  /// Optional label shown below the chips for context (e.g. "passages").
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final selected = item == value;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(item),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color:
                        selected ? MerchantColors.gold : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? MerchantColors.gold
                          : MerchantColors.gold.withValues(alpha: 0.35),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    labelBuilder(item),
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? MerchantColors.darkOverlay
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (unit != null) ...[
          const SizedBox(height: 10),
          Text(
            unit!,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: MerchantColors.textLightGrey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Condition card ───────────────────────────────────────────────────────────
//
// Card with icon + label + toggle. An optional [expandedChild] slides in with
// AnimatedSize when the toggle is enabled. Used on the Conditions and Options
// steps. Pass [disabled]=true to dim the card and lock the toggle.

class _ConditionCard extends StatelessWidget {
  const _ConditionCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.expandedChild,
    this.disabled = false,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? expandedChild;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.55 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value
                ? MerchantColors.gold.withValues(alpha: 0.55)
                : MerchantColors.gold.withValues(alpha: 0.2),
            width: value ? 1.5 : 1,
          ),
          color: MerchantColors.bgHeader.withValues(alpha: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header row ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: MerchantColors.gold.withValues(
                          alpha: value ? 0.15 : 0.07),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, color: MerchantColors.gold, size: 17),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Switch(
                    value: value,
                    activeThumbColor: MerchantColors.darkOverlay,
                    activeTrackColor: MerchantColors.gold,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFF6B5B4F),
                    onChanged: disabled ? null : onChanged,
                  ),
                ],
              ),
            ),
            // ── Animated expanded body ───────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: (value && expandedChild != null)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Divider(
                          height: 1,
                          color: MerchantColors.gold.withValues(alpha: 0.18),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: expandedChild!,
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dropdown card ────────────────────────────────────────────────────────────
//
// Gold-bordered dropdown used inside reward config panels where a chip picker
// would be too wide (e.g. free-label selections).

class _DropdownCard<T> extends StatelessWidget {
  const _DropdownCard({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MerchantColors.gold.withValues(alpha: 0.5),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            dropdownColor: MerchantColors.bgHeader,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
            iconEnabledColor: MerchantColors.gold,
            items: items
                .map(
                  (e) => DropdownMenuItem<T>(
                    value: e,
                    child: Text(labelBuilder(e)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ),
    );
  }
}

// ─── Segment button ───────────────────────────────────────────────────────────
//
// Compact icon + label toggle used inside config panels for binary mode switches
// (e.g. Percentage vs Fixed amount in the voucher panel).

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: selected ? MerchantColors.gold : Colors.transparent,
            border: Border.all(
              color: selected
                  ? MerchantColors.gold
                  : MerchantColors.gold.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected
                    ? MerchantColors.darkOverlay
                    : MerchantColors.gold,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? MerchantColors.darkOverlay
                        : MerchantColors.gold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Free product name field ──────────────────────────────────────────────────
//
// Stateful TextField for the free-product reward label. Syncs its controller
// with the notifier on every keystroke, and handles external hydration via
// didUpdateWidget so the field stays consistent across Riverpod rebuilds.

class _FreeProductNameField extends StatefulWidget {
  const _FreeProductNameField({
    required this.initialText,
    required this.onChanged,
  });

  final String initialText;
  final ValueChanged<String> onChanged;

  @override
  State<_FreeProductNameField> createState() => _FreeProductNameFieldState();
}

class _FreeProductNameFieldState extends State<_FreeProductNameField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.addListener(() => widget.onChanged(_controller.text));
  }

  @override
  void didUpdateWidget(covariant _FreeProductNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only overwrite when the source-of-truth changed from outside (hydration).
    if (widget.initialText != oldWidget.initialText &&
        widget.initialText != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.initialText,
        selection:
            TextSelection.collapsed(offset: widget.initialText.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textCapitalization: TextCapitalization.sentences,
      scrollPadding: const EdgeInsets.only(bottom: 160, top: 48),
      maxLength: 80,
      buildCounter: (
        context, {
        required currentLength,
        required isFocused,
        maxLength,
      }) {
        if (maxLength == null) return null;
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '$currentLength / $maxLength',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: MerchantColors.textLightGrey.withValues(alpha: 0.85),
            ),
          ),
        );
      },
      style: GoogleFonts.outfit(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Nom du produit offert',
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: GoogleFonts.outfit(
          color: MerchantColors.gold.withValues(alpha: 0.95),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        hintText: 'Ex. : Café, pizza margherita, dessert du jour…',
        hintStyle: GoogleFonts.outfit(
          color: MerchantColors.textLightGrey,
          fontSize: 13,
        ),
        filled: true,
        fillColor: MerchantColors.bgMain.withValues(alpha: 0.65),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: MerchantColors.gold.withValues(alpha: 0.45),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: MerchantColors.gold.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: MerchantColors.gold, width: 1.75),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
