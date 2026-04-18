import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/repositories/client_notification_repository.dart';
import 'firestore_client_notification_repository.dart';

final clientNotificationRepositoryProvider =
    Provider<ClientNotificationRepository>((ref) {
  return FirestoreClientNotificationRepository(
    firestore: FirebaseFirestore.instance,
  );
});
