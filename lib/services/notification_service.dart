import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get notifications {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    return _firestore.collection('users').doc(uid).collection('notifications');
  }

  Future<void> createNotification({
    required String title,
    required String message,
    required String type,
    String? referenceId,
    String? uniqueKey,
  }) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    if (uniqueKey != null) {
      final existing = await notifications
          .where('uniqueKey', isEqualTo: uniqueKey)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return;
      }
    }

    await notifications.add({
      'title': title,
      'message': message,
      'type': type,
      'isRead': false,
      'referenceId': referenceId,
      'uniqueKey': uniqueKey,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getNotifications() {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    return notifications.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> markAsRead(String notificationId) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    await notifications.doc(notificationId).update({'isRead': true});
  }

  Future<void> markAsUnread(String notificationId) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    await notifications.doc(notificationId).update({'isRead': false});
  }

  Future<void> deleteNotification(String notificationId) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    await notifications.doc(notificationId).delete();
  }

  Future<void> markAllAsRead() async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    final snapshot = await notifications
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  Stream<int> getUnreadCount() {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    return notifications
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> checkBudget({
    required String budgetId,
    required String category,
    required double budgetAmount,
    required double spentAmount,
  }) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    if (budgetAmount <= 0) {
      return;
    }

    final double percentage = (spentAmount / budgetAmount) * 100;

    final now = DateTime.now();

    final String monthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    if (percentage >= 80 && percentage < 100) {
      final String uniqueKey = 'budget_warning_${budgetId}_$monthKey';

      await createNotification(
        title: 'Budget Warning',
        message:
            'You have used ${percentage.toStringAsFixed(0)}% of your $category budget.',
        type: 'budget_warning',
        referenceId: budgetId,
        uniqueKey: uniqueKey,
      );
    }

    if (spentAmount >= budgetAmount) {
      final String uniqueKey = 'budget_exceeded_${budgetId}_$monthKey';

      await createNotification(
        title: 'Budget Exceeded',
        message: 'You have reached or exceeded your $category budget.',
        type: 'budget_exceeded',
        referenceId: budgetId,
        uniqueKey: uniqueKey,
      );
    }
  }

  Future<void> checkGoalProgress({
    required String goalId,
    required String goalName,
    required double currentAmount,
    required double targetAmount,
  }) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    if (targetAmount <= 0) {
      return;
    }

    double progress = (currentAmount / targetAmount) * 100;

    if (progress > 100) {
      progress = 100;
    }

    if (progress >= 100) {
      await createNotification(
        title: 'Goal Achieved 🎉',
        message: 'Congratulations! You achieved your $goalName savings goal.',
        type: 'goal_achieved',
        referenceId: goalId,
        uniqueKey: 'goal_achieved_$goalId',
      );

      return;
    }

    if (progress >= 75) {
      await createNotification(
        title: 'Goal Progress',
        message: 'You have reached 75% of your $goalName savings goal.',
        type: 'goal_progress',
        referenceId: goalId,
        uniqueKey: 'goal_progress_75_$goalId',
      );

      return;
    }

    if (progress >= 50) {
      await createNotification(
        title: 'Goal Progress',
        message: 'You have reached 50% of your $goalName savings goal.',
        type: 'goal_progress',
        referenceId: goalId,
        uniqueKey: 'goal_progress_50_$goalId',
      );

      return;
    }

    if (progress >= 25) {
      await createNotification(
        title: 'Goal Progress',
        message: 'You have reached 25% of your $goalName savings goal.',
        type: 'goal_progress',
        referenceId: goalId,
        uniqueKey: 'goal_progress_25_$goalId',
      );
    }
  }

  Future<void> deleteAllNotifications() async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    final snapshot = await notifications.get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
