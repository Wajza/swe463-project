import 'package:souq_skills/models/user.dart';

import 'repository.dart';
import 'seed_data.dart';

class AuthService {
  final Repository _repo = Repository.instance;

  bool get isSignedIn => _repo.isSignedIn;

  /// Whether [phone] belongs to the existing account on this device.
  bool isKnownPhone(String phone) =>
      _repo.hasAccount && _repo.currentUser.phone == phone;

  void createAccount({
    required String firstName,
    required String lastName,
    required String username,
    required String phone,
    required String city,
    required bool keepLocationPrivate,
  }) {
    _repo.load(
      SeedData.newMember(
        User(
          id: User.currentUserId,
          firstName: firstName,
          lastName: lastName,
          username: username,
          phone: phone,
          city: city,
          isVerified: true,
        ),
      ),
    );
    _repo.settings = _repo.settings.copyWith(
      locationVisible: !keepLocationPrivate,
    );
    _repo.hasAccount = true;
    _setSignedIn(true);
  }

  void signIn() => _setSignedIn(true);

  void signOut() => _setSignedIn(false);

  void deleteAccount() {
    _repo.hasAccount = false;
    _setSignedIn(false);
  }

  void _setSignedIn(bool value) {
    _repo.isSignedIn = value;
    _repo.emitChange();
  }
}
