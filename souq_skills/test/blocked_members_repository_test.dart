import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/data/blocked_members_repository.dart';

const _maha = 'uid-maha';
const _sami = 'uid-sami';
const _lina = 'uid-lina';

void main() {
  group('DemoBlockedMembersRepository', () {
    test('an account starts with nobody blocked', () async {
      expect(
        await DemoBlockedMembersRepository().fetchBlockedIds(_maha),
        isEmpty,
      );
    });

    test('blocks and unblocks members', () async {
      final blocked = DemoBlockedMembersRepository();

      await blocked.block(_maha, _sami);
      await blocked.block(_maha, _lina);
      expect(await blocked.fetchBlockedIds(_maha), {_sami, _lina});

      await blocked.unblock(_maha, _sami);
      expect(await blocked.fetchBlockedIds(_maha), {_lina});
    });

    test(
      'blocking twice or unblocking someone not blocked is harmless',
      () async {
        final blocked = DemoBlockedMembersRepository();

        await blocked.block(_maha, _sami);
        await blocked.block(_maha, _sami);
        await blocked.unblock(_maha, _lina);
        await blocked.unblock(_sami, _maha);

        expect(await blocked.fetchBlockedIds(_maha), {_sami});
      },
    );

    test('nobody can block themselves', () async {
      final blocked = DemoBlockedMembersRepository();

      await expectLater(
        blocked.block(_maha, _maha),
        throwsA(same(BlockingException.cannotBlockYourself)),
      );
      expect(await blocked.fetchBlockedIds(_maha), isEmpty);
    });

    test('every account has its own block list', () async {
      final blocked = DemoBlockedMembersRepository(
        blocked: {
          _maha: {_sami},
        },
      );

      await blocked.block(_sami, _maha);

      expect(await blocked.fetchBlockedIds(_maha), {_sami});
      expect(await blocked.fetchBlockedIds(_sami), {_maha});
    });

    test(
      "removing all of an account's blocks leaves everyone else's",
      () async {
        final blocked = DemoBlockedMembersRepository(
          blocked: {
            _maha: {for (var i = 0; i < 450; i++) 'blocked-$i'},
            _sami: {_maha},
            _lina: {_sami},
          },
        );

        await blocked.unblockAll(_maha);
        await blocked.unblockAll(_maha);

        expect(await blocked.fetchBlockedIds(_maha), isEmpty);
        expect(await blocked.fetchBlockedIds(_sami), {_maha});
        expect(await blocked.fetchBlockedIds(_lina), {_sami});
      },
    );

    test('hands out copies, so changes to them are not stored', () async {
      final blocked = DemoBlockedMembersRepository(
        blocked: {
          _maha: {_sami},
        },
      );

      (await blocked.fetchBlockedIds(_maha)).add(_lina);

      expect(await blocked.fetchBlockedIds(_maha), {_sami});
    });
  });
}
