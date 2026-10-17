import 'package:flutter_test/flutter_test.dart';

import 'package:souq_skills/main.dart';

void main() {
  testWidgets('welcome screen opens phone verification flow', (tester) async {
    await tester.pumpWidget(const SouqSkillsApp());

    expect(find.text('Trade what you know.'), findsOneWidget);
    await tester.ensureVisible(find.text('Get started'));
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('What’s your number?'), findsOneWidget);
    expect(find.text('Send verification code'), findsOneWidget);
  });

  testWidgets('verification success exposes main navigation destinations', (
    tester,
  ) async {
    await tester.pumpWidget(const SouqSkillsApp());
    await tester.ensureVisible(find.text('Get started'));
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send verification code'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verify code'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start exploring'));
    await tester.tap(find.text('Start exploring'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Post'), findsOneWidget);
    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Wallet'));
    await tester.pumpAndSettle();
    expect(find.text('Skill wallet'), findsOneWidget);
  });
}
