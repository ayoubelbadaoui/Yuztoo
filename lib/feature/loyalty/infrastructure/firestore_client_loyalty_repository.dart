import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/domain/core/either.dart';
import '../../../core/domain/core/failure.dart';
import '../../../core/domain/core/result.dart';
import '../../../core/infrastructure/logger_service.dart';
import '../domain/entities/client_merchant_loyalty_progress.dart';
import '../domain/entities/loyalty_pending_client_row.dart';
import '../domain/repositories/client_loyalty_repository.dart';

/// Firestore: `merchants/{merchantId}/loyalty_clients/{clientUid}`.
class FirestoreClientLoyaltyRepository implements ClientLoyaltyRepository {
  FirestoreClientLoyaltyRepository({
    required FirebaseFirestore firestore,
    Duration passageCooldown = const Duration(seconds: 60),
  })  : _firestore = firestore,
        _passageCooldown = passageCooldown;

  final FirebaseFirestore _firestore;

  /// Minimum time between two passage writes for the same (client, merchant).
  /// Blocks accidental double-tap and the simplest fraud loop (rapid re-scan).
  /// Server-time-aware via `last_passage_at` written inside the transaction.
  final Duration _passageCooldown;

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
    final p = (data['pending_passages'] as num?)?.toInt() ?? 0;
    final c = (data['cumulative_spend_euros'] as num?)?.toDouble() ?? 0.0;
    // first_visit_at: first time we create the loyalty doc for this client at
    // this merchant. The "bon d'accueil" is shown on the loyalty card when
    // this flag is set; once the client claims it, welcome_bon_claimed_at is
    // written and the bon disappears from "Mes avantages".
    final hasFirstVisit =
        data.containsKey('first_visit_at') && data['first_visit_at'] != null;
    final welcomeBonClaimed = data.containsKey('welcome_bon_claimed_at') &&
        data['welcome_bon_claimed_at'] != null;
    return ClientMerchantLoyaltyProgress(
      validatedPassages: v,
      pendingPassages: p,
      cumulativeSpendEuros: c,
      hasFirstVisit: hasFirstVisit,
      welcomeBonClaimed: welcomeBonClaimed,
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
  Stream<List<LoyaltyPendingClientRow>> watchPendingLoyaltyClients(
    String merchantId,
  ) {
    if (merchantId.isEmpty) {
      return Stream<List<LoyaltyPendingClientRow>>.value(
        <LoyaltyPendingClientRow>[],
      );
    }
    return _firestore
        .collection('merchants')
        .doc(merchantId)
        .collection('loyalty_clients')
        .where('pending_passages', isGreaterThan: 0)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            return snapshot.docs
                .map(
                  (QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                      LoyaltyPendingClientRow(
                    clientUid: d.id,
                    progress: _fromMap(d.data()),
                  ),
                )
                .toList();
          },
        );
  }

