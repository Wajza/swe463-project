import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/core/app_router.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/screens/trades/schedule_session_screen.dart';
import 'package:souq_skills/services/repository.dart';

import 'support/memory_data_source.dart';

Widget _tradeDetails(String tradeId) => MaterialApp(
  theme: AppTheme.light(),
  onGenerateRoute: AppRouter.onGenerateRoute,
  onGenerateInitialRoutes: (_) => [
    AppRouter.onGenerateRoute(
      RouteSettings(name: AppRoutes.tradeDetails, arguments: tradeId),
    ),
  ],
);

final _pencil = find.widgetWithIcon(IconButton, Icons.edit_outlined);

void main() {
  setUp(() {
    Repository.instance
      ..dataSource = MemoryDataSource()
      ..reset();
  });

  testWidgets('the session card\'s pencil opens rescheduling', (tester) async {
    // t-sami: accepted, with a session booked.
    await tester.pumpWidget(_tradeDetails('t-sami'));
    await tester.pumpAndSettle();

    expect(_pencil, findsOneWidget);
    expect(find.byTooltip('Reschedule'), findsOneWidget);

    await tester.tap(_pencil);
    await tester.pumpAndSettle();

    expect(find.byType(ScheduleSessionScreen), findsOneWidget);
  });

  testWidgets('the menu has no Reschedule, only its other actions', (
    tester,
  ) async {
    await tester.pumpWidget(_tradeDetails('t-sami'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Reschedule'), findsNothing);
    expect(find.text('Report trade'), findsOneWidget);
    expect(find.text('Open a dispute'), findsOneWidget);
  });

  testWidgets('a completed trade\'s session has no pencil', (tester) async {
    // t-omar: completed, so it can no longer be rescheduled.
    await tester.pumpWidget(_tradeDetails('t-omar'));
    await tester.pumpAndSettle();

    expect(find.text('Session'), findsOneWidget);
    expect(_pencil, findsNothing);
  });
}
