import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitmate/main.dart';

void main() {
  testWidgets('SplitMate app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SplitMateApp(),
      ),
    );
    expect(find.text('SplitMate'), findsOneWidget);
  });
}
