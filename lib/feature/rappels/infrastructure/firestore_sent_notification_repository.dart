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
      return const Left(UnexpectedFailure(message: 'merchantId is required'));
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
      final ref = await _col(notification.merchantId).add(dto.toFirestore());
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
}
