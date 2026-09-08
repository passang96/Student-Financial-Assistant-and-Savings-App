import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

abstract interface class UserProfileStore {
  Future<Map<String, dynamic>?> load(String uid);

  Future<void> save(UserProfile profile);
}

class FirebaseUserProfileStore implements UserProfileStore {
  FirebaseUserProfileStore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static String documentPath(String uid) => 'users/$uid';

  @override
  Future<Map<String, dynamic>?> load(String uid) async {
    final snapshot = await _firestore.doc(documentPath(uid)).get();
    return snapshot.data();
  }

  @override
  Future<void> save(UserProfile profile) {
    return _firestore.doc(documentPath(profile.uid)).set({
      'uid': profile.uid,
      'displayName': profile.displayName,
      'email': profile.email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
