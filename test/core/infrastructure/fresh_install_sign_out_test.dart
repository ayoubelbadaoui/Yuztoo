import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_yuztoo/core/infrastructure/firebase_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeUser implements User {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuth implements FirebaseAuth {
  _FakeAuth({required bool signedIn}) : _user = signedIn ? _FakeUser() : null;

  User? _user;
  int signOutCalls = 0;

  @override
  User? get currentUser => _user;

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _user = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fresh install (no saved data): keychain session is signed out',
      () async {
    SharedPreferences.setMockInitialValues({});
    final auth = _FakeAuth(signedIn: true);

    await signOutSessionRestoredByFreshInstall(auth: auth);

    expect(auth.signOutCalls, 1);
    expect(auth.currentUser, isNull);
  });

  test('app update (saved data, no marker yet): user stays signed in',
      () async {
    SharedPreferences.setMockInitialValues({'last_selected_role': 'client'});
    final auth = _FakeAuth(signedIn: true);

    await signOutSessionRestoredByFreshInstall(auth: auth);

    expect(auth.signOutCalls, 0);
  });

  test('later launches never sign out', () async {
    SharedPreferences.setMockInitialValues({});
    final auth = _FakeAuth(signedIn: false);
    await signOutSessionRestoredByFreshInstall(auth: auth); // first launch

    final restored = _FakeAuth(signedIn: true);
    await signOutSessionRestoredByFreshInstall(auth: restored);

    expect(restored.signOutCalls, 0);
  });
}
