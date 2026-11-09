import 'package:souq_skills/services/app_data_source.dart';

class MemoryDataSource implements AppDataSource {
  MemoryDataSource({this.failReads = false, this.failWrites = false});

  bool failReads;
  bool failWrites;
  String? snapshot;

  @override
  Future<String?> read() async {
    if (failReads) throw StateError('read failed');
    return snapshot;
  }

  @override
  Future<void> write(String value) async {
    if (failWrites) throw StateError('write failed');
    snapshot = value;
  }
}
