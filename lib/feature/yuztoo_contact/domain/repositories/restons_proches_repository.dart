import '../../../../core/domain/core/result.dart';
import '../entities/restons_proches_profile.dart';

abstract class RestonsProchesRepository {
  /// Loads the public Restons proches profile, or null when this Firebase
  /// project has no YuzToo official merchant id.
  Future<Result<RestonsProchesProfile?>> getProfile();

  /// Persists every editable field. Caller must be the merchant owner.
  Future<Result<RestonsProchesProfile>> saveProfile(
    RestonsProchesProfile profile,
  );
}
