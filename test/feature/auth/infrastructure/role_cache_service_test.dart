import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/auth/core/infrastructure/role_cache_service.dart';
import 'package:flutter_yuztoo/types.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RoleCacheService', () {
    late RoleCacheService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = RoleCacheService();
    });

    test('stores last role per user id', () async {
      await service.saveLastSelectedRole(UserRole.merchant, userId: 'user_a');
      await service.saveLastSelectedRole(UserRole.client, userId: 'user_b');

      expect(
        await service.readLastSelectedRole(userId: 'user_a'),
        UserRole.merchant,
      );
      expect(
        await service.readLastSelectedRole(userId: 'user_b'),
        UserRole.client,
      );
    });

    test('falls back to global key when per-user key is missing', () async {
      await service.saveLastSelectedRole(UserRole.merchant);
      expect(
        await service.readLastSelectedRole(userId: 'new_user'),
        UserRole.merchant,
      );
    });
  });
}
