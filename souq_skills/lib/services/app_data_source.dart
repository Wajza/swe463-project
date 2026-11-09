import 'package:shared_preferences/shared_preferences.dart';

/// Where the app's data is kept between launches.
abstract interface class AppDataSource {
  /// Returns the saved data, or null when nothing has been saved yet.
  Future<String?> read();

  Future<void> write(String snapshot);
}

class LocalDataSource implements AppDataSource {
  static const _key = 'souq_skills_snapshot';

  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  @override
  Future<void> write(String snapshot) async {
    final saved = await (await SharedPreferences.getInstance()).setString(
      _key,
      snapshot,
    );
    if (!saved) throw StateError('The device refused to save the data.');
  }
}
