import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qatra_app/main.dart';

void main() {
  testWidgets('QatraApp smoke test', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: QatraApp(),
      ),
    );

    // Verify that QATRA app renders
    expect(find.text('QATRA'), findsWidgets);
  });
}
