import 'package:flutter_test/flutter_test.dart';
import 'package:temple_calendar/main.dart';
import 'package:provider/provider.dart';
import 'package:temple_calendar/models/app_state.dart';

void main() {
  testWidgets('Temple Calendar app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const TempleCalendarApp(),
      ),
    );
    expect(find.text('寺院カレンダー'), findsWidgets);
  });
}
