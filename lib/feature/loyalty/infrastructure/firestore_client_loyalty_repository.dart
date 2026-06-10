import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/domain/core/either.dart';
import '../../../core/domain/core/failure.dart';
import '../../../core/domain/core/result.dart';
import '../../../core/infrastructure/logger_service.dart';
import '../../merchant/domain/entities/client_gratification_config.dart';
import '../../merchant/domain/entities/loyalty_program_config.dart';
import '../../merchant/infrastructure/loyalty_program_firestore_mapper.dart';
import '../domain/entities/client_merchant_loyalty_progress.dart';
import '../domain/entities/loyalty_pending_client_row.dart';
import '../domain/failures/passage_cooldown_failure.dart';
import '../domain/repositories/client_loyalty_repository.dart';

/// Firestore: `merchants/{merchantId}/loyalty_clients/{clientUid}`.
class FirestoreClientLoyaltyRepository implements ClientLoyaltyRepository {
  FirestoreClientLoyaltyRepository({
    required FirebaseFirestore firestore,
    Duration passageCooldown = Duration.zero,
  })  : _firestore = firestore,
        _passageCooldown = passageCooldown;

  final FirebaseFirestore _firestore;

  /// Minimum time between two passage writes for the same (client, merchant).
  /// Blocks accidental double-tap and the simplest fraud loop (rapid re-scan).
  ///
  /// The anchor `last_passage_at` is written with `FieldValue.serverTimestamp()`,
  /// so the stored value is authoritative server time. The comparison in this
  /// SDK uses the device clock for "now", which is fine as a UX guard but is
  /// NOT the security boundary — the authoritative enforcement is the
  /// matching rule in `firestore.rules`
  /// (`loyaltyClientPassageCooldownPasses`), which compares `request.time`
  /// (server) to `last_passage_at`. A tampered local clock is bypassed by
  /// the SDK guard but caught by the rule.
  final Duration _passageCooldown;

  /// Tolerance applied to the client-side cooldown comparison to absorb honest
  /// device clock skew (NTP drift, time-zone fiddling). Capped at 2 minutes
  /// because larger drift is uncommon on phones, but never more than a quarter
  /// of the cooldown itself — otherwise small cooldowns (e.g. unit-test
  /// overrides) would be fully absorbed by the tolerance and never fire.
  /// Larger drift than 2 min is caught by the server-side rule anyway.
  static const Duration _maxClockSkewTolerance = Duration(minutes: 2);

  Duration get _effectiveClockSkewTolerance {
    final quarterCooldown = _passageCooldown ~/ 4;
    return quarterCooldown < _maxClockSkewTolerance
        ? quarterCooldown
        : _maxClockSkewTolerance;
  }

  /// Sentinel error string used to bubble cooldown rejection out of the
  /// Firestore transaction without coupling the error mapping to the
  /// transaction body.
  static const String _passageCooldownSentinel = 'passage_cooldown_active';

  DocumentReference<Map<String, dynamic>> _docRef(
    String merchantId,
    String clientUid,
  ) =>
      _firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('loyalty_clients')
          .doc(clientUid);

  static ClientMerchantLoyaltyProgress _fromMap(Map<String, dynamic>? data) {
    if (data == null) return const ClientMerchantLoyaltyProgress.empty();
    final v = (data['validated_passages'] as num?)?.toInt() ?? 0;
    final c = (data['cumulative_spend_euros'] as num?)?.toDouble() ?? 0.0;
    // first_visit_at: first time we create the loyalty doc for this client at
    // this merchant. The "bon d'accueil" is shown on the loyalty card when
    // this flag is set; once the client claims it, welcome_bon_claimed_at is
    // written and the bon disappears from "Mes avantages".
    final hasFirstVisit =
        data.containsKey('first_visit_at') && data['first_visit_at'] != null;
    final welcomeBonClaimed = data.containsKey('welcome_bon_claimed_at') &&
        data['welcome_bon_claimed_at'] != null;
    final enrolled = LoyaltyProgramFirestoreMapper.fromFirestoreMap(
      data['enrolled_loyalty_program'],
    );
    final status = data['program_status'] as String?;
    return ClientMerchantLoyaltyProgress(
      validatedPassages: v,
      cumulativeSpendEuros: c,
      hasFirstVisit: hasFirstVisit,
      welcomeBonClaimed: welcomeBonClaimed,
      enrolledProgram: enrolled,
      programStatus: status,
    );
  }

