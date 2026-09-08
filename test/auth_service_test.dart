import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_financial_assistant/models/user_profile.dart';
import 'package:student_financial_assistant/services/auth_service.dart';
import 'package:student_financial_assistant/services/user_profile_store.dart';

void main() {
  group('AuthService', () {
    test('logs in with trimmed valid input', () async {
      final auth = _FakeFirebaseAuth(
        signInUser: _FakeUser(
          uid: 'user-a',
          email: 'student@example.com',
          displayName: 'Student',
        ),
      );
      addTearDown(auth.close);
      final service = AuthService(firebaseAuth: auth);

      final result = await service.login(
        email: '  student@example.com ',
        password: 'secret1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.userId, 'user-a');
      expect(auth.lastSignInEmail, 'student@example.com');
      expect(auth.lastSignInPassword, 'secret1');
    });

    test('rejects invalid login input before calling Firebase', () async {
      final auth = _FakeFirebaseAuth();
      addTearDown(auth.close);
      final service = AuthService(firebaseAuth: auth);

      final badEmail = await service.login(
        email: 'not-an-email',
        password: 'secret1',
      );
      final badPassword = await service.login(
        email: 'student@example.com',
        password: '123',
      );

      expect(badEmail.message, 'Enter a valid email address.');
      expect(badPassword.message, 'Password must be at least 6 characters.');
      expect(auth.signInCalls, 0);
    });

    test('maps login failures without exposing raw Firebase errors', () async {
      final auth = _FakeFirebaseAuth(
        signInError: FirebaseAuthException(
          code: 'invalid-credential',
          message: 'RAW_FIREBASE_MESSAGE',
        ),
      );
      addTearDown(auth.close);
      final service = AuthService(firebaseAuth: auth);

      final result = await service.login(
        email: 'student@example.com',
        password: 'secret1',
      );

      expect(result.isSuccess, isFalse);
      expect(result.message, 'Incorrect email or password.');
      expect(result.message, isNot(contains('RAW_FIREBASE_MESSAGE')));
    });

    test('registers and saves the profile for the authenticated UID', () async {
      final user = _FakeUser(uid: 'new-user-uid', email: 'new@example.com');
      final auth = _FakeFirebaseAuth(createUser: user);
      final store = _MemoryProfileStore();
      addTearDown(auth.close);
      final service = AuthService(firebaseAuth: auth, profileStore: store);

      final result = await service.register(
        name: '  New Student  ',
        email: ' new@example.com ',
        password: 'secret1',
        confirmPassword: 'secret1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.userId, 'new-user-uid');
      expect(user.displayName, 'New Student');
      expect(store.savedProfile?.uid, 'new-user-uid');
      expect(store.savedProfile?.displayName, 'New Student');
    });

    test('rejects missing and mismatched registration input', () async {
      final auth = _FakeFirebaseAuth();
      addTearDown(auth.close);
      final service = AuthService(firebaseAuth: auth);

      final missingName = await service.register(
        name: '',
        email: 'new@example.com',
        password: 'secret1',
        confirmPassword: 'secret1',
      );
      final mismatch = await service.register(
        name: 'New Student',
        email: 'new@example.com',
        password: 'secret1',
        confirmPassword: 'secret2',
      );

      expect(missingName.message, 'Name is required.');
      expect(mismatch.message, 'Passwords do not match.');
      expect(auth.createUserCalls, 0);
    });

    test(
      'sends a reset link for valid email and rejects invalid email',
      () async {
        final auth = _FakeFirebaseAuth();
        addTearDown(auth.close);
        final service = AuthService(firebaseAuth: auth);

        final invalid = await service.forgotPassword(email: 'bad-email');
        final valid = await service.forgotPassword(
          email: '  student@example.com ',
        );

        expect(invalid.isSuccess, isFalse);
        expect(invalid.message, 'Enter a valid email address.');
        expect(valid.isSuccess, isTrue);
        expect(
          valid.message,
          'If an account exists for that email, a reset link was sent.',
        );
        expect(auth.resetEmails, ['student@example.com']);
      },
    );
  });
}

class _FakeFirebaseAuth implements FirebaseAuth {
  _FakeFirebaseAuth({this.signInUser, this.createUser, this.signInError});

  final User? signInUser;
  final User? createUser;
  final Object? signInError;
  final _authStates = StreamController<User?>.broadcast();
  final _userChanges = StreamController<User?>.broadcast();

  User? _currentUser;
  int signInCalls = 0;
  int createUserCalls = 0;
  String? lastSignInEmail;
  String? lastSignInPassword;
  final List<String> resetEmails = [];

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> authStateChanges() => _authStates.stream;

  @override
  Stream<User?> userChanges() => _userChanges.stream;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    lastSignInEmail = email;
    lastSignInPassword = password;
    if (signInError case final error?) {
      throw error;
    }
    _currentUser = signInUser;
    return _FakeUserCredential(signInUser);
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    createUserCalls++;
    _currentUser = createUser;
    return _FakeUserCredential(createUser);
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    resetEmails.add(email);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authStates.add(null);
    _userChanges.add(null);
  }

  Future<void> close() async {
    await _authStates.close();
    await _userChanges.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUserCredential implements UserCredential {
  const _FakeUserCredential(this.user);

  @override
  final User? user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUser implements User {
  _FakeUser({required this.uid, this.email, String? displayName})
    : _displayName = displayName;

  @override
  final String uid;

  @override
  final String? email;

  String? _displayName;

  @override
  String? get displayName => _displayName;

  @override
  Future<void> updateDisplayName(String? displayName) async {
    _displayName = displayName;
  }

  @override
  Future<void> reload() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryProfileStore implements UserProfileStore {
  UserProfile? savedProfile;

  @override
  Future<Map<String, dynamic>?> load(String uid) async {
    final profile = savedProfile;
    if (profile == null || profile.uid != uid) {
      return null;
    }
    return {
      'uid': profile.uid,
      'displayName': profile.displayName,
      'email': profile.email,
    };
  }

  @override
  Future<void> save(UserProfile profile) async {
    savedProfile = profile;
  }
}
