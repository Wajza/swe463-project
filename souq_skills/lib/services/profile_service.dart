import 'package:souq_skills/data/profile_repository.dart';
import 'package:souq_skills/models/app_settings.dart';
import 'package:souq_skills/models/user.dart';

import 'auth_service.dart';
import 'repository.dart';

export 'package:souq_skills/data/profile_repository.dart'
    show ProfileException;

class ProfileService {
  final Repository _repo = Repository.instance;

  User get currentUser => _repo.currentUser;
  AppSettings get settings => _repo.settings;

  void updateProfile(User user) => _repo.updateUser(user);

  /// Saves [user] to the signed-in account's online profile, then shows it
  /// on this device. In the offline demo it is saved on this device only.
  ///
  /// Throws a [ProfileException] and changes nothing if it cannot be saved.
  Future<void> saveProfile(User user) async {
    final profiles = AuthService.profiles;
    if (profiles != null) {
      final uid = AuthService.repository.uid;
      if (uid == null) {
        throw const ProfileException(
          'Your session has expired. Sign in again.',
        );
      }
      await profiles.saveProfile(uid, user);
    }
    _repo.updateUser(user);
  }

  void updateSettings(AppSettings Function(AppSettings current) change) =>
      _repo.updateSettings(change(_repo.settings));

  void addOfferedSkill(String skill) => _updateUser(
    (user) => user.copyWith(skillsOffered: _added(user.skillsOffered, skill)),
  );

  void removeOfferedSkill(String skill) => _updateUser(
    (user) => user.copyWith(skillsOffered: _removed(user.skillsOffered, skill)),
  );

  void addWantedSkill(String skill) => _updateUser(
    (user) => user.copyWith(skillsWanted: _added(user.skillsWanted, skill)),
  );

  void removeWantedSkill(String skill) => _updateUser(
    (user) => user.copyWith(skillsWanted: _removed(user.skillsWanted, skill)),
  );

  void _updateUser(User Function(User current) change) =>
      _repo.updateUser(change(_repo.currentUser));

  List<String> _added(List<String> skills, String skill) =>
      {...skills, skill.trim()}.toList();

  List<String> _removed(List<String> skills, String skill) =>
      skills.where((item) => item != skill).toList();
}
