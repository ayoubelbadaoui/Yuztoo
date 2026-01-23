import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Service for handling Firebase Authentication
class AuthService {
  /// Get FirebaseAuth instance - lazy loading to avoid errors if Firebase not initialized
  FirebaseAuth get _auth {
    if (!isFirebaseInitialized) {
      throw FirebaseAuthException(
        code: 'firebase-not-initialized',
        message: 'Firebase n\'est pas initialisé. Veuillez ajouter les fichiers de configuration Firebase.',
      );
    }
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'firebase-not-initialized',
        message: 'Firebase n\'est pas initialisé. Veuillez ajouter les fichiers de configuration Firebase.',
      );
    }
  }
  
  /// Check if Firebase is initialized
  bool get isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get current Firebase user
  User? get currentUser {
    try {
      if (!isFirebaseInitialized) return null;
      return _auth.currentUser;
    } catch (e) {
      return null;
    }
  }

  /// Get current user ID
  String? get currentUserId => currentUser?.uid;

  /// Get current user email
  String? get currentUserEmail => currentUser?.email;

  /// Create user with email and password
  /// 
  /// [email] - User's email address
  /// [password] - User's password (minimum 6 characters)
  /// 
  /// Returns [UserCredential] on success, throws [FirebaseAuthException] on error
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // Check if Firebase is initialized
    if (!isFirebaseInitialized) {
      throw FirebaseAuthException(
        code: 'firebase-not-initialized',
        message: 'Firebase n\'est pas initialisé. Veuillez ajouter les fichiers de configuration Firebase.',
      );
    }
    
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle "no firebase app" error specifically
      if (e.code == 'no-app' || e.message?.contains('No Firebase App') == true) {
        throw FirebaseAuthException(
          code: 'firebase-not-initialized',
          message: 'Firebase n\'est pas initialisé. Veuillez ajouter les fichiers de configuration Firebase.',
        );
      }
      rethrow;
    } catch (e) {
      // Check if it's a Firebase not initialized error
      if (e.toString().contains('No Firebase App') || 
          e.toString().contains('no firebase app')) {
        throw FirebaseAuthException(
          code: 'firebase-not-initialized',
          message: 'Firebase n\'est pas initialisé. Veuillez ajouter les fichiers de configuration Firebase.',
        );
      }
      // Re-throw as FirebaseAuthException for consistent error handling
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: e.toString(),
      );
    }
  }

  /// Send phone verification code and return verificationId
  Future<String> sendPhoneVerification(String phoneNumber) async {
    if (!isFirebaseInitialized) {
      throw FirebaseAuthException(
        code: 'firebase-not-initialized',
        message: 'Firebase n\'est pas initialisé. Veuillez ajouter les fichiers de configuration Firebase.',
      );
    }

    final completer = Completer<String>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        // Auto-verification completed on some devices
        if (!completer.isCompleted) {
          // We still return a fake verificationId since code is auto verified
          completer.complete('');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
    );

    return completer.future;
  }

  /// Link phone credential with SMS code
  Future<void> linkPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) async {
    if (!isFirebaseInitialized) {
      throw FirebaseAuthException(
        code: 'firebase-not-initialized',
        message: 'Firebase n\'est pas initialisé. Veuillez ajouter les fichiers de configuration Firebase.',
      );
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Aucun utilisateur connecté',
      );
    }

    await user.linkWithCredential(credential);
  }

  /// Get French error message from Firebase Auth error code
  /// 
  /// [errorCode] - Firebase Auth error code
  /// 
  /// Returns French error message or generic message if code not found
  static String getFrenchErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'Cette adresse email est déjà utilisée';
      case 'weak-password':
        return 'Le mot de passe est trop faible';
      case 'invalid-email':
        return 'Adresse email invalide';
      case 'operation-not-allowed':
        return 'Cette opération n\'est pas autorisée';
      case 'user-disabled':
        return 'Ce compte utilisateur a été désactivé';
      case 'user-not-found':
        return 'Aucun compte trouvé pour cette adresse email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'invalid-verification-code':
        return 'Code de vérification invalide';
      case 'invalid-verification-id':
        return 'ID de vérification invalide';
      case 'phone-number-already-exists':
        return 'Ce numéro de téléphone est déjà utilisé';
      case 'credential-already-in-use':
        return 'Ce numéro de téléphone est déjà utilisé';
      case 'provider-already-linked':
        return 'Ce numéro de téléphone est déjà associé à votre compte';
      case 'invalid-phone-number':
        return 'Numéro de téléphone invalide';
      case 'quota-exceeded':
        return 'Quota dépassé. Veuillez réessayer plus tard';
      case 'network-request-failed':
        return 'Erreur de connexion réseau';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard';
      case 'firebase-not-initialized':
      case 'no-app':
        return 'Firebase n\'est pas configuré. Veuillez contacter le support technique.';
      case 'unknown-error':
      default:
        return 'Une erreur s\'est produite. Veuillez réessayer';
    }
  }

  /// Handle Firebase Auth error and return French message
  /// 
  /// [exception] - FirebaseAuthException to handle
  /// 
  /// Returns French error message
  static String handleAuthError(FirebaseAuthException exception) {
    return getFrenchErrorMessage(exception.code);
  }
}

