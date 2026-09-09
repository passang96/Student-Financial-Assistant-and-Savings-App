class FinancialHealthComponent {
  final String title;
  final int score;
  final int maxScore;
  final String explanation;

  const FinancialHealthComponent({
    required this.title,
    required this.score,
    required this.maxScore,
    required this.explanation,
  });
}

class FinancialHealthResult {
  final int score;
  final String rating;
  final String message;

  final List<FinancialHealthComponent> components;
  final List<String> reasons;
  final List<String> recommendations;

  final int potentialScore;
  final String topRecommendation;

  const FinancialHealthResult({
    required this.score,
    required this.rating,
    required this.message,
    required this.components,
    required this.reasons,
    required this.recommendations,
    required this.potentialScore,
    required this.topRecommendation,
  });
}

class FinancialHealthService {
  FinancialHealthResult calculateHealthScore({
    required double income,
    required double expenses,
    required double monthlyBudget,
    required double currentMonthSavings,
    required int savingsGoalCount,
  }) {
    final List<FinancialHealthComponent> components = [];
    final List<String> reasons = [];
    final List<String> recommendations = [];

    final double netBalance = income - expenses;

    final double availableFunds = netBalance - currentMonthSavings;

    int totalScore = 0;

    // ============================================================
    // 1. CASH FLOW
    // Maximum: 30 points
    // ============================================================

    int cashFlowScore = 0;
    String cashFlowExplanation;

    if (income <= 0) {
      cashFlowExplanation =
          'No income has been recorded for the current period.';

      reasons.add(
        'The app cannot fully evaluate your cash flow until income is recorded.',
      );

      recommendations.add(
        'Record all income sources so the app can calculate your financial position accurately.',
      );
    } else {
      final double expenseRatio = expenses / income;
      final double expensePercentage = expenseRatio * 100;

      if (expenseRatio <= 0.50) {
        cashFlowScore = 30;

        cashFlowExplanation =
            'Expenses are ${expensePercentage.toStringAsFixed(1)}% of your income, which is currently well controlled.';

        reasons.add(
          'Your expenses are less than half of your recorded income.',
        );
      } else if (expenseRatio <= 0.70) {
        cashFlowScore = 26;

        cashFlowExplanation =
            'Expenses are ${expensePercentage.toStringAsFixed(1)}% of your income and remain manageable.';

        reasons.add(
          'Your spending is currently at a manageable level compared with your income.',
        );
      } else if (expenseRatio <= 0.85) {
        cashFlowScore = 20;

        cashFlowExplanation =
            'Expenses are ${expensePercentage.toStringAsFixed(1)}% of your income.';

        reasons.add(
          'A large portion of your income is currently being used for expenses.',
        );

        recommendations.add(
          'Review discretionary spending such as shopping, entertainment, and non-essential purchases.',
        );
      } else if (expenseRatio <= 1.00) {
        cashFlowScore = 10;

        cashFlowExplanation =
            'Expenses are ${expensePercentage.toStringAsFixed(1)}% of your income, leaving limited flexibility.';

        reasons.add('Your expenses are very close to your recorded income.');

        recommendations.add(
          'Reduce non-essential expenses so more income remains available after spending.',
        );
      } else {
        cashFlowScore = 0;

        cashFlowExplanation = 'Expenses are higher than your recorded income.';

        reasons.add('Your recorded expenses currently exceed your income.');

        recommendations.add(
          'Prioritise reducing expenses and review your largest spending categories.',
        );
      }
    }

    components.add(
      FinancialHealthComponent(
        title: 'Cash Flow',
        score: cashFlowScore,
        maxScore: 30,
        explanation: cashFlowExplanation,
      ),
    );

    totalScore += cashFlowScore;

    // ============================================================
    // 2. BUDGET CONTROL
    // Maximum: 25 points
    // ============================================================

    int budgetScore = 0;
    String budgetExplanation;

    if (monthlyBudget <= 0) {
      budgetExplanation = 'No monthly budget has been set.';

      reasons.add(
        'Without a budget, the app cannot compare your spending against a planned limit.',
      );

      recommendations.add(
        'Set a realistic monthly budget so spending can be monitored more effectively.',
      );
    } else {
      final double budgetRatio = expenses / monthlyBudget;

      final double budgetPercentage = budgetRatio * 100;

      if (budgetRatio <= 0.50) {
        budgetScore = 25;

        budgetExplanation =
            'You have used ${budgetPercentage.toStringAsFixed(1)}% of your budget.';

        reasons.add('You are comfortably within your current spending budget.');
      } else if (budgetRatio <= 0.75) {
        budgetScore = 22;

        budgetExplanation =
            'You have used ${budgetPercentage.toStringAsFixed(1)}% of your budget.';

        reasons.add('Your budget usage is currently under control.');
      } else if (budgetRatio <= 0.90) {
        budgetScore = 15;

        budgetExplanation =
            'You have used ${budgetPercentage.toStringAsFixed(1)}% of your budget.';

        reasons.add('You are approaching your spending limit.');

        recommendations.add(
          'Slow down discretionary spending to avoid exceeding your budget.',
        );
      } else if (budgetRatio <= 1.00) {
        budgetScore = 8;

        budgetExplanation =
            'You have used ${budgetPercentage.toStringAsFixed(1)}% of your budget.';

        reasons.add('Most of your monthly budget has already been used.');

        recommendations.add(
          'Limit spending to essential expenses until the next budget period.',
        );
      } else {
        budgetScore = 0;

        budgetExplanation =
            'You have used ${budgetPercentage.toStringAsFixed(1)}% of your budget and exceeded the planned limit.';

        reasons.add('Your current spending is above your planned budget.');

        recommendations.add(
          'Review your largest expense categories and reduce spending where possible.',
        );
      }
    }

    components.add(
      FinancialHealthComponent(
        title: 'Budget Control',
        score: budgetScore,
        maxScore: 25,
        explanation: budgetExplanation,
      ),
    );

    totalScore += budgetScore;

    // ============================================================
    // 3. AVAILABLE FUNDS / FINANCIAL FLEXIBILITY
    // Maximum: 25 points
    //
    // Uses CURRENT-MONTH savings contributions rather than
    // lifetime savings-goal balances.
    // ============================================================

    int availableFundsScore = 0;
    String availableFundsExplanation;

    if (income <= 0) {
      availableFundsExplanation =
          'Available funds cannot be evaluated properly because no income is recorded.';
    } else {
      final double availableRatio = availableFunds / income;

      final double availablePercentage = availableRatio * 100;

      if (availableFunds < 0) {
        availableFundsScore = 0;

        availableFundsExplanation =
            'Your current-month expenses and savings contributions are greater than your recorded income.';

        reasons.add(
          'You currently have negative available funds after this month\'s expenses and savings contributions.',
        );

        recommendations.add(
          'Reduce spending and avoid increasing savings contributions until your available funds return to a positive level.',
        );
      } else if (availableRatio >= 0.30) {
        availableFundsScore = 25;

        availableFundsExplanation =
            '${availablePercentage.toStringAsFixed(1)}% of your income remains available after this month\'s expenses and savings contributions.';

        reasons.add('You have strong financial flexibility remaining.');
      } else if (availableRatio >= 0.20) {
        availableFundsScore = 20;

        availableFundsExplanation =
            '${availablePercentage.toStringAsFixed(1)}% of your income remains available.';

        reasons.add('You still have a healthy amount of available funds.');
      } else if (availableRatio >= 0.10) {
        availableFundsScore = 14;

        availableFundsExplanation =
            '${availablePercentage.toStringAsFixed(1)}% of your income remains available.';

        reasons.add('Your available funds are becoming limited.');

        recommendations.add(
          'Try to keep at least 20% of your income available after expenses and savings when possible.',
        );
      } else if (availableFunds > 0) {
        availableFundsScore = 7;

        availableFundsExplanation =
            'Only ${availablePercentage.toStringAsFixed(1)}% of your income remains available.';

        reasons.add(
          'Only a small amount of money remains available for unexpected costs.',
        );

        recommendations.add(
          'Reduce discretionary expenses or avoid increasing savings contributions until more funds are available.',
        );
      } else {
        availableFundsScore = 3;

        availableFundsExplanation =
            'No additional funds remain available after expenses and savings.';

        reasons.add('You currently have no financial buffer remaining.');

        recommendations.add(
          'Focus on rebuilding a small financial buffer before making additional savings allocations.',
        );
      }
    }

    components.add(
      FinancialHealthComponent(
        title: 'Available Funds',
        score: availableFundsScore,
        maxScore: 25,
        explanation: availableFundsExplanation,
      ),
    );

    totalScore += availableFundsScore;

    // ============================================================
    // 4. SAVINGS BEHAVIOUR
    // Maximum: 15 points
    //
    // Uses savings contributions made during the CURRENT MONTH.
    // ============================================================

    int savingsScore = 0;
    String savingsExplanation;

    if (savingsGoalCount == 0) {
      savingsExplanation = 'You currently have no savings goals.';

      reasons.add('Structured savings goals have not yet been created.');

      recommendations.add(
        'Create at least one realistic savings goal and begin with small regular contributions.',
      );
    } else if (currentMonthSavings <= 0) {
      savingsScore = 3;

      savingsExplanation =
          'Savings goals exist, but no contributions have been recorded this month.';

      reasons.add(
        'You have savings goals but have not contributed to them during the current month.',
      );

      recommendations.add(
        'Consider making a small, affordable contribution toward one of your savings goals.',
      );
    } else if (income <= 0) {
      savingsScore = 3;

      savingsExplanation =
          'Savings contributions were recorded, but no current-month income is available for comparison.';

      reasons.add(
        'The app cannot fully assess your savings rate until income is recorded.',
      );
    } else if (netBalance <= 0) {
      savingsScore = 3;

      savingsExplanation =
          'You contributed to savings this month, but current expenses exceed or fully use your income.';

      reasons.add(
        'Your current spending leaves limited room for sustainable saving.',
      );

      recommendations.add(
        'Stabilise your monthly expenses before increasing savings contributions.',
      );
    } else {
      final double savingsRate = currentMonthSavings / income;

      final double savingsPercentage = savingsRate * 100;

      if (savingsRate >= 0.20) {
        savingsScore = 15;

        savingsExplanation =
            'You saved ${savingsPercentage.toStringAsFixed(1)}% of your recorded income this month.';

        reasons.add(
          'You are currently making strong progress toward your savings goals.',
        );
      } else if (savingsRate >= 0.10) {
        savingsScore = 12;

        savingsExplanation =
            'You saved ${savingsPercentage.toStringAsFixed(1)}% of your recorded income this month.';

        reasons.add('You are maintaining a healthy monthly savings rate.');
      } else if (savingsRate >= 0.05) {
        savingsScore = 8;

        savingsExplanation =
            'You saved ${savingsPercentage.toStringAsFixed(1)}% of your recorded income this month.';

        reasons.add('You are making progress toward your savings goals.');

        recommendations.add(
          'Increase your savings contribution gradually when your budget allows.',
        );
      } else {
        savingsScore = 5;

        savingsExplanation =
            'You saved ${savingsPercentage.toStringAsFixed(1)}% of your recorded income this month.';

        reasons.add('Your current savings rate is relatively small.');

        recommendations.add(
          'Consider making small regular savings contributions when your available funds allow.',
        );
      }
    }

    components.add(
      FinancialHealthComponent(
        title: 'Savings Behaviour',
        score: savingsScore,
        maxScore: 15,
        explanation: savingsExplanation,
      ),
    );

    totalScore += savingsScore;

    // ============================================================
    // 5. FINANCIAL PLANNING
    // Maximum: 5 points
    // ============================================================

    int planningScore = 0;
    String planningExplanation;

    if (monthlyBudget > 0 && savingsGoalCount > 0) {
      planningScore = 5;

      planningExplanation =
          'You are using both a spending budget and savings goals.';

      reasons.add('You are actively using financial planning tools.');
    } else if (monthlyBudget > 0 || savingsGoalCount > 0) {
      planningScore = 3;

      planningExplanation = 'You are using one financial planning tool.';

      recommendations.add(
        'Use both budgeting and savings goals for stronger financial planning.',
      );
    } else {
      planningExplanation =
          'No budgeting or savings planning tools are currently active.';

      recommendations.add(
        'Set a budget and create a savings goal to improve financial planning.',
      );
    }

    components.add(
      FinancialHealthComponent(
        title: 'Financial Planning',
        score: planningScore,
        maxScore: 5,
        explanation: planningExplanation,
      ),
    );

    totalScore += planningScore;

    totalScore = totalScore.clamp(0, 100);

    // ============================================================
    // RATING
    // ============================================================

    String rating;
    String message;

    if (totalScore >= 90) {
      rating = 'Excellent';

      message =
          'Your current financial position looks strong and well balanced.';
    } else if (totalScore >= 75) {
      rating = 'Good';

      message =
          'Your finances look healthy overall, although there are still opportunities to improve.';
    } else if (totalScore >= 60) {
      rating = 'Fair';

      message =
          'Your finances are manageable, but some areas could be strengthened.';
    } else if (totalScore >= 40) {
      rating = 'Needs Attention';

      message =
          'Several areas of your current financial position could be improved.';
    } else {
      rating = 'At Risk';

      message =
          'Your current financial position may be difficult to maintain without changes.';
    }

    // ============================================================
    // TOP RECOMMENDATION
    // ============================================================

    String topRecommendation;

    if (availableFunds < 0) {
      topRecommendation =
          'Restore positive available funds by reducing spending before increasing savings contributions.';
    } else if (income > 0 && availableFunds / income < 0.10) {
      final double desiredAvailable = income * 0.20;

      final double improvementNeeded = desiredAvailable - availableFunds;

      topRecommendation =
          'Try to increase your available funds by about \$${improvementNeeded.clamp(0, double.infinity).toStringAsFixed(2)} to create a stronger financial buffer.';
    } else if (income > 0 && expenses / income > 0.70) {
      final double targetExpenses = income * 0.70;

      final double reduction = expenses - targetExpenses;

      topRecommendation =
          'Reducing expenses by approximately \$${reduction.clamp(0, double.infinity).toStringAsFixed(2)} would bring spending closer to 70% of income.';
    } else if (monthlyBudget > 0 && expenses / monthlyBudget > 0.90) {
      topRecommendation =
          'Focus on staying within your remaining budget and avoid unnecessary spending.';
    } else if (savingsGoalCount == 0) {
      topRecommendation =
          'Create a savings goal and begin with a small, sustainable contribution.';
    } else {
      topRecommendation =
          'Maintain your current habits and continue balancing spending, savings, and available funds.';
    }

    // ============================================================
    // POTENTIAL SCORE
    // ============================================================

    int potentialScore = totalScore;

    if (cashFlowScore < 26) {
      potentialScore += 6;
    }

    if (budgetScore < 22) {
      potentialScore += 5;
    }

    if (availableFundsScore < 20) {
      potentialScore += 6;
    }

    if (savingsScore < 12 && savingsGoalCount > 0) {
      potentialScore += 4;
    }

    if (planningScore < 5) {
      potentialScore += 2;
    }

    potentialScore = potentialScore.clamp(totalScore, 100);

    return FinancialHealthResult(
      score: totalScore,
      rating: rating,
      message: message,
      components: components,
      reasons: reasons,
      recommendations: recommendations,
      potentialScore: potentialScore,
      topRecommendation: topRecommendation,
    );
  }
}
