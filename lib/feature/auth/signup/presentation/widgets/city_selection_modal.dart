import 'package:flutter/material.dart';
import '../constants/signup_constants.dart';

class CitySelectionModal {
  static void show(
    BuildContext context, {
    required List<String> cities,
    required String? selectedCity,
    required Function(String) onCitySelected,
    required Function() onValidateCity,
  }) {
    final TextEditingController searchController = TextEditingController();
    List<String> filteredCities = cities;

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
                            'Sélectionnez votre ville',
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
                              hintText: 'Rechercher une ville...',
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
                                  filteredCities = cities;
                                } else {
                                  filteredCities = cities
                                      .where((city) => city
                                          .toLowerCase()
                                          .contains(value.toLowerCase()))
                                      .toList();
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    // Cities list
                    Expanded(
                      child: filteredCities.isEmpty
                          ? const Center(
                              child: Text(
                                'Aucune ville trouvée',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: SignupConstants.textGrey,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: filteredCities.length,
                              itemBuilder: (context, index) {
                                final city = filteredCities[index];
                                final isSelected = selectedCity == city;

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    // Update city first, then validate after state updates
                                    onCitySelected(city);
                                    // Validate after state has been updated
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      onValidateCity();
                                    });
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
                                        Text(
                                          city,
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

