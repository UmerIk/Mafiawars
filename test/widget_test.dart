import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_flutter_app/main.dart';
import 'package:my_flutter_app/features/auth/presentation/auth_screen.dart';

void main() {
  testWidgets('MafiaApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MafiaApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.byType(AuthScreen), findsOneWidget);
  });
}
