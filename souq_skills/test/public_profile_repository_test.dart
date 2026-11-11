import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/models/user.dart';

const _maha = 'uid-maha';
const _sami = 'uid-sami';

const _profile = User(
  id: User.currentUserId,
  firstName: 'Maha',
  lastName: 'Alzahrani',
  username: 'maha_z',
  city: 'Jeddah',
  bio: 'Teaches calligraphy.',
  phone: '512345678',
  isVerified: false,
  skillsOffered: ['Arabic calligraphy'],
  skillsWanted: ['Piano'],
  availability: 'Weekends',
);

const _publicKeys = {
  'uid',
  'firstName',
  'lastName',
  'username',
  'city',
  'bio',
  'skillsOffered',
  'skillsWanted',
  'availability',
  'isVerified',
  'profileVisible',
};

void main() {
  group('ProfileDocument.toPublicData', () {
    test('shares only public fields, never the phone', () {
      final data = ProfileDocument.toPublicData(
        _maha,
        _profile,
        const ProfileVisibility(),
        isVerified: true,
      );

      expect(data.keys.toSet(), _publicKeys);
      expect(data.values, isNot(contains('512345678')));
      expect(data['uid'], _maha);
      expect(data['city'], 'Jeddah');
      expect(data['skillsWanted'], ['Piano']);
    });

    test('a hidden profile shares only names and username', () {
      final data = ProfileDocument.toPublicData(
        _maha,
        _profile,
        const ProfileVisibility(showProfile: false),
        isVerified: true,
      );

      expect(data['firstName'], 'Maha');
      expect(data['lastName'], 'Alzahrani');
      expect(data['username'], 'maha_z');
      expect(data['city'], '');
      expect(data['bio'], '');
      expect(data['skillsOffered'], isEmpty);
      expect(data['skillsWanted'], isEmpty);
      expect(data['availability'], '');
    });

    test('a private location leaves only the city out', () {
      final data = ProfileDocument.toPublicData(
        _maha,
        _profile,
        const ProfileVisibility(showLocation: false),
        isVerified: true,
      );

      expect(data['city'], '');
      expect(data['bio'], 'Teaches calligraphy.');
    });

    test('verified comes from how the account signed in, not the profile', () {
      Map<String, dynamic> publish({
        required bool isVerified,
        required User of,
      }) => ProfileDocument.toPublicData(
        _maha,
        of,
        const ProfileVisibility(),
        isVerified: isVerified,
      );

      expect(publish(isVerified: true, of: _profile)['isVerified'], isTrue);
      expect(
        publish(
          isVerified: false,
          of: _profile.copyWith(isVerified: true),
        )['isVerified'],
        isFalse,
      );
    });
  });

  group('ProfileDocument.fromPublicData', () {
    test('reads another member by uid, with no phone', () {
      final member = ProfileDocument.fromPublicData(
        _maha,
        ProfileDocument.toPublicData(
          _maha,
          _profile,
          const ProfileVisibility(),
          isVerified: true,
        ),
      );

      expect(member.id, _maha);
      expect(member.id, isNot(User.currentUserId));
      expect(member.phone, '');
      expect(member.name, 'Maha Alzahrani');
      expect(member.skillsOffered, ['Arabic calligraphy']);
      expect(member.isVerified, isTrue);
    });

    test('reads older or partial records safely', () {
      final member = ProfileDocument.fromPublicData(_maha, {
        'firstName': 'Maha',
        'skillsOffered': ['Figma', 7],
        'isVerified': 'yes',
        'phone': '512345678',
      });

      expect(member.firstName, 'Maha');
      expect(member.lastName, '');
      expect(member.skillsOffered, ['Figma']);
      expect(member.isVerified, isFalse);
      expect(member.phone, '');
    });
  });

  group('DemoProfileRepository public profiles', () {
    test('saving publishes, and fetching finds it', () async {
      final profiles = DemoProfileRepository();

      await profiles.saveProfile(_maha, _profile);

      expect(profiles.publicDataOf(_maha)!.keys.toSet(), _publicKeys);
      final found = await profiles.fetchPublicProfiles([_maha, _sami]);
      expect(found.keys, [_maha]);
      expect(found[_maha]!.username, 'maha_z');
    });

    test('saving follows the visibility it is given', () async {
      final profiles = DemoProfileRepository();

      await profiles.saveProfile(
        _maha,
        _profile,
        visibility: const ProfileVisibility(showProfile: false),
      );

      expect(profiles.publicDataOf(_maha)!['bio'], '');
      expect((await profiles.fetchProfile(_maha))!.bio, 'Teaches calligraphy.');
    });

    test('a refused username publishes nothing', () async {
      final profiles = DemoProfileRepository(claims: {'maha_z': _sami});

      await expectLater(
        profiles.saveProfile(_maha, _profile),
        throwsA(same(ProfileException.usernameTaken)),
      );

      expect(profiles.publicDataOf(_maha), isNull);
    });

    test('deleting removes the public profile with the rest', () async {
      final profiles = DemoProfileRepository();
      await profiles.saveProfile(_maha, _profile);

      await profiles.deleteProfile(_maha);

      expect(profiles.publicDataOf(_maha), isNull);
      expect(await profiles.fetchPublicProfiles([_maha]), isEmpty);
    });

    test(
      'accounts from before public profiles have none until saved',
      () async {
        final profiles = DemoProfileRepository(profiles: {_maha: _profile});

        expect(profiles.publicDataOf(_maha), isNull);
        await profiles.saveProfile(_maha, _profile);
        expect(profiles.publicDataOf(_maha), isNotNull);
      },
    );
  });
}
