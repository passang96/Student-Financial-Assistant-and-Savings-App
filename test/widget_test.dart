// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:student_financial_assistant/main.dart';

void main() {
  testWidgets('home screen shows account actions', (WidgetTester tester) async {
    await tester.pumpWidget(const StudentFinanceApp());

    expect(find.text('Welcome to Student Financial Assistant'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Manage Budget'), findsOneWidget);
  });
}
