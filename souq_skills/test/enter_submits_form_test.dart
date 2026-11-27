import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/app.dart';
import 'package:souq_skills/data/auth_repository.dart';
import 'package:souq_skills/screens/home/home_screen.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/member_simulator.dart';
import 'package:souq_skills/services/repository.dart';

import 'support/memory_data_source.dart';

/// The offline sign-in, whose codes can be held on their way.
class _SlowAuth extends DemoAuthRepository {
  _SlowAuth() : super(isKnownPhone: AuthService().isKnownPhone);

  Completer<void>? holdCodes;
  int codesSent = 0;

  @override
  Future<void> sendCode(String phoneNumber) async {
    codesSent++;
    await holdCodes?.future;
    await super.sendCode(phoneNumber);
  }
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

/// Whether the text field labelled [label] has the keyboard focus.
bool _hasFocus(WidgetTester tester, String label) => tester
    .widget<EditableText>(
      find.descendant(of: _field(label), matching: find.byType(EditableText)),
    )
    .focusNode
    .hasFocus;

/// Types [text] into the field labelled [label] and presses its keyboard
/// action key, as Enter does on a hardware keyboard.
Future<void> _typeAndPress(
  WidgetTester tester,
  String label,
  String text,
  TextInputAction action,
) async {
  await tester.enterText(_field(label), text);
  await tester.testTextInput.receiveAction(action);
  await tester.pumpAndSettle();
}

Future<void> _openPhoneScreen(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(800, 3000)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SouqSkillsApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Get started'));
  await tester.pumpAndSettle();
}

/// Signs the demo member in with Enter alone.
Future<void> _signInWithEnter(WidgetTester tester) async {
  await _openPhoneScreen(tester);
  await _typeAndPress(
    tester,
    'Phone number',
    '501234567',
    TextInputAction.done,
  );
  await _typeAndPress(
    tester,
    'Verification code',
    '123456',
    TextInputAction.done,
  );
}

void main() {
  final originalAuth = AuthService.repository;

  setUp(() {
    Repository.instance
      ..dataSource = MemoryDataSource()
      ..reset();
  });

  tearDown(() => AuthService.repository = originalAuth);

  testWidgets('Enter on the phone and code fields signs in, after checks', (
    tester,
  ) async {
    await _openPhoneScreen(tester);

    // The same validation as the Continue button.
    await _typeAndPress(tester, 'Phone number', '123', TextInputAction.done);
    expect(find.text('Enter a valid Saudi mobile number'), findsOneWidget);
    expect(find.text('Verify phone'), findsNothing);

    await _typeAndPress(
      tester,
      'Phone number',
      '501234567',
      TextInputAction.done,
    );
    expect(find.text('Verify phone'), findsOneWidget);

    await _typeAndPress(
      tester,
      'Verification code',
      '12345',
      TextInputAction.done,
    );
    expect(find.text('Enter a valid 6-digit code'), findsOneWidget);

    await _typeAndPress(
      tester,
      'Verification code',
      '123456',
      TextInputAction.done,
    );
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('pressing Enter again while a code is sending sends it once', (
    tester,
  ) async {
    final auth = _SlowAuth();
    AuthService.repository = auth;
    await _openPhoneScreen(tester);
    final sending = auth.holdCodes = Completer<void>();

    await tester.enterText(_field('Phone number'), '501234567');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Sending code…'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(auth.codesSent, 1);
    sending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Verify phone'), findsOneWidget);
    expect(auth.codesSent, 1);
  });

  testWidgets('Enter moves through sign-up and creates the account last', (
    tester,
  ) async {
    await _openPhoneScreen(tester);
    await _typeAndPress(
      tester,
      'Phone number',
      '512345678',
      TextInputAction.done,
    );
    await _typeAndPress(
      tester,
      'Verification code',
      '123456',
      TextInputAction.done,
    );
    expect(find.text('About you'), findsOneWidget);

    await _typeAndPress(tester, 'First name', 'Nora', TextInputAction.next);
    expect(_hasFocus(tester, 'Last name'), isTrue);
    await _typeAndPress(tester, 'Last name', 'Saad', TextInputAction.next);
    expect(_hasFocus(tester, 'Username'), isTrue);
    // Moving on never submits, so nothing was checked yet.
    expect(find.text('About you'), findsOneWidget);

    // The last field submits, with the same validation as the button.
    await _typeAndPress(tester, 'Username', 'x', TextInputAction.done);
    expect(find.text('About you'), findsOneWidget);
    await _typeAndPress(tester, 'Username', 'nora_saad', TextInputAction.done);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(Repository.instance.currentUser.username, 'nora_saad');
  });

  testWidgets('Enter on the last one-line field of Edit profile saves it', (
    tester,
  ) async {
    await _signInWithEnter(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();

    await _typeAndPress(tester, 'First name', 'Reem', TextInputAction.next);
    expect(_hasFocus(tester, 'Last name'), isTrue);
    await _typeAndPress(tester, 'Last name', '', TextInputAction.next);
    await tester.tap(_field('Phone number'));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    // Validation still stops it: the last name is required.
    expect(find.text('Edit profile'), findsOneWidget);
    expect(Repository.instance.currentUser.firstName, isNot('Reem'));

    await _typeAndPress(tester, 'Last name', 'Ali', TextInputAction.next);
    await tester.tap(_field('Phone number'));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Profile updated'), findsOneWidget);
    expect(Repository.instance.currentUser.firstName, 'Reem');
    expect(Repository.instance.currentUser.lastName, 'Ali');
  });

  testWidgets('Enter in the invite sheet invites the member typed', (
    tester,
  ) async {
    await _signInWithEnter(tester);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Group trades'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language exchange club'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Invite'));
    await tester.pumpAndSettle();

    // No member matches: Enter does nothing and the sheet stays open.
    await tester.enterText(find.byType(TextField), 'nobody');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(
      find.text('No member can be invited with that username.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'omar');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(find.text('Invited'), findsOneWidget);

    await tester.pump(MemberSimulator.replyDelay);
    await tester.pumpAndSettle();
  });
}
