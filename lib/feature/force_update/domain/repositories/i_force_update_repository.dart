import '../entities/force_update_config.dart';

abstract class IForceUpdateRepository {
  /// Live stream of `app_config/force_update`. Missing doc → disabled.
  Stream<ForceUpdateConfig> watchConfig();
}
