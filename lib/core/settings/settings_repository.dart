import 'package:sembast/sembast.dart';

class SettingsRepository {
  SettingsRepository(this._db);

  final Database _db;
  static final _store = StoreRef<String, Object?>('settings');
  static const _localeKey = 'locale';

  /// Language code chosen in the parent area, or null to follow the device.
  Future<String?> loadLanguageCode() async =>
      await _store.record(_localeKey).get(_db) as String?;

  Future<void> saveLanguageCode(String? code) async {
    final record = _store.record(_localeKey);
    code == null ? await record.delete(_db) : await record.put(_db, code);
  }
}
