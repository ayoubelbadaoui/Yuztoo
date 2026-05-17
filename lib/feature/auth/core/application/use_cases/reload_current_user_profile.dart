import '../../../../../core/domain/core/result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Fetches a fresh [AuthUser] from Firebase Auth + Firestore (no stream).
class ReloadCurrentUserProfile {
  const ReloadCurrentUserProfile(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser?>> call() => _repository.reloadCurrentUserProfile();
}
