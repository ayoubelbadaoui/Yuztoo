import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/domain/core/either.dart';
import '../../../core/domain/core/failure.dart';
import '../../../core/domain/core/result.dart';
import '../domain/entities/scheduled_notification.dart';
import '../domain/repositories/scheduled_notification_repository.dart';

class FirestoreScheduledNotificationRepository
    implements ScheduledNotificationRepository {
  FirestoreScheduledNotificationRepository(
      {required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _coll(String merchantId) =>
      _firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('scheduled_notifications');

  @override
  Stream<List<ScheduledNotification>> watchAll(String merchantId) {
    if (merchantId.isEmpty) {
      return Stream<List<ScheduledNotification>>.value(const []);
    }
    return _coll(merchantId)
        .orderBy('scheduled_at', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => _fromDoc(d.id, d.data()))
            .where((s) => s != null)
            .cast<ScheduledNotification>()
            .toList());
  }

  @override
  Future<Result<String>> schedule({
    required String merchantId,
    required String createdByUid,
    required String text,
    required String audience,
    required List<String> segments,
    required DateTime scheduledAt,
  }) async {
    if (merchantId.isEmpty || createdByUid.isEmpty) {
      return const Left<AppFailure, String>(
          UnexpectedFailure(message: 'merchantId & createdByUid required'));
    }
    final cleaned = text.trim();
    if (cleaned.isEmpty) {
      return const Left<AppFailure, String>(
          UnexpectedFailure(message: 'Le message ne peut pas être vide'));
    }
    if (cleaned.length > 500) {
      return const Left<AppFailure, String>(UnexpectedFailure(
          message: 'Message trop long (max 500 caractères)'));
    }
    if (!_validAudiences.contains(audience)) {
      return const Left<AppFailure, String>(
          UnexpectedFailure(message: 'Audience invalide'));
    }
    // The "5 minutes from now" floor protects against accidental
    // immediate sends from a date picker that hasn't moved off "today".
    // The tick CF runs every 5 minutes anyway, so anything sub-5min
    // would land at the same tick as an immediate send with extra
    // round-trips.
    final earliest =
        DateTime.now().toUtc().add(const Duration(minutes: 5));
    if (scheduledAt.toUtc().isBefore(earliest)) {
      return const Left<AppFailure, String>(UnexpectedFailure(
          message: 'L\'envoi doit être programmé au moins 5 min plus tard.'));
    }
    try {
      final ref = await _coll(merchantId).add({
        'text': cleaned,
        'audience': audience,
        'segments': segments,
        'scheduled_at': Timestamp.fromDate(scheduledAt.toUtc()),
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'created_by_uid': createdByUid,
      });
      return Right<AppFailure, String>(ref.id);
    } catch (e) {
      return Left<AppFailure, String>(UnexpectedFailure(
          message: 'Impossible de programmer la notification', cause: e));
    }
  }

  @override
  Future<Result<Unit>> cancel({
    required String merchantId,
    required String scheduledId,
  }) async {
    if (merchantId.isEmpty || scheduledId.isEmpty) {
      return const Left<AppFailure, Unit>(
          UnexpectedFailure(message: 'ids required'));
    }
    try {
      // Read-then-write: don't override a status the CF has already
      // flipped to `sent`. The race window is small (between the
      // CF's transaction commit and the merchant's tap) but still real.
      final ref = _coll(merchantId).doc(scheduledId);
      final snap = await ref.get();
      if (!snap.exists) {
        return const Right<AppFailure, Unit>(unit);
      }
      final status = snap.data()?['status'] as String?;
      if (status == 'sent') {
        return const Left<AppFailure, Unit>(UnexpectedFailure(
            message: 'Cette notification a déjà été envoyée.'));
      }
      if (status == 'cancelled') {
        return const Right<AppFailure, Unit>(unit);
      }
      await ref.update({'status': 'cancelled'});
      return const Right<AppFailure, Unit>(unit);
    } catch (e) {
      return Left<AppFailure, Unit>(UnexpectedFailure(
          message: 'Impossible d\'annuler', cause: e));
    }
  }

  static const _validAudiences = {'Tous mes clients', 'Certains clients'};

  ScheduledNotification? _fromDoc(String id, Map<String, dynamic> data) {
    try {
      final text = (data['text'] as String?)?.trim() ?? '';
      if (text.isEmpty) return null;
      final scheduledAt = _ts(data['scheduled_at']);
      if (scheduledAt == null) return null;
      final rawStatus = (data['status'] as String?) ?? 'pending';
      final status = switch (rawStatus) {
        'pending' => ScheduledNotificationStatus.pending,
        'sent' => ScheduledNotificationStatus.sent,
        'cancelled' => ScheduledNotificationStatus.cancelled,
        'failed' => ScheduledNotificationStatus.failed,
        _ => null,
      };
      if (status == null) return null;
      final rawSegments = data['segments'];
      final segments = rawSegments is List
          ? rawSegments.whereType<String>().toList()
          : <String>[];
      return ScheduledNotification(
        id: id,
        text: text,
        audience: (data['audience'] as String?) ?? 'Tous mes clients',
        segments: segments,
        scheduledAt: scheduledAt,
        status: status,
        createdAt: _ts(data['created_at']),
        createdByUid: data['created_by_uid'] as String?,
        sentAt: _ts(data['sent_at']),
        sentCount: data['sent_count'] is int
            ? data['sent_count'] as int
            : null,
        failureReason: data['failure_reason'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}
