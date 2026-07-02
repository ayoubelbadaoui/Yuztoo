import '../../../../../core/domain/core/value_object.dart';

/// Typed wrapper for a raw password string.
///
/// Intentionally a thin wrapper, not a policy enforcer:
/// - **Sign-up** policy (length, complexity) is enforced by
///   [SignupValidators] at the form layer, where the user can see and
///   correct violations.
/// - **Sign-in** must accept any pre-existing password — even one that
///   does not match the current policy — and let Firebase Auth respond
///   with the real verdict; gating client-side would lock legacy /
///   externally-provisioned accounts out under a misleading "Identifiants
///   incorrects" error.
///
/// The single check below (`!isEmpty`) prevents the trivial mistake of
/// constructing this with an empty string, which Firebase rejects anyway.
class Password extends ValueObject<String> {
  Password(super.input)
      : assert(isValid(input), 'Password must not be empty.');

  static bool isValid(String input) => input.isNotEmpty;
}