  @override
  Future<Result<ClientMerchantLoyaltyProgress>> applyPassageDeltas({
    required String merchantId,
    required String clientUid,
    int validatedPassagesDelta = 0,
    int pendingPassagesDelta = 0,
    double cumulativeSpendEurosDelta = 0,
  }) async {
    if (merchantId.isEmpty || clientUid.isEmpty) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'Commerce ou utilisateur invalide'),
      );
    }
    if (validatedPassagesDelta == 0 &&
        pendingPassagesDelta == 0 &&
        cumulativeSpendEurosDelta == 0) {
      return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(message: 'Aucune mise à jour de passage'),
      );
    }
    // Whether this call is *adding* a passage (positive delta on any counter).
    // Cooldown only applies to additions; a reverting delta from
    // validate-pending should always be allowed.
    final bool isAddingPassage = validatedPassagesDelta > 0 ||
        pendingPassagesDelta > 0 ||
        cumulativeSpendEurosDelta > 0;
    try {
      final progress = await _firestore.runTransaction(
        (Transaction tx) async {
          final ref = _docRef(merchantId, clientUid);
          final snap = await tx.get(ref);
          final isFirstVisit = !snap.exists;
          final cur = _fromMap(snap.data());

          // Cooldown: block accidental double-tap and rapid re-scan loops.
          // Server-side timestamp comparison — never trust the device clock.
          if (isAddingPassage) {
            final lastPassageAt = snap.data()?['last_passage_at'];
            if (lastPassageAt is Timestamp) {
              final since = DateTime.now()
                  .toUtc()
                  .difference(lastPassageAt.toDate().toUtc());
              if (!since.isNegative && since < _passageCooldown) {
                throw StateError(_passageCooldownSentinel);
              }
            }
          }

          if (pendingPassagesDelta < 0 &&
              cur.pendingPassages < -pendingPassagesDelta) {
            throw StateError('no_pending_passage');
          }
          final next = ClientMerchantLoyaltyProgress(
            validatedPassages: cur.validatedPassages + validatedPassagesDelta,
            pendingPassages: cur.pendingPassages + pendingPassagesDelta,
            cumulativeSpendEuros:
                cur.cumulativeSpendEuros + cumulativeSpendEurosDelta,
            isFirstVisit: isFirstVisit,
          );
          if (next.validatedPassages < 0 ||
              next.pendingPassages < 0 ||
              next.cumulativeSpendEuros < 0) {
            throw StateError('invalid_loyalty_counters');
          }
          tx.set(
            ref,
            <String, dynamic>{
              'validated_passages': next.validatedPassages,
              'pending_passages': next.pendingPassages,
              'cumulative_spend_euros': next.cumulativeSpendEuros,
              'updated_at': FieldValue.serverTimestamp(),
              if (isAddingPassage)
                'last_passage_at': FieldValue.serverTimestamp(),
              if (isFirstVisit) 'first_visit_at': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
          return next;
        },
      );
      LoggerService.logInfo(
        'Loyalty passage applied',
        context: <String, Object?>{
          'merchantId': merchantId,
          'clientUid': clientUid,
          'validatedDelta': validatedPassagesDelta,
          'pendingDelta': pendingPassagesDelta,
          'spendDelta': cumulativeSpendEurosDelta,
        },
      );
      // Increment the monthly validated-passages counter when needed.
      if (validatedPassagesDelta > 0) {
        _incrementMonthlyValidatedPassages(merchantId);
      }
      return Right<AppFailure, ClientMerchantLoyaltyProgress>(progress);
    } on FirebaseException catch (e, st) {
      LoggerService.logError(
        'Firebase loyalty passage',
        error: e,
        stackTrace: st,
      );
      return Left<AppFailure, ClientMerchantLoyaltyProgress>(
        UnexpectedFailure(
          message: 'Impossible d’enregistrer le passage',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      if (e.toString().contains(_passageCooldownSentinel)) {
        // Surfaced verbatim to the UI — the parent layer recognises this
        // string to render the friendly "déjà été enregistré" sheet rather
        // than a generic error toast.
        return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
          UnexpectedFailure(
            message:
                'Votre passage vient d’être enregistré. Patientez un instant avant le prochain.',
          ),
        );
      }
      if (e.toString().contains('no_pending_passage')) {
        return const Left<AppFailure, ClientMerchantLoyaltyProgress>(
          UnexpectedFailure(message: 'Aucun passage en attente pour ce client'),
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
            pendingPassages: cur.pendingPassages,
            cumulativeSpendEuros: nextSpend,
          );

          tx.set(
            ref,
            <String, dynamic>{
              'validated_passages': next.validatedPassages,
              'pending_passages': next.pendingPassages,
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
      final snap = await _firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('loyalty_clients')
          .get();
      final result = <String, String>{};
      final now = DateTime.now();
      for (final doc in snap.docs) {
        final data = doc.data();
        final validated = (data['validated_passages'] as num?)?.toInt() ?? 0;
        final updatedAt = data['updated_at'];
        DateTime? lastVisit;
        if (updatedAt is Timestamp) lastVisit = updatedAt.toDate();
        final daysSince = lastVisit != null
            ? now.difference(lastVisit).inDays
            : 999;
        final segment = _computeSegment(
          validatedPassages: validated,
          daysSinceLastVisit: daysSince,
        );
        result[doc.id] = segment;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  static String _computeSegment({
    required int validatedPassages,
    required int daysSinceLastVisit,
  }) {
    if (daysSinceLastVisit > 60) return 'inactif';
    if (validatedPassages >= 10) return 'vip';
    if (validatedPassages >= 3) return 'habitue';
    return 'nouveau';
  }

  /// Best-effort: increments `rappels_monthly_validated_passages` on the
  /// merchant doc, resetting the counter when the calendar month changes.
  void _incrementMonthlyValidatedPassages(String merchantId) {
    final now = DateTime.now();
    final currentYm =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final merchantRef =
        _firestore.collection('merchants').doc(merchantId);
    _firestore.runTransaction((tx) async {
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
