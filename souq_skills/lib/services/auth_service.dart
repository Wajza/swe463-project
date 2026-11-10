import 'package:firebase_core/firebase_core.dart';
import 'package:souq_skills/data/auth_repository.dart';
import 'package:souq_skills/models/user.dart';

import 'repository.dart';
import 'seed_data.dart';

export 'package:souq_skills/data/auth_repository.dart' show AuthException;

class AuthService {
  final Repository _repo = Repository.instance;

  static AuthRepository? _auth;

  /// Firebase once it has been initialized, otherwise the offline demo
  /// (as in widget tests). Can be replaced, e.g. with a fake.
  static AuthRepository get repository => _auth ??= Firebase.apps.isEmpty
      ? DemoAuthRepository(isKnownPhone: AuthService().isKnownPhone)
      : FirebaseAuthRepository();
  static set repository(AuthRepository value) => _auth = value;

  /// Signed in on this device and with the sign-in service.
  bool get isSignedIn => _repo.isSignedIn && repository.uid != null;

  /// Whether [phone] belongs to the existing account on this device.
  bool isKnownPhone(String phone) =>
      _repo.hasAccount && _repo.currentUser.phone == phone;

  /// The code to show on the verification screen before the member types.
  String? get suggestedCode => repository.suggestedCode;

  /// Waits for a sign-in saved by an earlier visit.
  Future<void> restoreSession() => repository.restoreSession();

  /// Texts a verification code to [phone] (local format, e.g. 5XXXXXXXX).
  /// Throws an [AuthException] if it cannot be sent.
  Future<void> sendCode(String phone) =>
      repository.sendCode(_international(phone));

  /// Signs in with [code] and returns whether the account already has a
  /// profile. If it does, the member is signed in on this device too;
  /// otherwise they still need to create one. Throws an [AuthException].
  Future<bool> verifyCode(String code) async {
    await repository.verifyCode(code);
    final hasProfile = await repository.hasProfile();
    if (hasProfile) signIn();
    return hasProfile;
  }

  /// Confirms the new number passed to [sendCode] with [code].
  /// Throws an [AuthException].
  Future<void> verifyNewPhone(String code) => repository.verifyNewPhone(code);

  /// Saves the new member's profile for their account, then sets it up on
  /// this device. Throws an [AuthException] and changes nothing on failure.
  Future<void> completeSignUp({
    required String firstName,
    required String lastName,
    required String username,
    required String phone,
    required String city,
    required bool keepLocationPrivate,
  }) async {
    final profile = _newUser(
      firstName: firstName,
      lastName: lastName,
      username: username,
      phone: phone,
      city: city,
    );
    await repository.createProfile(profile.toJson());
    createAccount(
      firstName: firstName,
      lastName: lastName,
      username: username,
      phone: phone,
      city: city,
      keepLocationPrivate: keepLocationPrivate,
    );
  }

  /// Sets up a new account on this device only.
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
        _newUser(
          firstName: firstName,
          lastName: lastName,
          username: username,
          phone: phone,
          city: city,
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

  /// Signs out on this device straight away, then with the sign-in service.
  Future<void> signOut() {
    _setSignedIn(false);
    return repository.signOut();
  }

  /// Deletes the account and its profile. Throws an [AuthException] and
  /// keeps the member signed in if that fails.
  Future<void> deleteAccount() async {
    await repository.deleteAccount();
    _repo.hasAccount = false;
    _setSignedIn(false);
  }

  User _newUser({
    required String firstName,
    required String lastName,
    required String username,
    required String phone,
    required String city,
  }) => User(
    id: User.currentUserId,
    firstName: firstName,
    lastName: lastName,
    username: username,
    phone: phone,
    city: city,
    isVerified: true,
  );

  static String _international(String phone) => '+966$phone';

  void _setSignedIn(bool value) {
    _repo.isSignedIn = value;
    _repo.emitChange();
  }
}
