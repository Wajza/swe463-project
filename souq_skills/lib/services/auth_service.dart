import 'package:souq_skills/core/validators.dart';
import 'package:souq_skills/models/user.dart';

import 'repository.dart';
import 'seed_data.dart';

class AuthService {
  final Repository _repo = Repository.instance;

  bool get hasAccount => _repo.hasAccount;
  bool get isSignedIn => _repo.isSignedIn;

  bool verifyOtp(String code) => AppValidators.otp(code) == null;

  void createAccount({
    required String name,
    required String username,
    required String phone,
    required String city,
  }) {
    _repo.load(
      SeedData.newMember(
        User(
          id: User.currentUserId,
          name: name,
          username: username,
          phone: phone,
          city: city,
          isVerified: true,
        ),
      ),
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
