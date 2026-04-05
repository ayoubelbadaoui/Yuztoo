import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/infrastructure/firestore_user_rules_patch.dart';

void main() {
  test('mergeUserPatchForFirestoreRules adds onboarding and roles when missing',
      () {
    final patch = <String, dynamic>{'cities': <String>['Paris']};
    mergeUserPatchForFirestoreRules(
      <String, dynamic>{'merchant_id': 'mid'},
      patch,
    );
    expect(patch['onboarding'], isA<Map>());
    expect(patch['roles'], isA<Map>());
    expect((patch['roles'] as Map)['merchant'], true);
  });

  test('mergeUserPatchForFirestoreRules leaves valid existing data alone', () {
    final existing = <String, dynamic>{
      'onboarding': <String, dynamic>{
        'merchant': 'completed',
        'client': 'completed',
      },
      'roles': <String, dynamic>{
        'client': false,
        'merchant': true,
        'provider': true,
      },
    };
    final patch = <String, dynamic>{'cities': <String>['Lyon']};
    mergeUserPatchForFirestoreRules(existing, patch);
    expect(patch.containsKey('onboarding'), false);
    expect(patch.containsKey('roles'), false);
  });
}
