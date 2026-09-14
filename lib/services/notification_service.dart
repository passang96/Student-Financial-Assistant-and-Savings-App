import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get notifications {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

  static String? budgetNotificationType({
    required double budgetAmount,
    required double spentAmount,
  }) {
    if (budgetAmount <= 0 || spentAmount < 0) {
      return null;
    }

    final percentage = (spentAmount / budgetAmount) * 100;

    if (percentage >= 100) {
      return 'budget_exceeded';
    }

    if (percentage >= 80) {
      return 'budget_warning';
    }

    return null;
  }

  static bool shouldNotifyProjectedOverspending({
    required double projectedAmount,
    required double budgetAmount,
  }) {
    return budgetAmount > 0 && projectedAmount > budgetAmount;
  }

  String _monthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  Future<void> createNotification({
    required String title,
    required String message,
    required String type,
    String? referenceId,
    String? uniqueKey,
  }) async {
    final data = <String, dynamic>{
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': false,
      'referenceId': referenceId,
      'uniqueKey': uniqueKey,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (uniqueKey == null) {
      await notifications.add(data);
      return;
    }

    final documentId = Uri.encodeComponent(uniqueKey);
    final reference = notifications.doc(documentId);

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);

      if (existing.exists) {
        return;
      }

      transaction.set(reference, data);
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getNotifications() {
    return notifications.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> markAsRead(String notificationId) async {
    await notifications.doc(notificationId).update({'isRead': true});
  }

  Future<void> markAsUnread(String notificationId) async {
    await notifications.doc(notificationId).update({'isRead': false});
  }

  Future<void> deleteNotification(String notificationId) async {
    await notifications.doc(notificationId).delete();
  }

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

  Stream<int> getUnreadCount() {
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
    DateTime? month,
  }) async {
    if (budgetAmount <= 0 || spentAmount < 0) {
      return;
    }

    final notificationType = budgetNotificationType(
      budgetAmount: budgetAmount,
      spentAmount: spentAmount,
    );

    final selectedMonth = month ?? DateTime.now();
    final key = _monthKey(selectedMonth);

    if (notificationType == 'budget_exceeded') {
      await createNotification(
        title: 'Budget Exceeded',
        message: 'You have reached or exceeded your $category budget.',
        type: 'budget_exceeded',
        referenceId: budgetId,
        uniqueKey: 'budget_exceeded_${budgetId}_$key',
      );

      return;
    }

    if (notificationType == 'budget_warning') {
      final percentage = (spentAmount / budgetAmount) * 100;

      await createNotification(
        title: 'Budget Warning',
        message:
            'You have used ${percentage.toStringAsFixed(0)}% of your $category budget.',
        type: 'budget_warning',
        referenceId: budgetId,
        uniqueKey: 'budget_warning_${budgetId}_$key',
      );
    }
  }

  Future<void> budgetWarning({
    required String category,
    required double spent,
    required double budget,
    DateTime? month,
  }) async {
    if (budget <= 0 || spent < 0) {
      return;
    }

    final selectedMonth = month ?? DateTime.now();
    final key = _monthKey(selectedMonth);
    final percentage = (spent / budget) * 100;

    if (percentage >= 100) {
      await createNotification(
        title: 'Budget Exceeded',
        message: 'You have exceeded your $category budget.',
        type: 'budget_exceeded',
        uniqueKey: 'budget_exceeded_${category}_$key',
      );

      return;
    }

    if (percentage >= 80) {
      await createNotification(
        title: 'Budget Warning',
        message:
            'You have used ${percentage.toStringAsFixed(0)}% of your $category budget.',
        type: 'budget_warning',
        uniqueKey: 'budget_warning_${category}_$key',
      );
    }
  }

  Future<void> projectedOverspending({
    required String category,
    required double projectedAmount,
    required double budgetAmount,
    DateTime? month,
  }) async {
    if (!shouldNotifyProjectedOverspending(
      projectedAmount: projectedAmount,
      budgetAmount: budgetAmount,
    )) {
      return;
    }

    final difference = projectedAmount - budgetAmount;
    final selectedMonth = month ?? DateTime.now();
    final key = _monthKey(selectedMonth);

    await createNotification(
      title: 'Possible Overspending',
      message:
          'At your current spending rate, $category may exceed its budget by \$${difference.toStringAsFixed(2)}.',
      type: 'projected_overspending',
      uniqueKey: 'projected_overspending_${category}_$key',
    );
  }

  Future<void> savingsRecommendation({
    required String goalId,
    required String goalName,
    required double amount,
  }) async {
    if (amount <= 0 || !amount.isFinite) {
      return;
    }

    final key = _monthKey(DateTime.now());

    await createNotification(
      title: 'Savings Recommendation',
      message:
          'You could potentially save \$${amount.toStringAsFixed(2)} toward $goalName.',
      type: 'savings_recommendation',
      referenceId: goalId,
      uniqueKey: 'savings_recommendation_${goalId}_$key',
    );
  }

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

    if (progress < 0) {
      progress = 0;
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

  Future<void> goalCompleted({required String goalName, String? goalId}) async {
    final key = goalId ?? goalName.trim().toLowerCase().replaceAll(' ', '_');

    await createNotification(
      title: 'Goal Achieved 🎉',
      message: 'Congratulations! You reached your $goalName savings goal.',
      type: 'goal_achieved',
      referenceId: goalId,
      uniqueKey: 'goal_completed_$key',
    );
  }

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
