import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iot_task_manager/main.dart';

void main() {
  testWidgets('App initializes', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SmartTaskManagerApp()));
    expect(find.byType(SmartTaskManagerApp), findsOneWidget);
  });
}
