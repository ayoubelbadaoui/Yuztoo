import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/infrastructure/firebase_providers.dart';
import '../domain/repositories/auto_notification_repository.dart';
import 'firestore_auto_notification_repository.dart';

final autoNotificationRepositoryProvider =
    Provider<AutoNotificationRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirestoreAutoNotificationRepository(firestore);
});
