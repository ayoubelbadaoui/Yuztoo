/// Thrown when self-service account deletion fails after user confirmation.
class DeleteAccountException implements Exception {
  DeleteAccountException(this.message);

  final String message;

  @override
  String toString() => message;
}
