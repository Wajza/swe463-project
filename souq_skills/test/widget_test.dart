import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/app.dart';
import 'package:souq_skills/screens/home/home_screen.dart';
import 'package:souq_skills/screens/wallet/wallet_screen.dart';

void main() {
  testWidgets('welcome screen opens account flow', (tester) async {
    await tester.pumpWidget(const SouqSkillsApp());

    expect(find.text('Souq Skills'), findsOneWidget);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
  });

  testWidgets('phone verification requires six digits', (tester) async {
    await tester.pumpWidget(const SouqSkillsApp());
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '501234567');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Enter the 6-digit code sent to your phone.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '12345');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid 6-digit code'), findsOneWidget);
  });

  testWidgets('bottom navigation opens main sections', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainShell()));

    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.tap(find.text('Chats'));
    await tester.pumpAndSettle();
    expect(find.text('Chats'), findsWidgets);
    await tester.tap(find.text('Wallet'));
    await tester.pumpAndSettle();
    expect(find.byType(WalletScreen), findsOneWidget);
  });
}
