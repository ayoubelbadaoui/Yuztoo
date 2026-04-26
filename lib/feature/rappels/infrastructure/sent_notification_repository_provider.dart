import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/infrastructure/firebase_providers.dart';
import '../domain/repositories/i_sent_notification_repository.dart';
import 'firestore_sent_notification_repository.dart';

final sentNotificationRepositoryProvider =
    Provider<ISentNotificationRepository>((ref) {
  final firestore = ref.read(firebaseFirestoreProvider);
  return FirestoreSentNotificationRepository(firestore: firestore);
});
