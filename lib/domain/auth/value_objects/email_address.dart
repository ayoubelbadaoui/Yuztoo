import '../../core/value_object.dart';

/// Simple validated email value object.
class EmailAddress extends ValueObject<String> {
  EmailAddress(String input)
      : assert(isValid(input), 'EmailAddress must be a valid email'),
        super(input.trim());

  static bool isValid(String input) {
    final email = input.trim();
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(email);
  }
}
