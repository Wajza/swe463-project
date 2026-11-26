import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/models/app_settings.dart';
import 'package:souq_skills/models/user.dart';

import 'auth_service.dart';
import 'repository.dart';

export 'package:souq_skills/data/profile_repository.dart' show ProfileException;

class ProfileService {
  final Repository _repo = Repository.instance;

  User get currentUser => _repo.currentUser;
  AppSettings get settings => _repo.settings;

  void updateProfile(User user) => _repo.updateUser(user);

  /// Saves [user] to the signed-in account's online profile, together with
  /// its public profile, then shows it on this device. The public profile
  /// follows the member's latest privacy choices as saved online, with
  /// only [locationVisible] changed when the location choice is changed in
  /// the same step: an edit never makes a hidden profile public. In the
  /// offline demo it is saved on this device only.
  ///
  /// Throws a [ProfileException] and changes nothing if it cannot be saved,
  /// including when the latest choices cannot be read.
  Future<void> saveProfile(User user, {bool? locationVisible}) async {
    final uid = AuthService.repository.uid;
    final settings = await _saveOnline(user, locationVisible: locationVisible);
    _repo.updateUser(user);
    _useChoices(uid, settings);
  }

  void updateSettings(AppSettings Function(AppSettings current) change) =>
      _repo.updateSettings(change(_repo.settings));

  /// Changes what other members see of this profile: online first, then
  /// the setting on this device. Only the choices given change; the others
  /// stay as last saved online. Throws a [ProfileException] and changes
  /// nothing if it cannot be saved.
  Future<void> updateVisibility({
    bool? profileVisible,
    bool? locationVisible,
  }) async {
    final uid = AuthService.repository.uid;
    final settings = await _saveOnline(
      _repo.currentUser,
      profileVisible: profileVisible,
      locationVisible: locationVisible,
    );
    _useChoices(uid, settings);
  }

  /// Publishes the public profile of an account from before public profiles
  /// existed. Quietly does nothing if it is already published, offline, or
  /// if it fails, so signing in never depends on it.
  Future<void> publishIfMissing() async {
    final profiles = AuthService.profiles;
    final uid = AuthService.repository.uid;
    if (profiles == null || uid == null) return;
    try {
      final published = await profiles.fetchPublicProfiles([uid]);
      if (published.containsKey(uid)) return;
      // Still the same account, with its profile shown on this device.
      if (uid != AuthService.repository.uid) return;
      await profiles.saveProfile(
        uid,
        _repo.currentUser,
        visibility: visibilityOf(_repo.settings),
      );
    } catch (_) {
      // Tried again at the next sign-in or profile save.
    }
  }

  /// What [settings] allow other members to see.
  static ProfileVisibility visibilityOf(AppSettings settings) =>
      ProfileVisibility(
        showProfile: settings.profileVisible,
        showLocation: settings.locationVisible,
      );

  AppSettings _settingsWith({bool? profileVisible, bool? locationVisible}) =>
      _repo.settings.copyWith(
        profileVisible: profileVisible,
        locationVisible: locationVisible,
      );

  /// Saves [user] online and returns the settings it was saved with.
  ///
  /// The sharing choices are the latest saved online, read just before, so
  /// a device whose settings are out of date (changed on another device
  /// since it signed in, or opened offline) never publishes them. Only
  /// [profileVisible] or [locationVisible], when given, are this save's own
  /// change. Accounts with no choices saved online, and the offline demo,
  /// use this device's. If the latest choices cannot be read, nothing is
  /// saved: a [ProfileException] is thrown.
  Future<AppSettings> _saveOnline(
    User user, {
    bool? profileVisible,
    bool? locationVisible,
  }) async {
    final profiles = AuthService.profiles;
    if (profiles == null) {
      return _settingsWith(
        profileVisible: profileVisible,
        locationVisible: locationVisible,
      );
    }
    final uid = AuthService.repository.uid;
    if (uid == null) {
      throw const ProfileException('Your session has expired. Sign in again.');
    }
    final saved = await profiles.fetchVisibility(uid);
    final settings = _repo.settings.copyWith(
      profileVisible: profileVisible ?? saved?.showProfile,
      locationVisible: locationVisible ?? saved?.showLocation,
    );
    await profiles.saveProfile(uid, user, visibility: visibilityOf(settings));
    return settings;
  }

  /// Shows the sharing choices of [settings] on this device once saved,
  /// unless another account has signed in meanwhile. Other settings, such
  /// as dark mode, are left as they are now.
  void _useChoices(String? uid, AppSettings settings) {
    if (uid != AuthService.repository.uid) return;
    final current = _repo.settings;
    if (current.profileVisible == settings.profileVisible &&
        current.locationVisible == settings.locationVisible) {
      return;
    }
    _repo.updateSettings(
      current.copyWith(
        profileVisible: settings.profileVisible,
        locationVisible: settings.locationVisible,
      ),
    );
  }

  // Each skill change is saved like any profile edit: online first, and
  // only then on this device. They throw a [ProfileException] on failure.

  Future<void> addOfferedSkill(String skill) => _saveChange(
    (user) => user.copyWith(skillsOffered: _added(user.skillsOffered, skill)),
  );

  Future<void> removeOfferedSkill(String skill) => _saveChange(
    (user) => user.copyWith(skillsOffered: _removed(user.skillsOffered, skill)),
  );

  Future<void> addWantedSkill(String skill) => _saveChange(
    (user) => user.copyWith(skillsWanted: _added(user.skillsWanted, skill)),
  );

  Future<void> removeWantedSkill(String skill) => _saveChange(
    (user) => user.copyWith(skillsWanted: _removed(user.skillsWanted, skill)),
  );

  /// Applies [change] to the latest profile, so other fields are kept.
  Future<void> _saveChange(User Function(User current) change) =>
      saveProfile(change(_repo.currentUser));

  List<String> _added(List<String> skills, String skill) =>
      {...skills, skill.trim()}.toList();

  List<String> _removed(List<String> skills, String skill) =>
      skills.where((item) => item != skill).toList();
}
