import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_yuztoo/feature/auth/core/infrastructure/role_cache_service.dart';
import 'package:flutter_yuztoo/types.dart';

void main() {
  late RoleCacheService service;

  setUp(() async {
    // Clear SharedPreferences before each test
    SharedPreferences.setMockInitialValues({});
    service = RoleCacheService();
  });

  group('RoleCacheService', () {
    test('should return null when no role is cached', () async {
      // Act
      final result = await service.getLastSelectedRole();

      // Assert
      expect(result, isNull);
    });

    test('should save and retrieve client role', () async {
      // Act
      await service.saveLastSelectedRole(UserRole.client);
      final result = await service.getLastSelectedRole();

      // Assert
      expect(result, UserRole.client);
    });

    test('should save and retrieve merchant role', () async {
      // Act
      await service.saveLastSelectedRole(UserRole.merchant);
      final result = await service.getLastSelectedRole();

      // Assert
      expect(result, UserRole.merchant);
    });

    test('should update cached role', () async {
      // Arrange
      await service.saveLastSelectedRole(UserRole.client);

      // Act
      await service.saveLastSelectedRole(UserRole.merchant);
      final result = await service.getLastSelectedRole();

      // Assert
      expect(result, UserRole.merchant);
    });

    test('should clear cached role', () async {
      // Arrange
      await service.saveLastSelectedRole(UserRole.client);

      // Act
      await service.clearLastSelectedRole();
      final result = await service.getLastSelectedRole();

      // Assert
      expect(result, isNull);
    });

    test('should handle multiple save operations', () async {
      // Act
      await service.saveLastSelectedRole(UserRole.client);
      await service.saveLastSelectedRole(UserRole.merchant);
      await service.saveLastSelectedRole(UserRole.client);
      final result = await service.getLastSelectedRole();

      // Assert
      expect(result, UserRole.client);
    });
  });
}

