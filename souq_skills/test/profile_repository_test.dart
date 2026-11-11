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

  test('usernames are compared without spaces or case', () {
    expect(ProfileDocument.usernameKey('  Maha_Z '), 'maha_z');
    expect(
      ProfileDocument.usernameKey('MAHA_z'),
      ProfileDocument.usernameKey('maha_Z'),
    );
  });

  // The decision used inside the Firestore transaction.
  group('UsernameChange.plan', () {
    UsernameChange plan({
      String oldUsername = 'maha_z',
      String newUsername = 'maha_z',
      String? newOwner,
      String? oldOwner,
    }) => UsernameChange.plan(
      uid: _uid,
      oldUsername: oldUsername,
      newUsername: newUsername,
      newOwner: newOwner,
      oldOwner: oldOwner,
    );

    test('a free name is claimed', () {
      final change = plan(oldUsername: '', newUsername: 'Maha_Z');
      expect(change.claim, 'maha_z');
      expect(change.release, isNull);
    });

    test('a name held by another account is refused', () {
      expect(
        () => plan(newUsername: 'sami', newOwner: 'other-uid'),
        throwsA(same(ProfileException.usernameTaken)),
      );
    });

    test('keeping the same name changes no claim', () {
      final change = plan(newUsername: 'Maha_Z', newOwner: _uid);
      expect(change.claim, isNull);
      expect(change.release, isNull);
    });

    test('a rename claims the new name and releases the old one', () {
      final change = plan(newUsername: 'maha_2', oldOwner: _uid);
      expect(change.claim, 'maha_2');
      expect(change.release, 'maha_z');
    });

    test('a name held by another account is never released', () {
      final change = plan(newUsername: 'maha_2', oldOwner: 'other-uid');
      expect(change.release, isNull);
    });

    test('an account without a claim claims its current name', () {
      final change = plan();
      expect(change.claim, 'maha_z');
      expect(change.release, isNull);
    });
  });

  group('DemoProfileRepository usernames', () {
    test('a free username can be saved and is claimed', () async {
      final repository = DemoProfileRepository();

      await repository.saveProfile(_uid, _profile);

      expect(repository.ownerOf('maha_z'), _uid);
      expect((await repository.fetchProfile(_uid))!.username, 'maha_z');
    });

    test('a taken username is refused and nothing changes', () async {
      final repository = DemoProfileRepository(
        profiles: {_uid: _profile},
        claims: {'maha_z': _uid, 'sami': 'other-uid'},
      );

      await expectLater(
        repository.saveProfile(_uid, _profile.copyWith(username: 'sami')),
        throwsA(
          isA<ProfileException>().having(
            (error) => error.message,
            'message',
            'That username is already taken',
          ),
        ),
      );

      expect((await repository.fetchProfile(_uid))!.username, 'maha_z');
      expect(repository.ownerOf('maha_z'), _uid);
      expect(repository.ownerOf('sami'), 'other-uid');
    });

    test('a username differing only in case or spaces is taken', () async {
      final repository = DemoProfileRepository(claims: {'maha_z': 'other-uid'});

      for (final duplicate in ['MAHA_Z', 'Maha_z', ' maha_z ']) {
        await expectLater(
          repository.saveProfile(_uid, _profile.copyWith(username: duplicate)),
          throwsA(same(ProfileException.usernameTaken)),
        );
      }
      expect(await repository.fetchProfile(_uid), isNull);
    });

    test('saving with the same username keeps the claim', () async {
      final repository = DemoProfileRepository();
      await repository.saveProfile(_uid, _profile);

      await repository.saveProfile(_uid, _profile.copyWith(bio: 'New bio'));
      await repository.saveProfile(_uid, _profile.copyWith(username: 'Maha_Z'));

      expect(repository.ownerOf('maha_z'), _uid);
      final fetched = (await repository.fetchProfile(_uid))!;
      expect(fetched.username, 'Maha_Z');
    });

    test('a rename moves the claim and keeps other fields', () async {
      final repository = DemoProfileRepository();
      await repository.saveProfile(_uid, _profile);

      await repository.saveProfile(_uid, _profile.copyWith(username: 'maha_2'));

      expect(repository.ownerOf('maha_2'), _uid);
      final fetched = (await repository.fetchProfile(_uid))!;
      expect(fetched.toJson(), _profile.copyWith(username: 'maha_2').toJson());
    });

    test('a released username can be taken by another account', () async {
      final repository = DemoProfileRepository();
      await repository.saveProfile(_uid, _profile);
      await repository.saveProfile(_uid, _profile.copyWith(username: 'maha_2'));

      expect(repository.ownerOf('maha_z'), isNull);
      await repository.saveProfile(
        'other-uid',
        _profile.copyWith(username: 'Maha_Z'),
      );
      expect(repository.ownerOf('maha_z'), 'other-uid');
    });

    test(
      'an account without a claim claims its name on its next save',
      () async {
        // Seeded profiles have no claims, like accounts made before claims.
        final repository = DemoProfileRepository(profiles: {_uid: _profile});
        expect(repository.ownerOf('maha_z'), isNull);

        await repository.saveProfile(_uid, _profile.copyWith(bio: 'Updated'));

        expect(repository.ownerOf('maha_z'), _uid);
        await expectLater(
          repository.saveProfile('other-uid', _profile),
          throwsA(same(ProfileException.usernameTaken)),
        );
      },
    );
  });
}
