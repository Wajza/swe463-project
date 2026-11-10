import 'package:firebase_core/firebase_core.dart';
import 'package:souq_skills/data/auth_repository.dart';
import 'package:souq_skills/data/device_account_store.dart';
import 'package:souq_skills/data/profile_repository.dart';
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

  static ProfileRepository? _profiles;

  /// Where profiles are stored online: Firestore once Firebase has been
  /// initialized. Null in the offline demo, which keeps the profile on this
  /// device only. Can be replaced, e.g. with a fake.
  static ProfileRepository? get profiles =>
      _profiles ??
      (Firebase.apps.isEmpty ? null : _profiles = FirebaseProfileRepository());
  static set profiles(ProfileRepository? value) => _profiles = value;

  static DeviceAccountStore? _deviceAccount;

  /// Which account the data saved on this device belongs to.
  static DeviceAccountStore get deviceAccount => _deviceAccount ??=
      Firebase.apps.isEmpty
      ? MemoryDeviceAccountStore()
      : PrefsDeviceAccountStore();
  static set deviceAccount(DeviceAccountStore? value) => _deviceAccount = value;

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
  /// profile. If it does, it is loaded and the member is signed in on this
  /// device too; otherwise they still need to create one.
  ///
  /// Throws an [AuthException]. If the profile cannot be loaded, the member
  /// is signed out again and the data on this device is left untouched.
  Future<bool> verifyCode(String code) async {
    await repository.verifyCode(code);
    final profiles = AuthService.profiles;
    if (profiles == null) {
      // Offline demo: the profile is the one kept on this device.
      final hasProfile = await repository.hasProfile();
      if (hasProfile) signIn();
      return hasProfile;
    }

    final uid = repository.uid;
    if (uid == null) {
      throw const AuthException('Your session has expired. Sign in again.');
    }
    final User? profile;
    try {
      profile = await profiles.fetchProfile(uid);
    } on ProfileException catch (error) {
      // Never continue half signed in, or with another account's data.
      await _signOutQuietly();
      throw AuthException(error.message);
    }
    if (profile == null) return false;
    await _openAccount(uid, profile);
    signIn();
    return true;
  }

  /// When the app opens signed in, loads that account's profile before Home
  /// is shown. Signs out on this device if the account has no profile.
  ///
  /// Throws a [ProfileException] if the profile cannot be loaded, unless the
  /// data on this device already belongs to that account.
  Future<void> loadSessionProfile() async {
    final profiles = AuthService.profiles;
    final uid = repository.uid;
    if (profiles == null || uid == null || !_repo.isSignedIn) return;
    final User? profile;
    try {
      profile = await profiles.fetchProfile(uid);
    } on ProfileException {
      // Offline, the member can still open their own saved copy.
      if (await _deviceOwner() == uid) return;
      rethrow;
    }
    if (profile == null) {
      _setSignedIn(false);
      return;
    }
    await _openAccount(uid, profile);
  }

  /// Shows [profile] as the current member. Data saved on this device for
  /// another account (or for nobody known) is replaced by a fresh start.
  Future<void> _openAccount(String uid, User profile) async {
    if (await _deviceOwner() == uid) {
      _repo.updateUser(profile);
      return;
    }
    _repo.load(SeedData.newMember(profile));
    _repo.hasAccount = true;
    await _rememberDeviceOwner(uid);
  }

  /// An unreadable owner counts as unknown, which only ever starts fresh.
  Future<String?> _deviceOwner() async {
    try {
      return await deviceAccount.read();
    } catch (_) {
      return null;
    }
  }

  /// If this fails, the next sign-in starts fresh again: data is never
  /// shown to the wrong account.
  Future<void> _rememberDeviceOwner(String? uid) async {
    try {
      await deviceAccount.write(uid);
    } catch (_) {}
  }

  Future<void> _signOutQuietly() async {
    try {
      await repository.signOut();
    } on AuthException {
      // Already failing; the original problem is the one to report.
    }
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
    await _rememberDeviceOwner(repository.uid);
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
    await _rememberDeviceOwner(null);
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
