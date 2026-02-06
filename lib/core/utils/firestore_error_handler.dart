import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/widgets/snackbar.dart';
import 'firestore_error_mapper.dart';

/// Global error handler for Firestore operations
/// Provides utilities to handle and display Firestore errors in the UI
class FirestoreErrorHandler {
  /// Handle a Firestore exception and show error message in UI
  /// Returns the French error message that was displayed
  static String? handleError(
    BuildContext context,
    dynamic exception, {
    String? customMessage,
    bool showInUI = true,
  }) {
    if (exception is! FirebaseException) {
      // Not a Firestore error, return null
      return null;
    }

    final frenchMessage = customMessage ?? FirestoreErrorMapper.getFrenchMessage(exception);

    if (showInUI && context.mounted) {
      showErrorSnackbar(context, frenchMessage);
    }

    return frenchMessage;
  }

  /// Handle a Firestore exception silently (without showing UI)
  /// Returns the French error message
  static String? handleErrorSilently(dynamic exception) {
    if (exception is! FirebaseException) {
      return null;
    }
    return FirestoreErrorMapper.getFrenchMessage(exception);
  }

  /// Wrap a Firestore operation with error handling
  /// If an error occurs, it will be automatically displayed in the UI
  static Future<T?> executeWithErrorHandling<T>({
    required BuildContext context,
    required Future<T> Function() operation,
    String? customErrorMessage,
    T? defaultValue,
  }) async {
    try {
      return await operation();
    } on FirebaseException catch (e) {
      handleError(
        context,
        e,
        customMessage: customErrorMessage,
      );
      return defaultValue;
    } catch (e) {
      // Not a Firestore error, rethrow or handle differently
      if (defaultValue != null) {
        return defaultValue;
      }
      rethrow;
    }
  }

  /// Get error message from exception without showing UI
  /// Useful for logging or custom error handling
  static String? getErrorMessage(dynamic exception) {
    return FirestoreErrorMapper.getFrenchMessageFromException(exception);
  }
}

