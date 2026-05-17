part of 'firestore_merchant_repository.dart';

mixin _FirestoreMerchantRepositoryCore on _FirestoreMerchantRepositoryBase {
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

  Future<Result<Merchant>> createMerchantAndLinkUser({
    required Merchant merchant,
    required String userId,
  }) async {
    // MVP: Use userId as merchantId (one merchant per user)
    // This ensures merchantId == user.uid for MVP
    final merchantId = merchant.id.isEmpty
        ? userId  // Use userId as merchantId (MVP requirement)
        : merchant.id;

    try {
      // Recover ville d'inscription from /users if onboarding sent a placeholder.
      final userSnap =
          await _firestore.collection('users').doc(userId).get();
      final signupCity =
          (userSnap.data()?['city'] as String?)?.trim() ?? '';

      var merchantToCreate = merchant.copyWith(id: merchantId);
      final resolvedCity = resolveMerchantCityForCreation(
        incomingMerchantCity: merchantToCreate.city,
        signupCityFromUserDoc: signupCity,
      );
      final persistedCity =
          persistableMerchantCity(resolvedCity) ?? resolvedCity.trim();
      merchantToCreate = merchantToCreate.copyWith(city: persistedCity);

      if (!merchantToCreate.isValid()) {
        return const Left<MerchantFailure, Merchant>(
          MerchantUnexpectedFailure(
            message: 'Impossible de créer le profil commerçant',
          ),
        );
      }

      // Create batch write for atomic operation
      final batch = _firestore.batch();

      // Create merchant document
      final merchantRef = _firestore.collection('merchants').doc(merchantId);
      final merchantDto = MerchantDto.fromDomain(merchantToCreate);
      batch.set(merchantRef, merchantDto.toFirestore(), SetOptions(merge: false));

      // Update user document with merchant_id and merchant role flags.
      // Build the onboarding + roles maps by MERGING into the existing
      // doc state. Firestore's merge:true does not deep-merge nested
      // maps — writing `{'onboarding': {merchant: ...}}` would replace
      // the whole onboarding map (dropping `client`), and writing
      // `{'roles': {merchant: true, client: false, provider: true}}`
      // would force `client: false` even for dual-profile users who
      // already had it set to true. This was the dual-profile data-loss
      // bug behind the user report "closing the app completes onboarding
      // in both client and merchant" — once client onboarding was
      // dropped, the next routing pass either re-ran client onboarding
      // OR (when paired with the createUserDocument inactive-role
      // 'completed' bug) silently skipped it.
      final userRef = _firestore.collection('users').doc(userId);
      final existingOnboarding = Map<String, dynamic>.from(
        (userSnap.data()?['onboarding'] as Map<String, dynamic>?) ?? {},
      );
      existingOnboarding['merchant'] = 'completed';
      existingOnboarding.putIfAbsent('client', () => 'not_started');
      final existingRoles = Map<String, dynamic>.from(
        (userSnap.data()?['roles'] as Map<String, dynamic>?) ?? {},
      );
      // Only set keys that this operation owns. Preserve any pre-existing
      // client role — a merchant who already had a client carnet stays
      // a client too.
      existingRoles['merchant'] = true;
      existingRoles['provider'] = true;
      existingRoles.putIfAbsent('client', () => false);
      final userPayload = <String, dynamic>{
        'merchant_id': merchantId,
        'onboarding': existingOnboarding,
        'roles': existingRoles,
        'updated_at': FieldValue.serverTimestamp(),
      };
      // Keep owner user city + connected cities in sync (Découvrir / préférences).
      final trimmedCity = merchantToCreate.city.trim();
      if (trimmedCity.isNotEmpty && !CityInput.isPlaceholder(trimmedCity)) {
        userPayload['city'] = trimmedCity;
        userPayload['cities'] = mergedOwnerConnectedCities(
          existingUserData: userSnap.data(),
          persistedCity: trimmedCity,
        );
      }
      batch.set(userRef, userPayload, SetOptions(merge: true));

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
            message: 'Impossible de créer le profil commerçant',
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
                'Permission refusée (règles Firestore). Impossible de créer le profil commerçant.',
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
          message: 'Impossible de créer le profil commerçant',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

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
}
