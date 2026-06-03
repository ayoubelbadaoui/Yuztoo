part of 'country_code_modal.dart';

class _CountryCodePickerSheet extends StatefulWidget {
  const _CountryCodePickerSheet({
    required this.selectedCountryCode,
    required this.onCountrySelected,
    required this.phoneController,
    required this.onPhoneNumberUpdate,
    required this.onRevalidatePhone,
  });

  final String selectedCountryCode;
  final void Function(String countryCode, String countryName, String countryFlag)
      onCountrySelected;
  final TextEditingController phoneController;
  final void Function(String) onPhoneNumberUpdate;
  final VoidCallback onRevalidatePhone;

  @override
  State<_CountryCodePickerSheet> createState() =>
      _CountryCodePickerSheetState();
}

class _CountryCodePickerSheetState extends State<_CountryCodePickerSheet> {
  late final TextEditingController _searchController;
  late List<Map<String, String>> _filteredCountries;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredCountries = SignupConstants.countryCodes;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SignupConstants.bgDark2,
                border: Border(
                  bottom: BorderSide(
                    color: SignupConstants.borderColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sélectionnez votre pays',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: SignupConstants.textLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(
                        color: SignupConstants.textLight, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un pays...',
                      hintStyle: const TextStyle(
                          color: SignupConstants.textGrey, fontSize: 13),
                      prefixIcon: const Icon(Icons.search,
                          color: SignupConstants.primaryGold),
                      filled: true,
                      fillColor: MerchantColors.inputFill,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: SignupConstants.borderColor, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: SignupConstants.borderColor, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: SignupConstants.primaryGold,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value.isEmpty) {
                          _filteredCountries = SignupConstants.countryCodes;
                        } else {
                          _filteredCountries = SignupConstants.countryCodes
                              .where((country) =>
                                  country['name']!
                                      .toLowerCase()
                                      .contains(value.toLowerCase()) ||
                                  country['code']!
                                      .contains(value.toLowerCase()))
                              .toList();
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _filteredCountries.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun pays trouvé',
                        style: TextStyle(
                          fontSize: 14,
                          color: SignupConstants.textGrey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _filteredCountries.length,
                      itemBuilder: (context, index) {
                        final country = _filteredCountries[index];
                        final isSelected =
                            widget.selectedCountryCode == country['code'];

                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            final countryCode = country['code']!;
                            final countryName = country['name']!;
                            final countryFlag = country['flag']!;

                            widget.onCountrySelected(
                                countryCode, countryName, countryFlag);

                            if (widget.phoneController.text.isNotEmpty) {
                              final digitsOnly = widget.phoneController.text
                                  .replaceAll(RegExp(r'[^\d]'), '');
                              final updatedPhone =
                                  PhoneFormatter.formatPhoneNumber(
                                countryCode,
                                digitsOnly,
                              );
                              widget.onPhoneNumberUpdate(updatedPhone);
                            }

                            if (widget.phoneController.text.isNotEmpty) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                widget.onRevalidatePhone();
                              });
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: isSelected
                                  ? SignupConstants.primaryGold
                                      .withValues(alpha: 0.15)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? SignupConstants.primaryGold
                                    : Colors.transparent,
                                width: isSelected ? 2 : 0,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        country['flag']!,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              country['name']!,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isSelected
                                                    ? SignupConstants
                                                        .primaryGold
                                                    : SignupConstants
                                                        .textLight,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.w400,
                                              ),
                                            ),
                                            Text(
                                              country['code']!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isSelected
                                                    ? SignupConstants
                                                        .primaryGold
                                                        .withValues(alpha: 0.7)
                                                    : SignupConstants.textGrey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: SignupConstants.primaryGold,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
