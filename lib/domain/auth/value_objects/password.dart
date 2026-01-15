import '../../core/value_object.dart';

/// Password value object with basic policy enforcement.
class Password extends ValueObject<String> {
  Password(super.input)
      : assert(isValid(input), 'Password must be at least 8 characters.');

  static bool isValid(String input) => input.trim().length >= 8;
}
