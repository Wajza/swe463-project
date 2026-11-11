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
  /// follows the member's privacy settings, or [locationVisible] when the
  /// location choice is being changed in the same step. In the offline demo
  /// it is saved on this device only.
  ///
  /// Throws a [ProfileException] and changes nothing if it cannot be saved.
  Future<void> saveProfile(User user, {bool? locationVisible}) async {
    await _saveOnline(user, _settingsWith(locationVisible: locationVisible));
    _repo.updateUser(user);
  }

  void updateSettings(AppSettings Function(AppSettings current) change) =>
      _repo.updateSettings(change(_repo.settings));

  /// Changes what other members see of this profile: online first, then
  /// the setting on this device. Throws a [ProfileException] and changes
  /// nothing if it cannot be saved.
  Future<void> updateVisibility({
    bool? profileVisible,
    bool? locationVisible,
  }) async {
    final settings = _settingsWith(
      profileVisible: profileVisible,
      locationVisible: locationVisible,
    );
    await _saveOnline(_repo.currentUser, settings);
    _repo.updateSettings(settings);
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

  Future<void> _saveOnline(User user, AppSettings settings) async {
    final profiles = AuthService.profiles;
    if (profiles == null) return;
    final uid = AuthService.repository.uid;
    if (uid == null) {
      throw const ProfileException('Your session has expired. Sign in again.');
    }
    await profiles.saveProfile(uid, user, visibility: visibilityOf(settings));
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
