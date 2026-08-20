import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current logged-in user's UID
  String get userId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    return user.uid;
  }

  // Current user's notification collection
  CollectionReference<Map<String, dynamic>> get notifications {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

  // CREATE NOTIFICATION

  Future<void> createNotification({
    required String title,
    required String message,
    required String type,
    String? referenceId,
    String? uniqueKey,
  }) async {
    // Prevent duplicate notifications
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
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': false,
      'referenceId': referenceId,
      'uniqueKey': uniqueKey,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // GET NOTIFICATIONS

  Stream<QuerySnapshot<Map<String, dynamic>>> getNotifications() {
    return notifications.orderBy('createdAt', descending: true).snapshots();
  }

  // MARK NOTIFICATION AS READ

  Future<void> markAsRead(String notificationId) async {
    await notifications.doc(notificationId).update({'isRead': true});
  }

  // MARK NOTIFICATION AS UNREAD

  Future<void> markAsUnread(String notificationId) async {
    await notifications.doc(notificationId).update({'isRead': false});
  }

  // DELETE NOTIFication

  Future<void> deleteNotification(String notificationId) async {
    await notifications.doc(notificationId).delete();
  }

  // MARK ALL AS READ

  Future<void> markAllAsRead() async {
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

  // UNREAD COUNT

  Stream<int> getUnreadCount() {
    return notifications
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // BUDGET WARNING / EXCEEDED

  Future<void> checkBudget({
    required String budgetId,
    required String category,
    required double budgetAmount,
    required double spentAmount,
  }) async {
    if (budgetAmount <= 0) {
      return;
    }

    final percentage = (spentAmount / budgetAmount) * 100;

    final now = DateTime.now();

    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    // Budget exceeded
    if (percentage >= 100) {
      final uniqueKey = 'budget_exceeded_${budgetId}_$monthKey';

      await createNotification(
        title: 'Budget Exceeded',
        message: 'You have reached or exceeded your $category budget.',
        type: 'budget_exceeded',
        referenceId: budgetId,
        uniqueKey: uniqueKey,
      );

      return;
    }

    // Budget warning at 80%
    if (percentage >= 80) {
      final uniqueKey = 'budget_warning_${budgetId}_$monthKey';

      await createNotification(
        title: 'Budget Warning',
        message:
            'You have used ${percentage.toStringAsFixed(0)}% of your $category budget.',
        type: 'budget_warning',
        referenceId: budgetId,
        uniqueKey: uniqueKey,
      );
    }
  }

  // Older/simple budget warning API
  Future<void> budgetWarning({
    required String category,
    required double spent,
    required double budget,
  }) async {
    if (budget <= 0) {
      return;
    }

    final percentage = (spent / budget) * 100;

    final now = DateTime.now();

    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    if (percentage >= 100) {
      await createNotification(
        title: 'Budget Exceeded',
        message: 'You have exceeded your $category budget.',
        type: 'budget_exceeded',
        uniqueKey: 'budget_exceeded_${category}_$monthKey',
      );

      return;
    }

    if (percentage >= 80) {
      await createNotification(
        title: 'Budget Warning',
        message:
            'You have used ${percentage.toStringAsFixed(0)}% of your $category budget.',
        type: 'budget_warning',
        uniqueKey: 'budget_warning_${category}_$monthKey',
      );
    }
  }

  // PROJECTED OVERSPENDING

  Future<void> projectedOverspending({
    required String category,
    required double projectedAmount,
    required double budgetAmount,
  }) async {
    if (budgetAmount <= 0 || projectedAmount <= budgetAmount) {
      return;
    }

    final difference = projectedAmount - budgetAmount;

    final now = DateTime.now();

    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    await createNotification(
      title: 'Possible Overspending',
      message:
          'At your current spending rate, $category may exceed its budget by \$${difference.toStringAsFixed(2)}.',
      type: 'projected_overspending',
      uniqueKey: 'projected_overspending_${category}_$monthKey',
    );
  }

  // SAVINGS RECOMMENDATION

  Future<void> savingsRecommendation({
    required String goalName,
    required double amount,
  }) async {
    if (amount <= 0) {
      return;
    }

    final now = DateTime.now();

    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    await createNotification(
      title: 'Savings Recommendation',
      message:
          'You could potentially save \$${amount.toStringAsFixed(2)} toward $goalName.',
      type: 'savings_recommendation',
      uniqueKey: 'savings_recommendation_${goalName}_$monthKey',
    );
  }

  // GOAL PROGRESS

  Future<void> checkGoalProgress({
    required String goalId,
    required String goalName,
    required double currentAmount,
    required double targetAmount,
  }) async {
    if (targetAmount <= 0) {
      return;
    }

    double progress = (currentAmount / targetAmount) * 100;

    if (progress > 100) {
      progress = 100;
    }

    // Goal achieved
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

    // 75%
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

    // 50%
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

    // 25%
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

  // SIMPLE GOAL COMPLETED NOTIFICATION

  Future<void> goalCompleted({required String goalName}) async {
    await createNotification(
      title: 'Goal Achieved 🎉',
      message: 'Congratulations! You reached your $goalName savings goal.',
      type: 'goal_achieved',
      uniqueKey: 'goal_completed_$goalName',
    );
  }

  // DELETE ALL NOTIFICATIONS

  Future<void> deleteAllNotifications() async {
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
