import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/app.dart';
import 'package:souq_skills/screens/home/home_screen.dart';
import 'package:souq_skills/screens/shell/main_shell.dart';
import 'package:souq_skills/screens/wallet/wallet_screen.dart';
import 'package:souq_skills/services/repository.dart';

import 'support/memory_data_source.dart';

void main() {
  setUp(() {
    Repository.instance
      ..dataSource = MemoryDataSource()
      ..reset();
  });

  Future<void> openPhoneScreen(WidgetTester tester) async {
    await tester.pumpWidget(const SouqSkillsApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
  }

  testWidgets('welcome screen has one way forward', (tester) async {
    await tester.pumpWidget(const SouqSkillsApp());
    await tester.pumpAndSettle();

    expect(find.text('Souq Skills'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('phone number and code are validated', (tester) async {
    await openPhoneScreen(tester);
    await tester.enterText(find.byType(TextField), '123');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid Saudi mobile number'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '501234567');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
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
