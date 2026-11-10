import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/models/user.dart';

const _uid = 'firebase-uid-123';

const _profile = User(
  id: User.currentUserId,
  firstName: 'Maha',
  lastName: 'Alzahrani',
  username: 'maha_z',
  city: 'Jeddah',
  bio: 'Teaches calligraphy.',
  phone: '512345678',
  isVerified: true,
  skillsOffered: ['Calligraphy'],
  skillsWanted: ['Flutter', 'Photography'],
  availability: 'Weekends',
);

void main() {
  group('ProfileDocument', () {
    test('stores the account uid as the id', () {
      final data = ProfileDocument.toData(_uid, _profile);

      expect(data['id'], _uid);
      expect(data['firstName'], 'Maha');
      expect(data['skillsWanted'], ['Flutter', 'Photography']);
    });

    test('reads back every field, as the current member', () {
      final user = ProfileDocument.fromData(
        ProfileDocument.toData(_uid, _profile),
      );

      expect(user.id, User.currentUserId);
      expect(user.toJson(), _profile.toJson());
    });

    test('uses empty values for missing fields', () {
      final user = ProfileDocument.fromData({
        'firstName': 'Maha',
        'phone': '512345678',
      });

      expect(user.firstName, 'Maha');
      expect(user.phone, '512345678');
      expect(user.lastName, '');
      expect(user.username, '');
      expect(user.city, '');
      expect(user.bio, '');
      expect(user.availability, '');
      expect(user.isVerified, isFalse);
      expect(user.skillsOffered, isEmpty);
      expect(user.skillsWanted, isEmpty);
    });

    test('ignores fields of the wrong type and extra fields', () {
      final user = ProfileDocument.fromData({
        'firstName': 42,
        'lastName': null,
        'isVerified': 'yes',
        'skillsOffered': ['Figma', 7, null, 'UI design'],
        'skillsWanted': 'Flutter',
        'createdAt': DateTime(2026),
      });

      expect(user.firstName, '');
      expect(user.lastName, '');
      expect(user.isVerified, isFalse);
      expect(user.skillsOffered, ['Figma', 'UI design']);
      expect(user.skillsWanted, isEmpty);
    });

    test('reads an empty record', () {
      final user = ProfileDocument.fromData({});

      expect(user.id, User.currentUserId);
      expect(user.name.trim(), isEmpty);
    });
  });

  group('DemoProfileRepository', () {
    test('has no profile for an unknown account', () async {
      expect(await DemoProfileRepository().fetchProfile(_uid), isNull);
    });

    test('returns a saved profile', () async {
      final repository = DemoProfileRepository();

      await repository.saveProfile(_uid, _profile);
      final fetched = await repository.fetchProfile(_uid);

      expect(fetched!.toJson(), _profile.toJson());
    });

    test('keeps profiles of different accounts apart', () async {
      final repository = DemoProfileRepository(profiles: {_uid: _profile});

      await repository.saveProfile(
        'other-uid',
        _profile.copyWith(firstName: 'Sami'),
      );

      expect((await repository.fetchProfile(_uid))!.firstName, 'Maha');
      expect((await repository.fetchProfile('other-uid'))!.firstName, 'Sami');
    });

    test('a later save replaces the earlier one', () async {
      final repository = DemoProfileRepository(profiles: {_uid: _profile});

      await repository.saveProfile(
        _uid,
        _profile.copyWith(city: 'Riyadh', skillsOffered: []),
      );
      final fetched = (await repository.fetchProfile(_uid))!;

      expect(fetched.city, 'Riyadh');
      expect(fetched.skillsOffered, isEmpty);
      expect(fetched.firstName, 'Maha');
    });
  });
}
