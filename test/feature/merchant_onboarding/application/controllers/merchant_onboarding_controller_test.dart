import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/application/controllers/merchant_onboarding_controller.dart';
import 'package:flutter_yuztoo/feature/merchant_onboarding/infrastructure/onboarding_storage.dart';
import 'package:mocktail/mocktail.dart';

class MockOnboardingStorage extends Mock implements OnboardingStorage {}

void main() {
  group('MerchantOnboardingController', () {
    late MockOnboardingStorage mockStorage;
    late MerchantOnboardingController controller;

    setUp(() {
      mockStorage = MockOnboardingStorage();
      when(() => mockStorage.loadCategoryId()).thenReturn(null);
      when(() => mockStorage.loadSubcategoryId()).thenReturn(null);
      when(() => mockStorage.saveCategoryId(any())).thenAnswer((_) async {});
      when(() => mockStorage.saveSubcategoryId(any())).thenAnswer((_) async {});
      when(() => mockStorage.clear()).thenAnswer((_) async {});
    });

    test('should initialize with empty state', () {
      // Arrange & Act
      controller = MerchantOnboardingController(mockStorage);

      // Assert
      expect(controller.state.selectedCategoryId, isNull);
      expect(controller.state.selectedSubcategoryId, isNull);
      expect(controller.state.isComplete, isFalse);
    });

    test('should load persisted state on initialization', () {
      // Arrange
      when(() => mockStorage.loadCategoryId()).thenReturn('restaurant');
      when(() => mockStorage.loadSubcategoryId()).thenReturn('restaurant_french');

      // Act
      controller = MerchantOnboardingController(mockStorage);

      // Assert
      expect(controller.state.selectedCategoryId, 'restaurant');
      expect(controller.state.selectedSubcategoryId, 'restaurant_french');
      expect(controller.state.isComplete, isTrue);
    });

    test('should select category and update state', () {
      // Arrange
      controller = MerchantOnboardingController(mockStorage);

      // Act
      controller.selectCategory('restaurant');

      // Assert
      expect(controller.state.selectedCategoryId, 'restaurant');
      expect(controller.state.isComplete, isTrue);
      verify(() => mockStorage.saveCategoryId('restaurant')).called(1);
    });

    test('should not select category if empty string', () {
      // Arrange
      controller = MerchantOnboardingController(mockStorage);

      // Act
      controller.selectCategory('');

      // Assert
      expect(controller.state.selectedCategoryId, isNull);
      verifyNever(() => mockStorage.saveCategoryId(any()));
    });

    test('should select subcategory and update state', () {
      // Arrange
      controller = MerchantOnboardingController(mockStorage);
      controller.selectCategory('restaurant');

      // Act
      controller.selectSubcategory('restaurant_french');

      // Assert
      expect(controller.state.selectedSubcategoryId, 'restaurant_french');
      verify(() => mockStorage.saveSubcategoryId('restaurant_french')).called(1);
    });

    test('should not select subcategory if empty string', () {
      // Arrange
      controller = MerchantOnboardingController(mockStorage);

      // Act
      controller.selectSubcategory('');

      // Assert
      expect(controller.state.selectedSubcategoryId, isNull);
      verifyNever(() => mockStorage.saveSubcategoryId(any()));
    });

    test('should clear category', () {
      // Arrange
      controller = MerchantOnboardingController(mockStorage);
      controller.selectCategory('restaurant');

      // Act
      controller.clearCategory();

      // Assert
      expect(controller.state.selectedCategoryId, isNull);
      expect(controller.state.isComplete, isFalse);
      verify(() => mockStorage.saveCategoryId(null)).called(1);
    });

    test('should clear subcategory', () {
      // Arrange
      controller = MerchantOnboardingController(mockStorage);
      controller.selectSubcategory('restaurant_french');

      // Act
      controller.clearSubcategory();

      // Assert
      expect(controller.state.selectedSubcategoryId, isNull);
      verify(() => mockStorage.saveSubcategoryId(null)).called(1);
    });

    test('should reset all state', () {
      // Arrange
      controller = MerchantOnboardingController(mockStorage);
      controller.selectCategory('restaurant');
      controller.selectSubcategory('restaurant_french');

      // Act
      controller.reset();

      // Assert
      expect(controller.state.selectedCategoryId, isNull);
      expect(controller.state.selectedSubcategoryId, isNull);
      expect(controller.state.isComplete, isFalse);
      verify(() => mockStorage.clear()).called(1);
    });

    test('should update isComplete when category is selected', () {
      // Arrange
      controller = MerchantOnboardingController(mockStorage);

      // Act
      controller.selectCategory('restaurant');

      // Assert
      expect(controller.state.isComplete, isTrue);
      expect(controller.isComplete, isTrue);
    });

    test('should have isComplete false when no category', () {
      // Arrange
      controller = MerchantOnboardingController(mockStorage);

      // Assert
      expect(controller.state.isComplete, isFalse);
      expect(controller.isComplete, isFalse);
    });

    test('should handle null storage gracefully', () {
      // Arrange & Act
      controller = MerchantOnboardingController(null);

      // Assert - Should not throw
      expect(controller.state.selectedCategoryId, isNull);
      controller.selectCategory('restaurant');
      expect(controller.state.selectedCategoryId, 'restaurant');
    });

    test('should get selectedCategoryId', () {
      // Arrange
      controller = MerchantOnboardingController(mockStorage);
      controller.selectCategory('restaurant');

      // Assert
      expect(controller.selectedCategoryId, 'restaurant');
    });

    test('should get selectedSubcategoryId', () {
      // Arrange
      controller = MerchantOnboardingController(mockStorage);
      controller.selectSubcategory('restaurant_french');

      // Assert
      expect(controller.selectedSubcategoryId, 'restaurant_french');
    });

    test('should replace category when selecting new one', () {
      // Arrange
      controller = MerchantOnboardingController(mockStorage);
      controller.selectCategory('restaurant');

      // Act
      controller.selectCategory('retail');

      // Assert
      expect(controller.state.selectedCategoryId, 'retail');
      expect(controller.state.selectedSubcategoryId, isNull); // Should clear subcategory
    });

    test('should replace subcategory when selecting new one', () {
      // Arrange
      controller = MerchantOnboardingController(mockStorage);
      controller.selectCategory('restaurant');
      controller.selectSubcategory('restaurant_french');

      // Act
      controller.selectSubcategory('restaurant_italian');

      // Assert
      expect(controller.state.selectedSubcategoryId, 'restaurant_italian');
    });
  });
}

