import 'package:flutter/material.dart';
import '../constants/signup_constants.dart';
import '../utils/phone_formatter.dart';

part 'country_code_modal.part.dart';

class CountryCodeModal {
  static void show(
    BuildContext context, {
    required String selectedCountryCode,
    required Function(String countryCode, String countryName, String countryFlag)
        onCountrySelected,
    required TextEditingController phoneController,
    required Function(String) onPhoneNumberUpdate,
    required Function() onRevalidatePhone,
    required bool phoneFieldHasBeenValidated,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SignupConstants.bgDark2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return _CountryCodePickerSheet(
          selectedCountryCode: selectedCountryCode,
          onCountrySelected: onCountrySelected,
          phoneController: phoneController,
          onPhoneNumberUpdate: onPhoneNumberUpdate,
          onRevalidatePhone: onRevalidatePhone,
        );
      },
    );
  }
}
