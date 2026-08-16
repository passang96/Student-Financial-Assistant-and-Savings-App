import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get categories {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    return _firestore.collection('users').doc(uid).collection('categories');
  }

  Future<void> addCategory({required String name, required String type}) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    if (name.trim().isEmpty) {
      throw Exception('Category name cannot be empty');
    }

    final cleanName = name.trim();
    final cleanType = type.trim().toLowerCase();

    if (cleanType != 'income' && cleanType != 'expense') {
      throw Exception('Category type must be income or expense');
    }

    final existing = await categories
        .where('name', isEqualTo: cleanName)
        .where('type', isEqualTo: cleanType)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Category already exists');
    }

    await categories.add({
      'name': cleanName,
      'type': cleanType,
      'isCustom': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCategories() {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    return categories.orderBy('name').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCategoriesByType(String type) {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    return categories
        .where('type', isEqualTo: type.toLowerCase())
        .orderBy('name')
        .snapshots();
  }

  Future<void> updateCategory({
    required String categoryId,
    required String newName,
    required String type,
  }) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    if (newName.trim().isEmpty) {
      throw Exception('Category name cannot be empty');
    }

    final cleanName = newName.trim();
    final cleanType = type.trim().toLowerCase();

    if (cleanType != 'income' && cleanType != 'expense') {
      throw Exception('Category type must be income or expense');
    }

    await categories.doc(categoryId).update({
      'name': cleanName,
      'type': cleanType,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCategory(String categoryId) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    await categories.doc(categoryId).delete();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getCategory(
    String categoryId,
  ) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    return await categories.doc(categoryId).get();
  }

  Future<bool> categoryExists({
    required String name,
    required String type,
  }) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    final result = await categories
        .where('name', isEqualTo: name.trim())
        .where('type', isEqualTo: type.toLowerCase())
        .limit(1)
        .get();

    return result.docs.isNotEmpty;
  }
}
