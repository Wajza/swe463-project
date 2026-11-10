import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which account the data saved on this device belongs to, so a
/// different account never opens someone else's data.
abstract class DeviceAccountStore {
  /// The uid of the account that owns the saved data, or null if unknown.
  Future<String?> read();

  /// Records [uid] as the owner; null forgets the owner.
  Future<void> write(String? uid);
}

class PrefsDeviceAccountStore implements DeviceAccountStore {
  static const _key = 'souq_skills_account_uid';

  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  @override
  Future<void> write(String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = uid == null
        ? await prefs.remove(_key)
        : await prefs.setString(_key, uid);
    if (!saved) throw StateError('The device refused to save the account.');
  }
}

/// Keeps the owner in memory only, e.g. in tests.
class MemoryDeviceAccountStore implements DeviceAccountStore {
  MemoryDeviceAccountStore([this._uid]);

  String? _uid;

  @override
  Future<String?> read() async => _uid;

  @override
  Future<void> write(String? uid) async => _uid = uid;
}
