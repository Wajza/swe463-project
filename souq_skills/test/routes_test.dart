import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/core/app_router.dart';
import 'package:souq_skills/core/app_routes.dart';
import 'package:souq_skills/core/app_theme.dart';
import 'package:souq_skills/models/otp_request.dart';
import 'package:souq_skills/models/proposal_request.dart';
import 'package:souq_skills/screens/utility/not_found_screen.dart';
import 'package:souq_skills/services/repository.dart';

import 'support/memory_data_source.dart';

const _routeArguments = <String, Object>{
  AppRoutes.otpVerification: OtpRequest(
    phone: '501234567',
    purpose: OtpPurpose.signIn,
  ),
  AppRoutes.createAccountProfile: '501234567',
  AppRoutes.listingDetails: 'l-flutter',
  AppRoutes.listingReviews: 'l-flutter',
  AppRoutes.listingPublished: 'l-yara-ui',
  AppRoutes.editListing: 'l-yara-ui',
  AppRoutes.shareListing: 'l-flutter',
  AppRoutes.memberProfile: 'm-sami',
  AppRoutes.chat: 'm-noura',
  AppRoutes.groupChat: 'g-design',
  AppRoutes.proposalInsideChat: ProposalRequest(memberId: 'm-sami'),
  AppRoutes.proposalDetails: 'p-noura',
  AppRoutes.tradeDetails: 't-sami',
  AppRoutes.scheduleSession: 't-faisal',
  AppRoutes.disputeTrade: 't-sami',
  AppRoutes.rateTrade: 't-lina',
  AppRoutes.groupTradeDetails: 'g-design',
  AppRoutes.editGroupTrade: 'g-language',
  AppRoutes.reportMember: 'm-sami',
  AppRoutes.reportTrade: 't-sami',
  AppRoutes.disputeCaseDetails: 'c-seed',
};

Widget _appAt(ThemeData theme, String route) => MaterialApp(
  theme: theme,
  onGenerateRoute: AppRouter.onGenerateRoute,
  onGenerateInitialRoutes: (_) => [
    AppRouter.onGenerateRoute(
      RouteSettings(name: route, arguments: _routeArguments[route]),
    ),
  ],
);

void main() {
  setUp(() {
    Repository.instance
      ..dataSource = MemoryDataSource()
      ..reset();
  });

  for (final (label, theme) in [
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
  ]) {
    testWidgets('every route renders on a phone in $label theme', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      for (final route in AppRouter.routeNames) {
        await tester.pumpWidget(_appAt(theme, route), duration: Duration.zero);
        await tester.pump();

        expect(tester.takeException(), isNull, reason: route);
        if (route != AppRoutes.notFound) {
          expect(find.byType(NotFoundScreen), findsNothing, reason: route);
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      }
    });
  }

  testWidgets('every screen has at most one main button', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 3000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final route in AppRouter.routeNames) {
      await tester.pumpWidget(_appAt(AppTheme.light(), route));
      await tester.pump();
      expect(
        find.byType(FilledButton).evaluate().length,
        lessThanOrEqualTo(1),
        reason: route,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }
  });

  testWidgets('missing arguments show Not Found instead of crashing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRoutes.tradeDetails,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NotFoundScreen), findsOneWidget);
  });
}
