class BudgetModel {
  final String id;
  final String month;
  final double overallAmount;
  final Map<String, double> categoryBudgets;

  const BudgetModel({
    required this.id,
    required this.month,
    required this.overallAmount,
    required this.categoryBudgets,
  });

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'overallAmount': overallAmount,
      'categoryBudgets': categoryBudgets,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map, String documentId) {
    final rawCategories = map['categoryBudgets'] as Map<String, dynamic>? ?? {};

    return BudgetModel(
      id: documentId,
      month: map['month'] as String? ?? documentId,
      overallAmount: (map['overallAmount'] as num?)?.toDouble() ?? 0,
      categoryBudgets: rawCategories.map(
        (category, amount) =>
            MapEntry(category, (amount as num?)?.toDouble() ?? 0),
      ),
    );
  }
}
