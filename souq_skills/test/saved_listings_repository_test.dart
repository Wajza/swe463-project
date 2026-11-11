import 'package:flutter_test/flutter_test.dart';
import 'package:souq_skills/data/saved_listings_repository.dart';

const _maha = 'uid-maha';
const _sami = 'uid-sami';

void main() {
  group('DemoSavedListingsRepository', () {
    test('an account starts with nothing saved', () async {
      expect(await DemoSavedListingsRepository().fetchSavedIds(_maha), isEmpty);
    });

    test('saves and unsaves listings', () async {
      final saved = DemoSavedListingsRepository();

      await saved.save(_maha, 'a');
      await saved.save(_maha, 'b');
      expect(await saved.fetchSavedIds(_maha), {'a', 'b'});

      await saved.unsave(_maha, 'a');
      expect(await saved.fetchSavedIds(_maha), {'b'});
    });

    test('saving twice or unsaving something not saved is harmless', () async {
      final saved = DemoSavedListingsRepository();

      await saved.save(_maha, 'a');
      await saved.save(_maha, 'a');
      await saved.unsave(_maha, 'never-saved');
      await saved.unsave(_sami, 'a');

      expect(await saved.fetchSavedIds(_maha), {'a'});
    });

    test('every account has its own saved listings', () async {
      final saved = DemoSavedListingsRepository(
        saved: {
          _maha: {'a'},
        },
      );

      await saved.save(_sami, 'b');
      await saved.unsave(_sami, 'a');

      expect(await saved.fetchSavedIds(_maha), {'a'});
      expect(await saved.fetchSavedIds(_sami), {'b'});
    });

    test('hands out copies, so changes to them are not stored', () async {
      final saved = DemoSavedListingsRepository(
        saved: {
          _maha: {'a'},
        },
      );

      (await saved.fetchSavedIds(_maha)).add('b');

      expect(await saved.fetchSavedIds(_maha), {'a'});
    });
  });
}
