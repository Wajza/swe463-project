import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/app.dart';
import 'package:souq_skills/screens/home/home_screen.dart';
import 'package:souq_skills/services/auth_service.dart';
import 'package:souq_skills/services/listing_service.dart';
import 'package:souq_skills/services/repository.dart';

import 'support/memory_data_source.dart';

void main() {
  final repository = Repository.instance;
  late MemoryDataSource source;

  setUp(() {
    source = MemoryDataSource();
    repository
      ..dataSource = source
      ..reset();
  });

  test('changes are saved and restored after a restart', () async {
    await repository.restore();
    AuthService().signIn();
    ListingService().toggleSaved('l-photo');
    await pumpEventQueue();

    final saved = source.snapshot;
    repository.reset();
    expect(ListingService().byId('l-photo')!.isSaved, isFalse);

    source.snapshot = saved;
    await repository.restore();
    expect(ListingService().byId('l-photo')!.isSaved, isTrue);
    expect(AuthService().isSignedIn, isTrue);
  });

  test('unreadable saved data falls back to the sample data', () async {
    source.snapshot = 'not json';
    await repository.restore();
    expect(repository.isRestored, isTrue);
    expect(repository.listings, isNotEmpty);
  });

  testWidgets('shows a spinner, then the welcome screen', (tester) async {
    await tester.pumpWidget(const SouqSkillsApp());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('a signed-in member skips the welcome screen', (tester) async {
    await repository.restore();
    AuthService().signIn();
    await tester.pumpWidget(const SouqSkillsApp());
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('a failed load explains itself and can be retried', (
    tester,
  ) async {
    source.failReads = true;
    await tester.pumpWidget(const SouqSkillsApp());
    await tester.pumpAndSettle();
    expect(find.text('Could not load your data'), findsOneWidget);

    source.failReads = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets('a failed save warns the member and can be retried', (
    tester,
  ) async {
    await tester.pumpWidget(const SouqSkillsApp());
    await tester.pumpAndSettle();

    source.failWrites = true;
    AuthService().signOut();
    await tester.pumpAndSettle();
    expect(find.text('Your latest changes were not saved.'), findsOneWidget);

    source.failWrites = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Your latest changes were not saved.'), findsNothing);
  });
}
