import 'package:flutter/material.dart';
import '../constants/signup_constants.dart';
import '../utils/phone_formatter.dart';

class CountryCodeModal {
  static void show(
    BuildContext context, {
    required String selectedCountryCode,
    required Function(String countryCode, String countryName, String countryFlag) onCountrySelected,
    required TextEditingController phoneController,
    required Function(String) onPhoneNumberUpdate,
    required Function() onRevalidatePhone,
    required bool phoneFieldHasBeenValidated,
  }) {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, String>> filteredCountries = SignupConstants.countryCodes;

    showModalBottomSheet(
      context: context,
      backgroundColor: SignupConstants.bgDark2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
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
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SignupConstants.bgDark2,
                        border: Border(
                          bottom: BorderSide(
                            color: SignupConstants.borderColor.withOpacity(0.3),
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
                          // Search field
                          TextField(
                            controller: searchController,
                            style: const TextStyle(color: SignupConstants.textLight, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Rechercher un pays...',
                              hintStyle: const TextStyle(color: SignupConstants.textGrey, fontSize: 13),
                              prefixIcon: const Icon(Icons.search, color: SignupConstants.primaryGold),
                              filled: true,
                              fillColor: SignupConstants.bgDark1,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: SignupConstants.borderColor, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: SignupConstants.borderColor, width: 1),
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
                                  filteredCountries = SignupConstants.countryCodes;
                                } else {
                                  filteredCountries = SignupConstants.countryCodes
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
                    // Countries list
                    Expanded(
                      child: filteredCountries.isEmpty
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
                              itemCount: filteredCountries.length,
                              itemBuilder: (context, index) {
                                final country = filteredCountries[index];
                                final isSelected = selectedCountryCode == country['code'];

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    final countryCode = country['code']!;
                                    final countryName = country['name']!;
                                    final countryFlag = country['flag']!;
                                    
                                    onCountrySelected(countryCode, countryName, countryFlag);
                                    
                                    // Update phone number with new country code
                                    if (phoneController.text.isNotEmpty) {
                                      final digitsOnly = phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
                                      final updatedPhone = PhoneFormatter.formatPhoneNumber(
                                        countryCode,
                                        digitsOnly,
                                      );
                                      onPhoneNumberUpdate(updatedPhone);
                                    }
                                    
                                    // Re-validate phone field when country code changes
                                    if (phoneController.text.isNotEmpty) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        onRevalidatePhone();
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
                                          ? SignupConstants.primaryGold.withOpacity(0.15)
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
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      country['name']!,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: isSelected
                                                            ? SignupConstants.primaryGold
                                                            : SignupConstants.textLight,
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
                                                            ? SignupConstants.primaryGold.withOpacity(0.7)
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
          },
        );
      },
    );
  }
}

