import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_financial_assistant/main.dart';
import 'package:student_financial_assistant/models/user_profile.dart';
import 'package:student_financial_assistant/services/auth_service.dart';
import 'package:student_financial_assistant/services/user_profile_store.dart';

void main() {
  testWidgets('profile loads, saves, and remains updated after reopening', (
    tester,
  ) async {
    final user = _MutableFakeUser(
      uid: 'authenticated-user',
      email: 'student@example.com',
      displayName: 'Authentication Name',
    );
    final auth = _SessionFakeFirebaseAuth(user);
    final store = _MemoryProfileStore(
      UserProfile(
        uid: user.uid,
        displayName: 'Stored Student',
        email: user.email!,
      ),
    );
    addTearDown(auth.close);

    await tester.pumpWidget(
      MyApp(
        authService: AuthService(firebaseAuth: auth, profileStore: store),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Stored Student'), findsOneWidget);
    expect(find.text('student@example.com'), findsOneWidget);
    expect(find.text('authenticated-user'), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit-profile-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('profile-name-field')),
      'Updated Student',
    );
    await tester.tap(find.byKey(const Key('save-profile-button')));
    await tester.pumpAndSettle();

    expect(find.text('Updated Student'), findsOneWidget);
    expect(find.text('Profile updated successfully.'), findsOneWidget);
    expect(store.savedProfile?.uid, 'authenticated-user');
    expect(store.savedProfile?.displayName, 'Updated Student');

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Updated Student'), findsOneWidget);
    expect(store.loadedUids, everyElement('authenticated-user'));
  });

  testWidgets('profile edit validates the required name', (tester) async {
    final user = _MutableFakeUser(
      uid: 'authenticated-user',
      email: 'student@example.com',
      displayName: 'Student',
    );
    final auth = _SessionFakeFirebaseAuth(user);
    final store = _MemoryProfileStore(UserProfile.fromUser(user));
    addTearDown(auth.close);

    await tester.pumpWidget(
      MyApp(
        authService: AuthService(firebaseAuth: auth, profileStore: store),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-profile-button')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('profile-name-field')), '');
    await tester.tap(find.byKey(const Key('save-profile-button')));
    await tester.pump();

    expect(find.text('Name is required'), findsOneWidget);
    expect(store.saveCalls, 0);
  });

  testWidgets('Help & FAQ opens and displays its content', (tester) async {
    final user = _MutableFakeUser(
      uid: 'authenticated-user',
      email: 'student@example.com',
      displayName: 'Student',
    );
    final auth = _SessionFakeFirebaseAuth(user);
    addTearDown(auth.close);

    await tester.pumpWidget(
      MyApp(authService: AuthService(firebaseAuth: auth)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Help & FAQ'));
    await tester.pumpAndSettle();

    expect(find.text('Help & FAQ'), findsOneWidget);
    expect(find.text('How can we help?'), findsOneWidget);
    final question = find.text('How is my financial data protected?');
    expect(question, findsOneWidget);
    await tester.tap(question);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('kept under your signed-in account'),
      findsOneWidget,
    );
  });

  testWidgets('logout from Profile clears the session', (tester) async {
    final user = _MutableFakeUser(
      uid: 'authenticated-user',
      email: 'student@example.com',
      displayName: 'Student',
    );
    final auth = _SessionFakeFirebaseAuth(user);
    addTearDown(auth.close);

    await tester.pumpWidget(
      MyApp(authService: AuthService(firebaseAuth: auth)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-logout-button')));
    await tester.pumpAndSettle();

    expect(auth.signOutCalled, isTrue);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Logged out successfully.'), findsOneWidget);
  });
}

class _SessionFakeFirebaseAuth implements FirebaseAuth {
  _SessionFakeFirebaseAuth(this._currentUser);

  final _authStates = StreamController<User?>.broadcast();
  final _userChanges = StreamController<User?>.broadcast();
  User? _currentUser;
  bool signOutCalled = false;

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<User?> authStateChanges() => _authStates.stream;

  @override
  Stream<User?> userChanges() => _userChanges.stream;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
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

class _MutableFakeUser implements User {
  _MutableFakeUser({
    required this.uid,
    required this.email,
    required String displayName,
  }) : _displayName = displayName;

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
  _MemoryProfileStore(this.savedProfile);

  UserProfile? savedProfile;
  final List<String> loadedUids = [];
  int saveCalls = 0;

  @override
  Future<Map<String, dynamic>?> load(String uid) async {
    loadedUids.add(uid);
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
    saveCalls++;
    savedProfile = profile;
  }
}
