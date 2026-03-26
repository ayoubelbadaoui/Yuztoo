import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/merchant.dart';
import '../domain/merchant_failure.dart';
import '../domain/repositories/merchant_repository.dart';
import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/infrastructure/logger_service.dart';
import 'dto/merchant_dto.dart';

/// Firebase Firestore implementation of MerchantRepository.
class FirestoreMerchantRepository implements MerchantRepository {
  FirestoreMerchantRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<Result<bool>> merchantExists(String ownerUid) async {
    if (ownerUid.isEmpty) {
      return const Right<MerchantFailure, bool>(false);
    }

    try {
      final querySnapshot = await _firestore
          .collection('merchants')
          .where('owner_uid', isEqualTo: ownerUid)
          .limit(1)
          .get();

      final exists = querySnapshot.docs.isNotEmpty;
      LoggerService.logInfo(
        'Merchant existence check',
        context: {'ownerUid': ownerUid, 'exists': exists},
      );
      return Right<MerchantFailure, bool>(exists);
    } catch (e, st) {
      LoggerService.logError(
        'Error checking merchant existence',
        error: e,
        stackTrace: st,
        context: {'ownerUid': ownerUid},
      );
      return Left<MerchantFailure, bool>(
        MerchantNetworkFailure(
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Merchant>> createMerchantAndLinkUser({
    required Merchant merchant,
    required String userId,
  }) async {
    // Validate merchant data
    if (!merchant.isValid()) {
      return const Left<MerchantFailure, Merchant>(
        MerchantUnexpectedFailure(
          message: 'Unable to create merchant / Impossible de créer le profil commerçant',
        ),
      );
    }

    // MVP: Use userId as merchantId (one merchant per user)
    // This ensures merchantId == user.uid for MVP
    final merchantId = merchant.id.isEmpty
        ? userId  // Use userId as merchantId (MVP requirement)
        : merchant.id;

    try {
      // Create batch write for atomic operation
      final batch = _firestore.batch();

      // Create merchant document
      final merchantRef = _firestore.collection('merchants').doc(merchantId);
      final merchantDto = MerchantDto.fromDomain(
        merchant.copyWith(id: merchantId),
      );
      batch.set(merchantRef, merchantDto.toFirestore(), SetOptions(merge: false));

      // Update user document with merchant_id, mark onboarding as complete, and set merchant role
      final userRef = _firestore.collection('users').doc(userId);
      batch.set(userRef, {
        'merchant_id': merchantId,
        'onboarding.merchant': true, // Use dot notation for nested field
        'roles.merchant': true, // Ensure merchant role is set
        'roles.client': false, // Unset client role
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Commit batch write atomically
      await batch.commit();

      // Fetch the created merchant to return with server timestamps
      final createdDoc = await merchantRef.get();
      if (!createdDoc.exists) {
        LoggerService.logError(
          'Merchant document not found after creation',
          context: {'merchantId': merchantId, 'userId': userId},
        );
        return const Left<MerchantFailure, Merchant>(
          UnableToCreateMerchantFailure(
            message: 'Unable to create merchant / Impossible de créer le profil commerçant',
          ),
        );
      }

      final createdMerchant = MerchantDto.fromFirestore(createdDoc).toDomain();
      LoggerService.logInfo(
        'Merchant created and linked to user successfully',
        context: {
          'merchantId': merchantId,
          'userId': userId,
          'merchantName': merchant.name,
        },
      );

      return Right<MerchantFailure, Merchant>(createdMerchant);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase error creating merchant',
        error: e,
        stackTrace: st,
        context: {
          'merchantId': merchantId,
          'userId': userId,
          'code': e.code,
        },
      );

      // Check for specific Firebase errors
      if (e.code == 'permission-denied') {
        return const Left<MerchantFailure, Merchant>(
          UnableToCreateMerchantFailure(
            message:
                'Permission denied (Firestore rules) / Permission refusée (règles Firestore). Impossible de créer le profil commerçant.',
          ),
        );
      }

      return Left<MerchantFailure, Merchant>(
        MerchantNetworkFailure(
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error creating merchant',
        error: e,
        stackTrace: st,
        context: {
          'merchantId': merchantId,
          'userId': userId,
        },
      );
      return Left<MerchantFailure, Merchant>(
        MerchantUnexpectedFailure(
          message: 'Unable to create merchant / Impossible de créer le profil commerçant',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Merchant?>> getMerchantByOwnerUid(String ownerUid) async {
    if (ownerUid.isEmpty) {
      return const Right<MerchantFailure, Merchant?>(null);
    }

    try {
      // MVP: merchantId == ownerUid, so we can do a direct document read
      // This is more efficient than a query
      final doc = await _firestore.collection('merchants').doc(ownerUid).get();

      if (!doc.exists) {
        return const Right<MerchantFailure, Merchant?>(null);
      }

      final merchant = MerchantDto.fromFirestore(doc).toDomain();
      LoggerService.logInfo(
        'Merchant retrieved by owner UID (direct read)',
        context: {'ownerUid': ownerUid, 'merchantId': merchant.id},
      );
      return Right<MerchantFailure, Merchant?>(merchant);
    } catch (e, st) {
      LoggerService.logError(
        'Error getting merchant by owner UID',
        error: e,
        stackTrace: st,
        context: {'ownerUid': ownerUid},
      );
      return Left<MerchantFailure, Merchant?>(
        MerchantNetworkFailure(
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Merchant?>> getMerchantById(String merchantId) async {
    if (merchantId.isEmpty) {
      return const Right<MerchantFailure, Merchant?>(null);
    }
    try {
      final doc = await _firestore.collection('merchants').doc(merchantId).get();
      if (!doc.exists) {
        return const Right<MerchantFailure, Merchant?>(null);
      }
      final merchant = MerchantDto.fromFirestore(doc).toDomain();
      LoggerService.logInfo(
        'Merchant retrieved by ID',
        context: {'merchantId': merchantId},
      );
      return Right<MerchantFailure, Merchant?>(merchant);
    } catch (e, st) {
      LoggerService.logError(
        'Error getting merchant by ID',
        error: e,
        stackTrace: st,
        context: {'merchantId': merchantId},
      );
      return Left<MerchantFailure, Merchant?>(
        MerchantNetworkFailure(
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Unit>> linkExistingMerchantToUser({
    required String merchantId,
    required String userId,
  }) async {
    if (merchantId.isEmpty || userId.isEmpty) {
      return const Left<MerchantFailure, Unit>(
        MerchantUnexpectedFailure(
          message: 'Merchant ID and User ID are required',
        ),
      );
    }

    try {
      // Verify merchant exists
      final merchantDoc = await _firestore
          .collection('merchants')
          .doc(merchantId)
          .get();

      if (!merchantDoc.exists) {
        LoggerService.logError(
          'Merchant not found for linking',
          context: {'merchantId': merchantId, 'userId': userId},
        );
        return const Left<MerchantFailure, Unit>(
          MerchantUnexpectedFailure(
            message: 'Merchant not found / Le commerce n\'existe pas',
          ),
        );
      }

      // Verify merchant owner matches
      final merchantData = merchantDoc.data();
      final ownerUid = merchantData?['owner_uid'] as String?;
      if (ownerUid != userId) {
        LoggerService.logError(
          'Merchant owner mismatch',
          context: {
            'merchantId': merchantId,
            'userId': userId,
            'merchantOwnerUid': ownerUid,
          },
        );
        return const Left<MerchantFailure, Unit>(
          MerchantUnexpectedFailure(
            message: 'Merchant owner mismatch / Le propriétaire du commerce ne correspond pas',
          ),
        );
      }

      // Use batch write to ensure atomicity
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(userId);
      
      batch.update(userRef, {
        'merchant_id': merchantId,
        'onboarding.merchant': true,
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      LoggerService.logInfo(
        'Existing merchant linked to user successfully',
        context: {'merchantId': merchantId, 'userId': userId},
      );

      return const Right<MerchantFailure, Unit>(unit);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase error linking merchant to user',
        error: e,
        stackTrace: st,
        context: {'merchantId': merchantId, 'userId': userId, 'code': e.code},
      );

      if (e.code == 'permission-denied') {
        return const Left<MerchantFailure, Unit>(
          UnableToCreateMerchantFailure(
            message: 'Unable to link merchant / Impossible de lier le commerce',
          ),
        );
      }

      return Left<MerchantFailure, Unit>(
        MerchantNetworkFailure(
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error linking merchant to user',
        error: e,
        stackTrace: st,
        context: {'merchantId': merchantId, 'userId': userId},
      );
      return Left<MerchantFailure, Unit>(
        MerchantUnexpectedFailure(
          message: 'Unable to link merchant / Impossible de lier le commerce',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<Merchant>> updateMerchant({
    required String merchantId,
    String? displayName,
    String? description,
    List<String>? categories,
    String? logoUrl,
    String? phone,
    String? address,
    String? websiteUrl,
    String? bannerUrl,
    List<String>? newsImageUrls,
    String? status,
    Map<String, dynamic>? hours,
    bool? rappelsAutoClientValidation,
    bool? rappelsAutoPassageValidation,
  }) async {
    if (merchantId.isEmpty) {
      return const Left<MerchantFailure, Merchant>(
        MerchantUnexpectedFailure(
          message: 'Merchant ID is required',
        ),
      );
    }

    try {
      final merchantRef = _firestore.collection('merchants').doc(merchantId);
      
      // Build update map with only provided fields
      final updateData = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      if (displayName != null) {
        updateData['display_name'] = displayName;
      }
      if (description != null) {
        updateData['description'] = description;
      }
      if (categories != null) {
        updateData['categories'] = categories;
      }
      if (logoUrl != null) {
        updateData['logo_url'] = logoUrl;
      }
      if (phone != null) {
        updateData['phone'] = phone;
      }
      if (address != null) {
        updateData['address'] = address;
      }
      if (websiteUrl != null) {
        updateData['website_url'] = websiteUrl;
      }
      if (bannerUrl != null) {
        updateData['banner_url'] = bannerUrl;
      }
      if (newsImageUrls != null) {
        updateData['news_image_urls'] = newsImageUrls;
      }
      if (status != null) {
        updateData['status'] = status;
      }
      if (hours != null) {
        updateData['hours'] = hours;
      }
      if (rappelsAutoClientValidation != null) {
        updateData['rappels_auto_client_validation'] = rappelsAutoClientValidation;
      }
      if (rappelsAutoPassageValidation != null) {
        updateData['rappels_auto_passage_validation'] = rappelsAutoPassageValidation;
      }

      // Update merchant document
      await merchantRef.update(updateData);

      // Fetch updated merchant to return
      final updatedDoc = await merchantRef.get();
      if (!updatedDoc.exists) {
        LoggerService.logError(
          'Merchant document not found after update',
          context: {'merchantId': merchantId},
        );
        return const Left<MerchantFailure, Merchant>(
          MerchantUnexpectedFailure(
            message: 'Could not save storefront / Impossible d\'enregistrer la vitrine',
          ),
        );
      }

      final updatedMerchant = MerchantDto.fromFirestore(updatedDoc).toDomain();
      LoggerService.logInfo(
        'Merchant storefront updated successfully',
        context: {
          'merchantId': merchantId,
          'displayName': displayName,
          'hasLogoUrl': logoUrl != null,
        },
      );

      return Right<MerchantFailure, Merchant>(updatedMerchant);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase error updating merchant storefront',
        error: e,
        stackTrace: st,
        context: {
          'merchantId': merchantId,
          'code': e.code,
        },
      );

      if (e.code == 'permission-denied') {
        return const Left<MerchantFailure, Merchant>(
          MerchantUnexpectedFailure(
            message: 'Permission denied (Firestore rules) / Permission refusée (règles Firestore). Could not save storefront / Impossible d\'enregistrer la vitrine.',
          ),
        );
      }

      return Left<MerchantFailure, Merchant>(
        MerchantNetworkFailure(
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error updating merchant storefront',
        error: e,
        stackTrace: st,
        context: {'merchantId': merchantId},
      );
      return Left<MerchantFailure, Merchant>(
        MerchantUnexpectedFailure(
          message: 'Could not save storefront / Impossible d\'enregistrer la vitrine',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<List<Merchant>>> listMerchants({int limit = 20}) async {
    try {
      // List all merchants with a recent updated_at (no status filter) so Découvrir
      // shows newly created commerces (they were previously excluded when status was only 'inactive').
      final querySnapshot = await _firestore
          .collection('merchants')
          .orderBy('updated_at', descending: true)
          .limit(limit)
          .get();

      final merchants = querySnapshot.docs
          .map((doc) => MerchantDto.fromFirestore(doc).toDomain())
          .toList();

      LoggerService.logInfo(
        'List merchants for client home',
        context: {'count': merchants.length, 'limit': limit},
      );
      return Right<MerchantFailure, List<Merchant>>(merchants);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase error listing merchants',
        error: e,
        stackTrace: st,
        context: {'code': e.code},
      );
      if (e.code == 'permission-denied') {
        return const Left<MerchantFailure, List<Merchant>>(
          MerchantUnexpectedFailure(
            message: 'Permission denied reading merchants / Permission refusée.',
          ),
        );
      }
      return Left<MerchantFailure, List<Merchant>>(
        MerchantNetworkFailure(cause: e, stackTrace: st),
      );
    } catch (e, st) {
      LoggerService.logError(
        'Unexpected error listing merchants',
        error: e,
        stackTrace: st,
      );
      return Left<MerchantFailure, List<Merchant>>(
        MerchantUnexpectedFailure(
          message: 'Unable to load merchants / Impossible de charger les commerces',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  static const int _whereInLimit = 10;

  @override
  Future<Result<List<Merchant>>> getMerchantsByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return const Right<MerchantFailure, List<Merchant>>([]);
    }
    final distinctIds = ids.toSet().toList();
    try {
      final all = <Merchant>[];
      for (var i = 0; i < distinctIds.length; i += _whereInLimit) {
        final chunk = distinctIds.skip(i).take(_whereInLimit).toList();
        final snapshot = await _firestore
            .collection('merchants')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        final merchants = snapshot.docs
            .map((doc) => MerchantDto.fromFirestore(doc).toDomain())
            .toList();
        all.addAll(merchants);
      }
      // Preserve order of [ids] where possible
      final byId = {for (final m in all) m.id: m};
      final ordered = <Merchant>[];
      for (final id in ids) {
        final m = byId[id];
        if (m != null && !ordered.any((e) => e.id == m.id)) {
          ordered.add(m);
        }
      }
      for (final m in all) {
        if (!ordered.any((e) => e.id == m.id)) ordered.add(m);
      }
      LoggerService.logInfo(
        'getMerchantsByIds',
        context: {'requested': ids.length, 'found': ordered.length},
      );
      return Right<MerchantFailure, List<Merchant>>(ordered);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase error getMerchantsByIds',
        error: e,
        stackTrace: st,
        context: {'code': e.code},
      );
      if (e.code == 'permission-denied') {
        return const Right<MerchantFailure, List<Merchant>>([]);
      }
      return Left<MerchantFailure, List<Merchant>>(
        MerchantNetworkFailure(cause: e, stackTrace: st),
      );
    } catch (e, st) {
      LoggerService.logError('Error getMerchantsByIds', error: e, stackTrace: st);
      return Left<MerchantFailure, List<Merchant>>(
        MerchantUnexpectedFailure(
          message: 'Impossible de charger les commerces',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}

