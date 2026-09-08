import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

class GoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Get currently logged-in user's Firebase UID
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  // Reference to current user's savings goals collection
  CollectionReference<Map<String, dynamic>> get goals {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    return _firestore.collection('users').doc(uid).collection('savingsGoals');
  }

  // STEP 23 - CREATE A SAVINGS GOAL

  Future<void> createGoal({
    required String name,
    required double targetAmount,
    required DateTime targetDate,
  }) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    if (name.trim().isEmpty) {
      throw Exception('Goal name cannot be empty');
    }

    if (targetAmount <= 0) {
      throw Exception('Target amount must be greater than 0');
    }

    final goal = await goals.add({
      'name': name.trim(),
      'targetAmount': targetAmount,
      'currentAmount': 0.0,
      'targetDate': Timestamp.fromDate(targetDate),

      // Automatic values when goal is first created
      'progress': 0.0,
      'remainingAmount': targetAmount,
      'achieved': false,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _notificationService.savingsRecommendation(
      goalId: goal.id,
      goalName: name.trim(),
      amount: targetAmount,
    );
  }

  // READ ALL SAVINGS GOALS

  Stream<QuerySnapshot<Map<String, dynamic>>> getGoals() {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    return goals.orderBy('createdAt', descending: true).snapshots();
  }

  // READ ONE SAVINGS GOAL

  Future<DocumentSnapshot<Map<String, dynamic>>> getGoal(String goalId) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    return await goals.doc(goalId).get();
  }

  // EDIT / UPDATE SAVINGS GOAL

  Future<void> updateGoal({
    required String goalId,
    required String name,
    required double targetAmount,
    required DateTime targetDate,
  }) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    if (name.trim().isEmpty) {
      throw Exception('Goal name cannot be empty');
    }

    if (targetAmount <= 0) {
      throw Exception('Target amount must be greater than 0');
    }

    final goalRef = goals.doc(goalId);

    final snapshot = await goalRef.get();

    if (!snapshot.exists) {
      throw Exception('Goal not found');
    }

    final data = snapshot.data();

    if (data == null) {
      throw Exception('Goal data not found');
    }

    final double currentAmount =
        (data['currentAmount'] as num?)?.toDouble() ?? 0.0;

    // Recalculate progress if target changes
    double progress = (currentAmount / targetAmount) * 100;

    // Do not show progress above 100%
    if (progress > 100) {
      progress = 100;
    }

    // Calculate remaining amount
    double remainingAmount = targetAmount - currentAmount;

    if (remainingAmount < 0) {
      remainingAmount = 0;
    }

    // Check Goal Achieved
    final bool achieved = currentAmount >= targetAmount;

    await goalRef.update({
      'name': name.trim(),
      'targetAmount': targetAmount,
      'targetDate': Timestamp.fromDate(targetDate),
      'progress': progress,
      'remainingAmount': remainingAmount,
      'achieved': achieved,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _notificationService.savingsRecommendation(
      goalId: goalId,
      goalName: name.trim(),
      amount: (targetAmount - currentAmount).clamp(0, double.infinity),
    );
    await _notificationService.checkGoalProgress(
      goalId: goalId,
      goalName: name.trim(),
      currentAmount: currentAmount,
      targetAmount: targetAmount,
    );
  }

  // DELETE SAVINGS GOAL

  Future<void> deleteGoal(String goalId) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    await goals.doc(goalId).delete();
  }

  // ADD CONTRIBUTION

  Future<void> addContribution({
    required String goalId,
    required double contribution,
  }) async {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    if (contribution <= 0) {
      throw Exception('Contribution must be greater than 0');
    }

    final goalRef = goals.doc(goalId);

    // Use a Firestore transaction so two updates do not
    // accidentally overwrite each other.
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(goalRef);

      if (!snapshot.exists) {
        throw Exception('Goal not found');
      }

      final data = snapshot.data();

      if (data == null) {
        throw Exception('Goal data not found');
      }

      final double currentAmount =
          (data['currentAmount'] as num?)?.toDouble() ?? 0.0;

      final double targetAmount =
          (data['targetAmount'] as num?)?.toDouble() ?? 0.0;

      if (targetAmount <= 0) {
        throw Exception('Invalid target amount');
      }

      // Add contribution
      final double newAmount = currentAmount + contribution;

      // AUTOMATIC PROGRESS

      double progress = (newAmount / targetAmount) * 100;

      if (progress > 100) {
        progress = 100;
      }

      // AUTOMATIC REMAINING AMOUNT

      double remainingAmount = targetAmount - newAmount;

      if (remainingAmount < 0) {
        remainingAmount = 0;
      }

      // AUTOMATIC GOAL ACHIEVED

      final bool achieved = newAmount >= targetAmount;

      transaction.update(goalRef, {
        'currentAmount': newAmount,
        'progress': progress,
        'remainingAmount': remainingAmount,
        'achieved': achieved,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    // Save contribution history
    await goalRef.collection('contributions').add({
      'amount': contribution,
      'date': FieldValue.serverTimestamp(),
    });

    final updatedGoal = await goalRef.get();
    final updatedData = updatedGoal.data();
    final goalName = updatedData?['name'] as String? ?? 'your goal';
    final targetAmount =
        (updatedData?['targetAmount'] as num?)?.toDouble() ?? 0;
    final currentAmount =
        (updatedData?['currentAmount'] as num?)?.toDouble() ?? 0;

    await _notificationService.checkGoalProgress(
      goalId: goalId,
      goalName: goalName,
      currentAmount: currentAmount,
      targetAmount: targetAmount,
    );
    await _notificationService.savingsRecommendation(
      goalId: goalId,
      goalName: goalName,
      amount: (targetAmount - currentAmount).clamp(0, double.infinity),
    );
  }

  // GET CONTRIBUTION HISTORY

  Stream<QuerySnapshot<Map<String, dynamic>>> getContributions(String goalId) {
    if (uid == null) {
      throw Exception('User not logged in');
    }

    return goals
        .doc(goalId)
        .collection('contributions')
        .orderBy('date', descending: true)
        .snapshots();
  }

  // CALCULATE PROGRESS

  double calculateProgress({
    required double currentAmount,
    required double targetAmount,
  }) {
    if (targetAmount <= 0) {
      return 0;
    }

    double progress = (currentAmount / targetAmount) * 100;

    if (progress > 100) {
      progress = 100;
    }

    return progress;
  }

  // CALCULATE REMAINING

  double calculateRemaining({
    required double currentAmount,
    required double targetAmount,
  }) {
    final double remaining = targetAmount - currentAmount;

    if (remaining < 0) {
      return 0;
    }

    return remaining;
  }

  // CHECK GOAL ACHIEVED

  bool isGoalAchieved({
    required double currentAmount,
    required double targetAmount,
  }) {
    return currentAmount >= targetAmount;
  }
}
