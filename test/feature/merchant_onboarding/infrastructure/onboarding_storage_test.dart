import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/infrastructure/onboarding_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OnboardingStorage', () {
    late SharedPreferences prefs;
    late OnboardingStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = OnboardingStorage(prefs);
    });

    test('should save and load category ID', () async {
      // Act
      await storage.saveCategoryId('restaurant');
      final loaded = storage.loadCategoryId();

      // Assert
      expect(loaded, 'restaurant');
    });

    test('should save and load subcategory ID', () async {
      // Act
      await storage.saveSubcategoryId('restaurant_french');
      final loaded = storage.loadSubcategoryId();

      // Assert
      expect(loaded, 'restaurant_french');
    });

    test('should return null when category ID not set', () {
      // Act
      final loaded = storage.loadCategoryId();

      // Assert
      expect(loaded, isNull);
    });

    test('should return null when subcategory ID not set', () {
      // Act
      final loaded = storage.loadSubcategoryId();

      // Assert
      expect(loaded, isNull);
    });

    test('should remove category ID when saving null', () async {
      // Arrange
      await storage.saveCategoryId('restaurant');

      // Act
      await storage.saveCategoryId(null);
      final loaded = storage.loadCategoryId();

      // Assert
      expect(loaded, isNull);
    });

    test('should remove subcategory ID when saving null', () async {
      // Arrange
      await storage.saveSubcategoryId('restaurant_french');

      // Act
      await storage.saveSubcategoryId(null);
      final loaded = storage.loadSubcategoryId();

      // Assert
      expect(loaded, isNull);
    });

    test('should remove category ID when saving empty string', () async {
      // Arrange
      await storage.saveCategoryId('restaurant');

      // Act
      await storage.saveCategoryId('');
      final loaded = storage.loadCategoryId();

      // Assert
      expect(loaded, isNull);
    });

    test('should remove subcategory ID when saving empty string', () async {
      // Arrange
      await storage.saveSubcategoryId('restaurant_french');

      // Act
      await storage.saveSubcategoryId('');
      final loaded = storage.loadSubcategoryId();

      // Assert
      expect(loaded, isNull);
    });

    test('should clear all state', () async {
      // Arrange
      await storage.saveCategoryId('restaurant');
      await storage.saveSubcategoryId('restaurant_french');

      // Act
      await storage.clear();

      // Assert
      expect(storage.loadCategoryId(), isNull);
      expect(storage.loadSubcategoryId(), isNull);
    });

    test('should update category ID when saving new value', () async {
      // Arrange
      await storage.saveCategoryId('restaurant');

      // Act
      await storage.saveCategoryId('retail');
      final loaded = storage.loadCategoryId();

      // Assert
      expect(loaded, 'retail');
    });

    test('should update subcategory ID when saving new value', () async {
      // Arrange
      await storage.saveSubcategoryId('restaurant_french');

      // Act
      await storage.saveSubcategoryId('restaurant_italian');
      final loaded = storage.loadSubcategoryId();

      // Assert
      expect(loaded, 'restaurant_italian');
    });

    test('should persist data across instances', () async {
      // Arrange
      await storage.saveCategoryId('restaurant');
      await storage.saveSubcategoryId('restaurant_french');

      // Act - Create new instance
      final newStorage = OnboardingStorage(prefs);

      // Assert
      expect(newStorage.loadCategoryId(), 'restaurant');
      expect(newStorage.loadSubcategoryId(), 'restaurant_french');
    });
  });
}

