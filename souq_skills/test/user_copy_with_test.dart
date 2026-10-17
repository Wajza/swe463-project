import 'package:flutter_test/flutter_test.dart';

import '../lib/models/user.dart';

void main() {
  const original = User(name: 'Raghad', initials: 'RA');

  test('verification update preserves profile and original user', () {
    final updated = original.copyWith(isVerified: true);

    expect(updated.name, 'Raghad');
    expect(updated.initials, 'RA');
    expect(updated.isVerified, isTrue);
    expect(original.isVerified, isFalse);
  });

  test('profile update preserves verification', () {
    final verified = original.copyWith(isVerified: true);
    final updated = verified.copyWith(name: 'Sara', initials: 'SA');

    expect(updated.name, 'Sara');
    expect(updated.initials, 'SA');
    expect(updated.isVerified, isTrue);
    expect(verified.name, 'Raghad');
  });

  test('verification can be explicitly removed', () {
    final verified = original.copyWith(isVerified: true);

    expect(verified.copyWith(isVerified: false).isVerified, isFalse);
  });
}
