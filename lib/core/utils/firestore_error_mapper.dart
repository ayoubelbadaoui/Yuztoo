import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps Firestore error codes to French error messages for UI display
class FirestoreErrorMapper {
  /// Map of Firestore error codes to French error messages
  static const Map<String, String> firestoreErrorMap = {
    'aborted': 'L\'opération a été annulée (souvent un problème de concurrence).',
    'already-exists': 'Le document que vous tentez de créer existe déjà.',
    'cancelled': 'L\'opération a été annulée par l\'utilisateur ou le système.',
    'data-loss': 'Pertes de données irrécupérables ou corruption détectée.',
    'deadline-exceeded': 'Le délai d\'attente est dépassé, vérifiez votre connexion.',
    'failed-precondition': 'Requête rejetée : un index manquant ou un état invalide.',
    'internal': 'Erreur interne au serveur Firebase.',
    'invalid-argument': 'Argument invalide fourni à la requête.',
    'not-found': 'Le document ou la collection demandé n\'existe pas.',
    'out-of-range': 'L\'opération a tenté de dépasser la plage valide.',
    'permission-denied': 'Droits insuffisants. Vérifiez vos règles de sécurité.',
    'resource-exhausted': 'Quota dépassé (lectures/écritures quotidiennes).',
    'unauthenticated': 'L\'utilisateur n\'est pas authentifié.',
    'unavailable': 'Service temporairement indisponible. Réessayez plus tard.',
    'unimplemented': 'L\'opération n\'est pas supportée ou activée.',
    'unknown': 'Une erreur inconnue est survenue.',
  };

  /// Get French error message from Firestore exception
  /// Returns the mapped message if available, otherwise a generic message
  static String getFrenchMessage(FirebaseException exception) {
    final errorCode = exception.code.toLowerCase();
    
    // Check if we have a mapped message for this error code
    if (firestoreErrorMap.containsKey(errorCode)) {
      return firestoreErrorMap[errorCode]!;
    }
    
    // Fallback: try to extract meaningful information from the error message
    final errorMessage = exception.message?.toLowerCase() ?? '';
    
    // Check for common patterns in error messages
    if (errorMessage.contains('permission') || errorMessage.contains('denied')) {
      return firestoreErrorMap['permission-denied']!;
    }
    if (errorMessage.contains('network') || errorMessage.contains('connection')) {
      return firestoreErrorMap['unavailable']!;
    }
    if (errorMessage.contains('timeout') || errorMessage.contains('deadline')) {
      return firestoreErrorMap['deadline-exceeded']!;
    }
    if (errorMessage.contains('not found') || errorMessage.contains('n\'existe pas')) {
      return firestoreErrorMap['not-found']!;
    }
    if (errorMessage.contains('already exists') || errorMessage.contains('existe déjà')) {
      return firestoreErrorMap['already-exists']!;
    }
    
    // Default fallback
    return firestoreErrorMap['unknown']!;
  }

  /// Get French error message from any exception that might be a Firestore error
  /// Returns null if the exception is not a FirebaseException
  static String? getFrenchMessageFromException(dynamic exception) {
    if (exception is FirebaseException) {
      return getFrenchMessage(exception);
    }
    return null;
  }

  /// Check if an exception is a Firestore error
  static bool isFirestoreError(dynamic exception) {
    return exception is FirebaseException;
  }
}

