import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/infrastructure/firebase_providers.dart';
import '../domain/repositories/notification_template_repository.dart';
import 'firestore_notification_template_repository.dart';

final notificationTemplateRepositoryProvider =
    Provider<NotificationTemplateRepository>((ref) {
  final firestore = ref.read(firebaseFirestoreProvider);
  return FirestoreNotificationTemplateRepository(firestore: firestore);
});
