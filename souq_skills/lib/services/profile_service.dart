import '../models/app_settings.dart';
import '../models/user.dart';
import 'repository.dart';

class ProfileService {
  ProfileService({Repository? repository}) : _repository = repository ?? Repository.instance;
  final Repository _repository;
  Future<User> getProfile() async => _repository.currentUser;
  Future<User> updateProfile(User profile) async { _repository.updateUser(profile); return profile; }
  Future<AppSettings> getSettings() async => _repository.settings;
  Future<AppSettings> updateSettings(AppSettings settings) async { _repository.updateSettings(settings); return settings; }
}
