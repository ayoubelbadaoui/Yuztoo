import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../types.dart';

/// Service for handling Firestore user document operations
class UserService {
  /// Get FirebaseFirestore instance - lazy loading to avoid errors if Firebase not initialized
  FirebaseFirestore get _firestore {
    if (!isFirebaseInitialized) {
      throw Exception('Firebase n\'est pas initialisé. Veuillez ajouter les fichiers de configuration Firebase.');
    }
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      throw Exception('Firebase n\'est pas initialisé. Veuillez ajouter les fichiers de configuration Firebase.');
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

  /// Create user document in Firestore at /users/{uid}
  /// 
  /// [uid] - User's unique identifier from Firebase Auth
  /// [email] - User's email address
  /// [phone] - User's phone number (formatted with country code)
  /// [roles] - Map of user roles: {"client": bool, "merchant": bool, "provider": bool}
  /// [city] - User's city (required, non-empty)
  /// 
  /// Returns void on success, throws Exception on error
  Future<void> createUserDocument({
    required String uid,
    required String email,
    required String phone,
    required Map<String, bool> roles,
    required String city,
  }) async {
    if (!isFirebaseInitialized) {
      throw Exception('Firebase n\'est pas initialisé. Veuillez ajouter les fichiers de configuration Firebase.');
    }

    if (city.isEmpty) {
      throw Exception('La ville est requise');
    }

    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'phone': phone,
        'roles': roles,
        'city': city,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: false));
    } catch (e) {
      throw Exception('Erreur lors de la création du profil utilisateur: ${e.toString()}');
    }
  }

  /// Get user role from Firestore
  /// 
  /// [uid] - User's unique identifier from Firebase Auth
  /// 
  /// Returns UserRole (client or merchant) based on roles map in Firestore
  /// Returns null if user document doesn't exist or roles are invalid
  Future<UserRole?> getUserRole(String uid) async {
    if (!isFirebaseInitialized) {
      return null;
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return null;
      }

      final data = doc.data();
      if (data == null) {
        return null;
      }

      final roles = data['roles'] as Map<String, dynamic>?;
      if (roles == null) {
        return null;
      }

      // Check if user is merchant
      if (roles['merchant'] == true) {
        return UserRole.merchant;
      }
      
      // Default to client
      return UserRole.client;
    } catch (e) {
      return null;
    }
  }
}

