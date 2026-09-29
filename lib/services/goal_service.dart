import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/goal_progress.dart';
import 'notification_service.dart';

class GoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final NotificationService _notificationService = NotificationService();

  String get userId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get goals {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('savingsGoals');
  }

  Future<void> createGoal({
    required String name,
    required double targetAmount,
    required DateTime targetDate,
  }) async {
    _validateGoal(name: name, targetAmount: targetAmount);

    final goal = await goals.add({
      'name': name.trim(),
      'targetAmount': targetAmount,
      'currentAmount': 0.0,
      'targetDate': Timestamp.fromDate(targetDate),
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

  Stream<QuerySnapshot<Map<String, dynamic>>> getGoals() {
    return goals.orderBy('createdAt', descending: true).snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getGoal(String goalId) async {
    if (goalId.trim().isEmpty) {
      throw ArgumentError('Goal ID cannot be empty');
    }

    return goals.doc(goalId).get();
  }

  Future<void> updateGoal({
    required String goalId,
    required String name,
    required double targetAmount,
    required DateTime targetDate,
  }) async {
    if (goalId.trim().isEmpty) {
      throw ArgumentError('Goal ID cannot be empty');
    }

    _validateGoal(name: name, targetAmount: targetAmount);

    final goalRef = goals.doc(goalId);

    final snapshot = await goalRef.get();

    if (!snapshot.exists) {
      throw Exception('Goal not found');
    }

    final data = snapshot.data();

    if (data == null) {
      throw Exception('Goal data not found');
    }

    final currentAmount = (data['currentAmount'] as num?)?.toDouble() ?? 0.0;

    final progress = calculateProgress(
      currentAmount: currentAmount,
      targetAmount: targetAmount,
    );

    final remainingAmount = calculateRemaining(
      currentAmount: currentAmount,
      targetAmount: targetAmount,
    );

    final achieved = isGoalAchieved(
      currentAmount: currentAmount,
      targetAmount: targetAmount,
    );

    await goalRef.update({
      'name': name.trim(),
      'targetAmount': targetAmount,
      'targetDate': Timestamp.fromDate(targetDate),
      'progress': progress,
      'remainingAmount': remainingAmount,
      'achieved': achieved,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!achieved && remainingAmount > 0) {
      await _notificationService.savingsRecommendation(
        goalId: goalId,
        goalName: name.trim(),
        amount: remainingAmount,
      );
    }

    await _notificationService.checkGoalProgress(
      goalId: goalId,
      goalName: name.trim(),
      currentAmount: currentAmount,
      targetAmount: targetAmount,
    );
  }

  Future<void> deleteGoal(String goalId) async {
    if (goalId.trim().isEmpty) {
      throw ArgumentError('Goal ID cannot be empty');
    }

    final goalRef = goals.doc(goalId);

    final contributions = await goalRef.collection('contributions').get();

    if (contributions.docs.isNotEmpty) {
      final batch = _firestore.batch();

      for (final contribution in contributions.docs) {
        batch.delete(contribution.reference);
      }

      await batch.commit();
    }

    await goalRef.delete();
  }

  Future<void> addContribution({
    required String goalId,
    required double contribution,
  }) async {
    if (goalId.trim().isEmpty) {
      throw ArgumentError('Goal ID cannot be empty');
    }

    if (!contribution.isFinite || contribution <= 0) {
      throw ArgumentError('Contribution must be greater than 0');
    }

    final goalRef = goals.doc(goalId);

    final contributionRef = goalRef.collection('contributions').doc();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(goalRef);

      if (!snapshot.exists) {
        throw Exception('Goal not found');
      }

      final data = snapshot.data();

      if (data == null) {
        throw Exception('Goal data not found');
      }

      final currentAmount = (data['currentAmount'] as num?)?.toDouble() ?? 0.0;

      final targetAmount = (data['targetAmount'] as num?)?.toDouble() ?? 0.0;

      if (targetAmount <= 0) {
        throw Exception('Invalid target amount');
      }

      final newAmount = currentAmount + contribution;

      final progress = calculateProgress(
        currentAmount: newAmount,
        targetAmount: targetAmount,
      );

      final remainingAmount = calculateRemaining(
        currentAmount: newAmount,
        targetAmount: targetAmount,
      );

      final achieved = isGoalAchieved(
        currentAmount: newAmount,
        targetAmount: targetAmount,
      );

      transaction.update(goalRef, {
        'currentAmount': newAmount,
        'progress': progress,
        'remainingAmount': remainingAmount,
        'achieved': achieved,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(contributionRef, {
        'amount': contribution,
        'date': FieldValue.serverTimestamp(),
      });
    });

    final updatedGoal = await goalRef.get();

    final data = updatedGoal.data();

    if (data == null) {
      return;
    }

    final goalName = data['name'] as String? ?? 'your goal';

    final targetAmount = (data['targetAmount'] as num?)?.toDouble() ?? 0.0;

    final currentAmount = (data['currentAmount'] as num?)?.toDouble() ?? 0.0;

    final remainingAmount = calculateRemaining(
      currentAmount: currentAmount,
      targetAmount: targetAmount,
    );

    await _notificationService.checkGoalProgress(
      goalId: goalId,
      goalName: goalName,
      currentAmount: currentAmount,
      targetAmount: targetAmount,
    );

    if (remainingAmount > 0) {
      await _notificationService.savingsRecommendation(
        goalId: goalId,
        goalName: goalName,
        amount: remainingAmount,
      );
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getContributions(String goalId) {
    if (goalId.trim().isEmpty) {
      throw ArgumentError('Goal ID cannot be empty');
    }

    return goals
        .doc(goalId)
        .collection('contributions')
        .orderBy('date', descending: true)
        .snapshots();
  }

  double calculateProgress({
    required double currentAmount,
    required double targetAmount,
  }) {
    return GoalProgress.calculateProgress(
      currentAmount: currentAmount,
      targetAmount: targetAmount,
    );
  }

  double calculateRemaining({
    required double currentAmount,
    required double targetAmount,
  }) {
    return GoalProgress.calculateRemaining(
      currentAmount: currentAmount,
      targetAmount: targetAmount,
    );
  }

  bool isGoalAchieved({
    required double currentAmount,
    required double targetAmount,
  }) {
    return GoalProgress.isAchieved(
      currentAmount: currentAmount,
      targetAmount: targetAmount,
    );
  }

  void _validateGoal({required String name, required double targetAmount}) {
    GoalProgress.validate(name: name, targetAmount: targetAmount);
  }
}
