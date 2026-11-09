import 'package:souq_skills/models/app_settings.dart';
import 'package:souq_skills/models/user.dart';

import 'repository.dart';

class ProfileService {
  final Repository _repo = Repository.instance;

  User get currentUser => _repo.currentUser;
  AppSettings get settings => _repo.settings;

  void updateProfile(User user) => _repo.updateUser(user);

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

  void setCity(String city) => _updateUser((user) => user.copyWith(city: city));

  void _updateUser(User Function(User current) change) =>
      _repo.updateUser(change(_repo.currentUser));

  List<String> _added(List<String> skills, String skill) =>
      {...skills, skill.trim()}.toList();

  List<String> _removed(List<String> skills, String skill) =>
      skills.where((item) => item != skill).toList();
}
