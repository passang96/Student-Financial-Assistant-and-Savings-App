import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_financial_assistant/main.dart';
import 'package:student_financial_assistant/services/auth_service.dart';

void main() {
  testWidgets('logout clears the session and returns to Login', (tester) async {
    final firebaseAuth = _FakeFirebaseAuth(
      initialUser: _FakeUser(
        uid: 'firebase-uid-123',
        email: 'pema@example.com',
        displayName: 'Pema',
      ),
    );
    addTearDown(firebaseAuth.close);

    await tester.pumpWidget(
      MyApp(authService: AuthService(firebaseAuth: firebaseAuth)),
    );
    await tester.pump();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Hello, Pema!'), findsOneWidget);
    expect(find.text('pema@example.com'), findsOneWidget);

    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();

    expect(firebaseAuth.signOutCalled, isTrue);
    expect(firebaseAuth.currentUser, isNull);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Logged out successfully.'), findsOneWidget);
  });

  testWidgets('Profile closes if the Firebase session ends externally', (
    tester,
  ) async {
    final firebaseAuth = _FakeFirebaseAuth(
      initialUser: _FakeUser(
        uid: 'correct-profile-uid',
        email: 'pema@example.com',
        displayName: 'Pema',
      ),
    );
    addTearDown(firebaseAuth.close);

    await tester.pumpWidget(
      MyApp(authService: AuthService(firebaseAuth: firebaseAuth)),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('correct-profile-uid'), findsOneWidget);

    firebaseAuth.endSession();
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);
  });

  test('logout returns an understandable Firebase error', () async {
    final firebaseAuth = _FakeFirebaseAuth(
      initialUser: _FakeUser(
        uid: 'firebase-uid-123',
        email: 'pema@example.com',
        displayName: 'Pema',
      ),
      signOutError: FirebaseAuthException(code: 'network-request-failed'),
    );
    addTearDown(firebaseAuth.close);
    final authService = AuthService(firebaseAuth: firebaseAuth);

    final result = await authService.logout();

    expect(result.isSuccess, isFalse);
    expect(result.message, 'Check your internet connection and try again.');
    expect(firebaseAuth.currentUser?.uid, 'firebase-uid-123');
  });
}

class _FakeFirebaseAuth implements FirebaseAuth {
  _FakeFirebaseAuth({User? initialUser, this.signOutError})
    : _currentUser = initialUser;

  final _authStateController = StreamController<User?>.broadcast();
  final _userController = StreamController<User?>.broadcast();
  final Object? signOutError;

  User? _currentUser;
  bool signOutCalled = false;

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> authStateChanges() => _authStateController.stream;

  @override
  Stream<User?> userChanges() => _userController.stream;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    if (signOutError case final error?) {
      throw error;
    }
    endSession();
  }

  void endSession() {
    _currentUser = null;
    _authStateController.add(null);
    _userController.add(null);
  }

  Future<void> close() async {
    await _authStateController.close();
    await _userController.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUser implements User {
  _FakeUser({required this.uid, this.email, this.displayName});

  @override
  final String uid;

  @override
  final String? email;

  @override
  final String? displayName;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
