import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/firebase_providers.dart';
import '../domain/repositories/scheduled_notification_repository.dart';
import 'firestore_scheduled_notification_repository.dart';

final scheduledNotificationRepositoryProvider =
    Provider<ScheduledNotificationRepository>((ref) {
  final firestore = ref.read(firebaseFirestoreProvider);
  return FirestoreScheduledNotificationRepository(firestore: firestore);
});
