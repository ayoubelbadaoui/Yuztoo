import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/failure.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/infrastructure/logger_service.dart';
import '../domain/entities/sent_notification.dart';
import '../domain/repositories/i_sent_notification_repository.dart';
import 'dto/sent_notification_dto.dart';

/// Firestore: `merchants/{merchantId}/sent_notifications/{id}`
class FirestoreSentNotificationRepository implements ISentNotificationRepository {
  FirestoreSentNotificationRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String merchantId) => _firestore
      .collection('merchants')
      .doc(merchantId)
      .collection('sent_notifications');

  @override
  Future<Result<List<SentNotification>>> list(
    String merchantId, {
    int limit = 20,
  }) async {
    if (merchantId.isEmpty) return const Right([]);
    try {
      final snap = await _col(merchantId)
          .orderBy('sent_at', descending: true)
          .limit(limit)
          .get();
      final items = snap.docs
          .map((d) => SentNotificationDto.fromFirestore(d).toDomain())
          .toList();
      return Right(items);
    } on FirebaseException catch (e, st) {
      LoggerService.logError('listSentNotifications', error: e, stackTrace: st);
      return Left(UnexpectedFailure(
          message: 'Impossible de charger l\'historique', cause: e, stackTrace: st));
    } catch (e, st) {
      LoggerService.logError('listSentNotifications', error: e, stackTrace: st);
      return Left(UnexpectedFailure(message: 'Erreur de chargement', cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<SentNotification>> create(SentNotification notification) async {
    if (notification.merchantId.isEmpty) {
      return const Left(UnexpectedFailure(message: 'L\'identifiant du commerce est requis'));
    }
    try {
      final dto = SentNotificationDto(
        id: '',
        merchantId: notification.merchantId,
        text: notification.text,
        audience: notification.audience,
        segments: notification.segments,
        sentCount: notification.sentCount,
        sentAt: notification.sentAt,
      );
      final col = _col(notification.merchantId);
      final ref =
          notification.id.isNotEmpty ? col.doc(notification.id) : col.doc();
      await ref.set(dto.toFirestore());
      final created = notification.copyWith(id: ref.id);
      return Right(created);
    } on FirebaseException catch (e, st) {
      LoggerService.logError('createSentNotification', error: e, stackTrace: st);
      return Left(UnexpectedFailure(
          message: 'Impossible d\'enregistrer l\'envoi', cause: e, stackTrace: st));
    } catch (e, st) {
      LoggerService.logError('createSentNotification', error: e, stackTrace: st);
      return Left(UnexpectedFailure(message: 'Erreur d\'enregistrement', cause: e, stackTrace: st));
    }
  }

  @override
  Future<void> updateSentCount(
    String merchantId,
    String sentNotificationId,
    int sentCount,
  ) async {
    if (merchantId.isEmpty || sentNotificationId.isEmpty) return;
    try {
      await _col(merchantId).doc(sentNotificationId).set(
        {'sent_count': sentCount},
        SetOptions(merge: true),
      );
    } catch (e, st) {
      LoggerService.logError(
        'updateSentCount',
        error: e,
        stackTrace: st,
        context: {'merchantId': merchantId, 'sentNotificationId': sentNotificationId},
      );
    }
  }

  @override
  Future<void> recordOpen(String merchantId, String sentNotificationId) async {
    if (merchantId.isEmpty || sentNotificationId.isEmpty) return;
    try {
      await _col(merchantId).doc(sentNotificationId).set(
        {'open_count': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
    } catch (e, st) {
      LoggerService.logError(
        'recordOpen',
        error: e,
        stackTrace: st,
        context: {'merchantId': merchantId, 'sentNotificationId': sentNotificationId},
      );
    }
  }

  @override
  Future<void> incrementWeeklyNotifCount(String merchantId) async {
    if (merchantId.isEmpty) return;
    try {
      final docRef = _firestore.collection('merchants').doc(merchantId);
      final snap = await docRef.get();
      final data = snap.data();
      final resetAt = data?['weekly_notif_reset_at'];
      DateTime? lastReset;
      if (resetAt is Timestamp) lastReset = resetAt.toDate();

      final shouldReset = lastReset == null ||
          DateTime.now().difference(lastReset).inDays >= 7;

      if (shouldReset) {
        await docRef.update({
          'weekly_notif_sent_count': 1,
          'weekly_notif_reset_at': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.update({
          'weekly_notif_sent_count': FieldValue.increment(1),
        });
      }
    } catch (e, st) {
      LoggerService.logError('incrementWeeklyNotifCount', error: e, stackTrace: st);
    }
  }
}
