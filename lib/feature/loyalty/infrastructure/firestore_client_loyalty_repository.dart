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
  FirestoreClientLoyaltyRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

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
    return ClientMerchantLoyaltyProgress(
      validatedPassages: v,
      pendingPassages: p,
      cumulativeSpendEuros: c,
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
    try {
      final progress = await _firestore.runTransaction(
        (Transaction tx) async {
          final ref = _docRef(merchantId, clientUid);
          final snap = await tx.get(ref);
          final cur = _fromMap(snap.data());
          if (pendingPassagesDelta < 0 &&
              cur.pendingPassages < -pendingPassagesDelta) {
            throw StateError('no_pending_passage');
          }
          final next = ClientMerchantLoyaltyProgress(
            validatedPassages: cur.validatedPassages + validatedPassagesDelta,
            pendingPassages: cur.pendingPassages + pendingPassagesDelta,
            cumulativeSpendEuros:
                cur.cumulativeSpendEuros + cumulativeSpendEurosDelta,
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
}
