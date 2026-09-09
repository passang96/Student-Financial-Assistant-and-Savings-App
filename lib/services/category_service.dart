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

  /// Renames a category and cascades the new name onto every existing
  /// transaction that used the old name, so Transactions, Budgets, CSV
  /// history and Reports all stay consistent after a rename.
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

    final categoryDoc = await categories.doc(categoryId).get();
    final String? oldName = categoryDoc.data()?['name']?.toString();

    await categories.doc(categoryId).update({
      'name': cleanName,
      'type': cleanType,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (oldName != null && oldName != cleanName) {
      await _renameCategoryOnTransactions(oldName: oldName, newName: cleanName);
    }
  }

  /// Updates every transaction using [oldName] to use [newName] instead.
  /// Firestore batches are capped at 500 writes, so this chunks large
  /// result sets defensively even though most students won't hit the cap.
  Future<void> _renameCategoryOnTransactions({
    required String oldName,
    required String newName,
  }) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    final transactionsRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions');

    final matching = await transactionsRef
        .where('category', isEqualTo: oldName)
        .get();

    if (matching.docs.isEmpty) {
      return;
    }

    const int batchLimit = 450;

    for (var i = 0; i < matching.docs.length; i += batchLimit) {
      final chunk = matching.docs.skip(i).take(batchLimit);
      final batch = _firestore.batch();

      for (final doc in chunk) {
        batch.update(doc.reference, {
          'category': newName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    }
  }

  /// Returns how many transactions currently use [categoryName], so the UI
  /// can warn the user before a delete silently orphans that data.
  Future<int> countTransactionsUsingCategory(String categoryName) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('category', isEqualTo: categoryName)
        .count()
        .get();

    return snapshot.count ?? 0;
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
