import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temple_calendar/main.dart';
import 'package:temple_calendar/models/app_state.dart';

void main() {
  testWidgets('通信なしで起動し全タブが描画できる', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const TempleCalendarApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(MainScreen), findsOneWidget);
    final nav = find.byType(BottomNavigationBar);
    expect(nav, findsOneWidget);
    for (var i = 0; i < 4; i++) {
      final bar = tester.widget<BottomNavigationBar>(nav);
      bar.onTap!(i);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'tab $i');
    }
  });
}
