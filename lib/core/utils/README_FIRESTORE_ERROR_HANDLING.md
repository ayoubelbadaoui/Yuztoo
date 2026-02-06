# Firestore Error Handling

This directory contains utilities for handling Firestore errors globally across the application.

## Files

### `firestore_error_mapper.dart`
Maps Firestore error codes to French error messages for UI display.

**Usage:**
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:your_app/core/utils/firestore_error_mapper.dart';

try {
  // Firestore operation
} on FirebaseException catch (e) {
  final frenchMessage = FirestoreErrorMapper.getFrenchMessage(e);
  // Display message to user
}
```

### `firestore_error_handler.dart`
Global error handler for Firestore operations with UI integration.

**Usage:**

1. **Simple error handling with UI display:**
```dart
import 'package:your_app/core/utils/firestore_error_handler.dart';

try {
  // Firestore operation
} catch (e) {
  FirestoreErrorHandler.handleError(context, e);
}
```

2. **Silent error handling (no UI):**
```dart
final errorMessage = FirestoreErrorHandler.handleErrorSilently(exception);
```

3. **Wrapped operation with automatic error handling:**
```dart
final result = await FirestoreErrorHandler.executeWithErrorHandling(
  context: context,
  operation: () async {
    // Your Firestore operation
    return await firestore.collection('users').doc('123').get();
  },
  defaultValue: null,
);
```

## Error Codes Mapped

All Firestore error codes are mapped to French messages:
- `aborted` - Operation cancelled (concurrency issue)
- `already-exists` - Document already exists
- `cancelled` - Operation cancelled by user or system
- `data-loss` - Data loss or corruption detected
- `deadline-exceeded` - Timeout, check connection
- `failed-precondition` - Missing index or invalid state
- `internal` - Internal Firebase server error
- `invalid-argument` - Invalid argument provided
- `not-found` - Document or collection not found
- `out-of-range` - Operation exceeded valid range
- `permission-denied` - Insufficient permissions
- `resource-exhausted` - Quota exceeded
- `unauthenticated` - User not authenticated
- `unavailable` - Service temporarily unavailable
- `unimplemented` - Operation not supported
- `unknown` - Unknown error occurred

## Integration with Snackbar

The `snackbar.dart` utility includes a helper function for Firestore errors:

```dart
import 'package:your_app/core/shared/widgets/snackbar.dart';

try {
  // Firestore operation
} catch (e) {
  showFirestoreErrorSnackbar(context, e);
}
```

## Best Practices

1. Always catch `FirebaseException` specifically when handling Firestore errors
2. Use the mapper to get French messages for user-facing errors
3. Log errors with context for debugging
4. Show user-friendly messages in the UI, not technical error details

