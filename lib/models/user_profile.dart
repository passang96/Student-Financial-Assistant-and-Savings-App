import 'package:firebase_auth/firebase_auth.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
  });

  final String uid;
  final String displayName;
  final String email;

  factory UserProfile.fromUser(User user) {
    return UserProfile(
      uid: user.uid,
      displayName: user.displayName?.trim() ?? '',
      email: user.email?.trim() ?? '',
    );
  }

  factory UserProfile.fromMap({
    required String uid,
    required Map<String, dynamic> data,
    required User fallbackUser,
  }) {
    final storedName = data['displayName'];
    final storedEmail = data['email'];

    return UserProfile(
      uid: uid,
      displayName: storedName is String && storedName.trim().isNotEmpty
          ? storedName.trim()
          : fallbackUser.displayName?.trim() ?? '',
      email: storedEmail is String && storedEmail.trim().isNotEmpty
          ? storedEmail.trim()
          : fallbackUser.email?.trim() ?? '',
    );
  }
}