  @override
  Stream<ClientMerchantLoyaltyProgress> watchProgress(
    String merchantId,
    String clientUid,
  ) {
    if (merchantId.isEmpty || clientUid.isEmpty) {
      return Stream<ClientMerchantLoyaltyProgress>.value(
        const ClientMerchantLoyaltyProgress.empty(),
      );
    }
    return _docRef(merchantId, clientUid).snapshots().map(
          (DocumentSnapshot<Map<String, dynamic>> s) =>
              _fromMap(s.data()),
        );
  }

  @override
  Future<ClientMerchantLoyaltyProgress> readProgress(
    String merchantId,
    String clientUid,
  ) async {
    if (merchantId.isEmpty || clientUid.isEmpty) {
      return const ClientMerchantLoyaltyProgress.empty();
    }
    final snap = await _docRef(merchantId, clientUid).get();
    return _fromMap(snap.data());
  }

  @override
  Future<Result<ClientMerchantLoyaltyProgress>> applyPassageDeltas({
    required String merchantId,
    required String clientUid,
    int validatedPassagesDelta = 0,
    double cumulativeSpendEurosDelta = 0,
    LoyaltyProgramConfig? enrollProgram,
    ActiveValidationCompletion? completeActiveValidation,
  }) async {
    if (merchantId.isEmpty || clientUid.isEmpty) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'Commerce ou utilisateur invalide'),
      );
    }
    if (validatedPassagesDelta == 0 && cumulativeSpendEurosDelta == 0) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'Aucune mise à jour de passage'),
      );
    }
    // Every counter increment is a new passage event now — the old
    // "resolving pending" exception is gone with the pending_passages field.
    // Cooldown applies to all increments when [_passageCooldown] is non-zero.
    // The synchronous validation flow (active_validations) is the canonical
    // place where merchants record passages; optional cooldown reduces double-tap.
    final bool isNewPassageEvent =
        validatedPassagesDelta > 0 || cumulativeSpendEurosDelta > 0;
    try {
      final progress = await _firestore.runTransaction(
        (Transaction tx) async {
          final ref = _docRef(merchantId, clientUid);

          // When the caller wants to also close an active_validation session
          // atomically, read that doc first and verify it's still
          // 'awaiting'. The merchant queue listener only pops the form for
          // 'awaiting' docs, so a second tap on the loyalty popup hits a
          // session in 'completed' state and is rejected here — that's the
          // double-validation guard.
          DocumentReference<Map<String, dynamic>>? sessionRef;
          if (completeActiveValidation != null) {
            sessionRef = _firestore
                .collection('merchants')
                .doc(merchantId)
                .collection('active_validations')
                .doc(clientUid);
            final sessionSnap = await tx.get(sessionRef);
            if (!sessionSnap.exists) {
              throw StateError('active_validation_missing');
            }
            final sessionStatus =
                sessionSnap.data()?['status'] as String?;
            if (sessionStatus != 'awaiting') {
              throw StateError('active_validation_not_awaiting');
            }
            final source = sessionSnap.data()?['source'] as String?;
            if (source == 'ble' &&
                sessionSnap.data()?['merchant_ble_connected_at'] == null) {
              throw StateError('ble_merchant_not_connected');
            }
          }

          final snap = await tx.get(ref);
          final isFirstVisit = !snap.exists;
          final cur = _fromMap(snap.data());

          // Cooldown: UX-level guard against accidental double-tap and the
          // most casual rapid re-scan abuse. Compares the device clock to a
          // server-written `last_passage_at`. A tampered clock would bypass
          // this — the authoritative enforcement is in firestore.rules,
          // which compares `request.time` (server) to `last_passage_at`.
          if (isNewPassageEvent) {
            final lastPassageAt = snap.data()?['last_passage_at'];
            if (lastPassageAt is Timestamp) {
              final since = DateTime.now()
                  .toUtc()
                  .difference(lastPassageAt.toDate().toUtc());
              // A negative `since` means the device clock is behind server
              // time — fall through to the rule check rather than blocking
              // (we cannot trust the local arithmetic in that case).
              if (!since.isNegative &&
                  since + _effectiveClockSkewTolerance < _passageCooldown) {
                throw StateError(_passageCooldownSentinel);
              }
            }
          }

          final next = ClientMerchantLoyaltyProgress(
            validatedPassages: cur.validatedPassages + validatedPassagesDelta,
            cumulativeSpendEuros:
                cur.cumulativeSpendEuros + cumulativeSpendEurosDelta,
            isFirstVisit: isFirstVisit,
          );
          if (next.validatedPassages < 0 ||
              next.cumulativeSpendEuros < 0) {
            throw StateError('invalid_loyalty_counters');
          }
          final write = <String, dynamic>{
            'validated_passages': next.validatedPassages,
            'cumulative_spend_euros': next.cumulativeSpendEuros,
            'updated_at': FieldValue.serverTimestamp(),
            if (isNewPassageEvent)
              'last_passage_at': FieldValue.serverTimestamp(),
            if (isFirstVisit) 'first_visit_at': FieldValue.serverTimestamp(),
            if (isFirstVisit && enrollProgram != null) ...<String, dynamic>{
              'enrolled_loyalty_program':
                  LoyaltyProgramFirestoreMapper.toFirestoreMap(enrollProgram),
              'enrolled_at': FieldValue.serverTimestamp(),
              'program_status': 'active',
            },
          };
          tx.set(ref, write, SetOptions(merge: true));

          // Atomic active_validation close. If we got this far the session
          // was 'awaiting' (checked above) and the loyalty_clients write is
          // staged. Mark the session 'completed' with the result deltas so
          // the client's listener can celebrate.
          if (completeActiveValidation != null && sessionRef != null) {
            final sessionWrite = <String, dynamic>{
              'status': 'completed',
              'completed_at': FieldValue.serverTimestamp(),
              'result_validated_delta':
                  completeActiveValidation.validatedDelta,
              'result_spend_delta': completeActiveValidation.spendDelta,
              if (completeActiveValidation.declaredSpendEuros != null)
                'declared_spend_euros':
                    completeActiveValidation.declaredSpendEuros,
            };
            tx.set(sessionRef, sessionWrite, SetOptions(merge: true));
          }
          return next;
        },
      );
      LoggerService.logInfo(
        'Loyalty passage applied',
        context: <String, Object?>{
          'merchantId': merchantId,
          'clientUid': clientUid,
          'validatedDelta': validatedPassagesDelta,
          'spendDelta': cumulativeSpendEurosDelta,
        },
      );
      // Increment the monthly validated-passages counter when needed.
      if (validatedPassagesDelta > 0) {
        await _incrementMonthlyValidatedPassages(merchantId);
      }
      return Right<AppFailure, ClientMerchantLoyaltyProgress>(progress);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase loyalty passage',
        error: e,
        stackTrace: st,
      );
      // The server-side cooldown rule rejects with permission-denied when
      // the merchant tries to bump `last_passage_at` < 1h after the
      // previous one. The SDK guard usually catches this earlier, but a
      // tampered local clock would bypass the SDK and surface here. Route
      // it to the same friendly message instead of the generic fallback.
      if (e.code == 'permission-denied' && isNewPassageEvent) {
        return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
          PassageCooldownFailure(),
        );
      }
      return Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(
          message: 'Impossible d’enregistrer le passage',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      if (e.toString().contains(_passageCooldownSentinel)) {
        // Surfaced as a typed failure so callers can switch on the type
        // (preferred) instead of substring-matching the message. The
        // canonical French copy lives in [PassageCooldownFailure] so
        // sheets, snackbars and analytics share the same wording.
        return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
          PassageCooldownFailure(),
        );
      }
      if (e.toString().contains('active_validation_missing')) {
        return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
          UnexpectedFailure(
            message: 'La demande de passage est introuvable.',
          ),
        );
      }
      if (e.toString().contains('active_validation_not_awaiting')) {
        return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
          UnexpectedFailure(
            message: 'Cette demande a déjà été traitée.',
          ),
        );
      }
      if (e.toString().contains('ble_merchant_not_connected')) {
        return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
          UnexpectedFailure(
            message:
                'Confirmez la connexion BLE du client avant de valider le passage.',
          ),
        );
      }
      if (e.toString().contains('invalid_loyalty_counters')) {
        return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
          UnexpectedFailure(message: 'Données fidélité invalides'),
        );
      }
      LoggerService.logError('Loyalty passage', error: e, stackTrace: st);
      return Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(
          message: 'Erreur lors de l’enregistrement',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Stream<List<LoyaltyPendingClientRow>> watchClientsWithRewardAvailable({
    required String merchantId,
    required int visitsRequired,
    required double spendRequiredEuros,
    required bool iSpendBased,
  }) {
    if (merchantId.isEmpty) {
      return Stream<List<LoyaltyPendingClientRow>>.value(
        <LoyaltyPendingClientRow>[],
      );
    }
    return _firestore
        .collection('merchants')
        .doc(merchantId)
        .collection('loyalty_clients')
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                LoyaltyPendingClientRow(
              clientUid: d.id,
              progress: _fromMap(d.data()),
            ),
          )
          .where((row) {
        if (iSpendBased) {
          return row.progress.cumulativeSpendEuros >= spendRequiredEuros;
        }
        return row.progress.validatedPassages >= visitsRequired;
      }).toList();
    });
  }

  @override
  Future<Result<ClientMerchantLoyaltyProgress>> redeemReward({
    required String merchantId,
    required String clientUid,
    required int visitsRequired,
    required double spendRequiredEuros,
    required bool isSpendBased,
  }) async {
    if (merchantId.isEmpty || clientUid.isEmpty) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'Commerce ou client invalide'),
      );
    }
    try {
      final progress = await _firestore.runTransaction(
        (Transaction tx) async {
          final ref = _docRef(merchantId, clientUid);
          final snap = await tx.get(ref);
          final cur = _fromMap(snap.data());

          // Verify the reward is actually available before deducting.
          final rewardAvailable = isSpendBased
              ? cur.cumulativeSpendEuros >= spendRequiredEuros
              : cur.validatedPassages >= visitsRequired;
          if (!rewardAvailable) {
            throw StateError('reward_not_available');
          }

          // Deduct one reward cycle. Keep any overflow passages for the next cycle.
          final nextValidated = isSpendBased
              ? cur.validatedPassages
              : (cur.validatedPassages - visitsRequired).clamp(0, 9999);
          final nextSpend = isSpendBased
              ? (cur.cumulativeSpendEuros - spendRequiredEuros)
                  .clamp(0.0, 1e9)
              : cur.cumulativeSpendEuros;

          final next = ClientMerchantLoyaltyProgress(
            validatedPassages: nextValidated,
            cumulativeSpendEuros: nextSpend,
          );

          tx.set(
            ref,
            <String, dynamic>{
              'validated_passages': next.validatedPassages,
              'cumulative_spend_euros': next.cumulativeSpendEuros,
              'updated_at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
          return next;
        },
      );
      LoggerService.logInfo(
        'Loyalty reward redeemed',
        context: <String, Object?>{
          'merchantId': merchantId,
          'clientUid': clientUid,
        },
      );
      return Right<AppFailure, ClientMerchantLoyaltyProgress>(progress);
    } on FirebaseException catch (e, st) {
      LoggerService.logError('Reward redemption Firebase', error: e, stackTrace: st);
      return Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(
          message: 'Impossible de valider la récompense',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      if (e.toString().contains('reward_not_available')) {
        return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
          UnexpectedFailure(
            message: 'La récompense n\'est pas encore disponible pour ce client',
          ),
        );
      }
      LoggerService.logError('Reward redemption', error: e, stackTrace: st);
      return Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(
          message: 'Erreur lors de la validation de la récompense',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Result<ClientMerchantLoyaltyProgress>> claimWelcomeBon({
    required String merchantId,
    required String clientUid,
  }) async {
    if (merchantId.isEmpty || clientUid.isEmpty) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'Commerce ou utilisateur invalide'),
      );
    }
    try {
      final progress = await _firestore.runTransaction(
        (Transaction tx) async {
          final ref = _docRef(merchantId, clientUid);
          final snap = await tx.get(ref);
          if (!snap.exists) {
            // No loyalty doc yet → no welcome bon to claim. The UI must not
            // surface the bon in this state, but guard anyway in case a stale
            // optimistic UI fires the use case.
            throw StateError('welcome_bon_unavailable');
          }
          final data = snap.data() ?? <String, dynamic>{};
          final hasFirstVisit = data['first_visit_at'] != null;
          if (!hasFirstVisit) {
            throw StateError('welcome_bon_unavailable');
          }
          // Idempotency: if already claimed, return the current progress
          // unchanged. Two rapid taps on "Utiliser" must NOT race-claim or
          // throw — the user just sees a successful confirmation.
          if (data['welcome_bon_claimed_at'] != null) {
            return _fromMap(data);
          }
          tx.set(
            ref,
            <String, dynamic>{
              'welcome_bon_claimed_at': FieldValue.serverTimestamp(),
              'updated_at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
          return _fromMap(<String, dynamic>{
            ...data,
            'welcome_bon_claimed_at': Timestamp.now(),
          });
        },
      );
      LoggerService.logInfo(
        'Welcome bon claimed',
        context: <String, Object?>{
          'merchantId': merchantId,
          'clientUid': clientUid,
        },
      );
      return Right<AppFailure, ClientMerchantLoyaltyProgress>(progress);
    } on FirebaseException catch (e, st) {
      LoggerService.logError('Welcome bon Firebase', error: e, stackTrace: st);
      return Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(
          message: 'Impossible de valider votre bon de bienvenue',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      if (e.toString().contains('welcome_bon_unavailable')) {
        return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
          UnexpectedFailure(
            message:
                'Aucun bon de bienvenue disponible. Effectuez un premier passage pour le débloquer.',
          ),
        );
      }
      LoggerService.logError('Welcome bon claim', error: e, stackTrace: st);
      return Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(
          message: 'Erreur lors de la validation du bon',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<Map<String, String>> getClientSegments(String merchantId) async {
    if (merchantId.isEmpty) return {};
    try {
      var gratification = ClientGratificationConfig.defaults;
      try {
        final merchantSnap =
            await _firestore.collection('merchants').doc(merchantId).get();
        final raw = merchantSnap.data()?['gratification_config'];
        if (raw is Map) {
          gratification = ClientGratificationConfig.fromMap(
            Map<String, dynamic>.from(raw),
          );
        }
      } catch (e) {
        LoggerService.logError(
          'getClientSegments: gratification_config',
          error: e,
        );
      }

      final loyaltySnap = await _firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('loyalty_clients')
          .get();

      final result = <String, String>{};
      final now = DateTime.now();
      for (final doc in loyaltySnap.docs) {
        final data = doc.data();
        final validated = (data['validated_passages'] as num?)?.toInt() ?? 0;
        // Prefer `last_passage_at` (the cooldown anchor) — it is written
        // ONLY on a true passage event. `updated_at` was the previous
        // anchor but it also moves on merchant-side CRM edits (notes,
        // manual segment), which made `daysSinceLastVisit` artificially
        // small and silently kept clients out of the `inactif` segment.
        // Fall back to `updated_at` for legacy docs that pre-date the
        // cooldown deployment and so never wrote `last_passage_at`.
        DateTime? lastVisit;
        final lastPassageAt = data['last_passage_at'];
        if (lastPassageAt is Timestamp) {
          lastVisit = lastPassageAt.toDate();
        } else {
          final updatedAt = data['updated_at'];
          if (updatedAt is Timestamp) lastVisit = updatedAt.toDate();
        }
        final daysSince = lastVisit != null
            ? now.difference(lastVisit).inDays
            : 999;
        result[doc.id] = gratification.segmentKeyFor(
          validatedPassages: validated,
          daysSinceLastVisit: daysSince,
        );
      }

      // Merchant manual labels (VIP, etc.) live on merchants/{id}/clients/{uid}
      // and must override auto segments for notification / promo ciblage.
      try {
        final overridesSnap = await _firestore
            .collection('merchants')
            .doc(merchantId)
            .collection('clients')
            .get();
        for (final doc in overridesSnap.docs) {
          final manual = (doc.data()['manual_segment'] as String?)?.trim();
          if (manual != null && manual.isNotEmpty) {
            result[doc.id] = manual;
          }
        }
      } catch (e) {
        LoggerService.logError(
          'getClientSegments: fetch manual_segment overrides',
          error: e,
        );
      }

      return result;
    } catch (_) {
      return {};
    }
  }

  /// Best-effort: increments `rappels_monthly_validated_passages` on the
  /// merchant doc, resetting the counter when the calendar month changes.
  Future<void> _incrementMonthlyValidatedPassages(String merchantId) async {
    final now = DateTime.now();
    final currentYm =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final merchantRef =
        _firestore.collection('merchants').doc(merchantId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(merchantRef);
      final storedYm =
          snap.data()?['rappels_monthly_validated_ym'] as String?;
      final newCount =
          storedYm == currentYm ? FieldValue.increment(1) : 1;
      tx.set(
        merchantRef,
        {
          'rappels_monthly_validated_passages': newCount,
          'rappels_monthly_validated_ym': currentYm,
        },
        SetOptions(merge: true),
      );
    }).catchError((Object e) {
      LoggerService.logError(
        'incrementMonthlyValidatedPassages',
        error: e,
      );
    });
  }
}
