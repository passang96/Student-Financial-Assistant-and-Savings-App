import 'package:flutter_test/flutter_test.dart';
import 'package:student_financial_assistant/main.dart';

void main() {
  testWidgets('shows a useful message when Firebase cannot start', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MyApp(initializationError: 'Firebase initialization failed'),
    );

    expect(find.text('Firebase is unavailable'), findsOneWidget);
    expect(
      find.text(
        "Check this platform's Firebase configuration and restart the app.",
      ),
      findsOneWidget,
    );
  });
}
