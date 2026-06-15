import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dalem/app/app.dart';
import 'package:dalem/app/router.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DalemApp(initialRoute: AppRouter.signIn),
      ),
    );
    await tester.pump();
    expect(find.byType(DalemApp), findsOneWidget);
  });
}
