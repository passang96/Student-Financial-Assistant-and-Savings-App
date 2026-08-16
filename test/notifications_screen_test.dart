import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_financial_assistant/screens/notifications/notifications_screen.dart';

void main() {
  testWidgets('shows all budget and goal notification types', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));

    expect(find.text('Transport budget exceeded'), findsOneWidget);
    expect(find.text('Dining budget is nearly full'), findsOneWidget);
    expect(find.text('Unread (3)'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Emergency fund achieved!'), findsOneWidget);
    expect(find.text('Laptop fund is halfway there'), findsOneWidget);
  });

  testWidgets('can mark every notification as read and filter unread items', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));

    await tester.tap(find.byTooltip('Mark all as read'));
    await tester.pump();
    expect(find.text('Unread (0)'), findsOneWidget);

    await tester.tap(find.text('Unread (0)'));
    await tester.pumpAndSettle();

    expect(find.text('No unread notifications'), findsOneWidget);
    expect(
      find.text('You are up to date with your budgets and savings goals.'),
      findsOneWidget,
    );
  });
}
