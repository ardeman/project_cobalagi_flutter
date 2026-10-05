import 'package:sembast/sembast.dart';

class SettingsRepository {
  SettingsRepository(this._db);

  final Database _db;
  static final _store = StoreRef<String, Object?>('settings');
  static const _localeKey = 'locale';
  static const _supporterKey = 'supporter';

  /// Language code chosen in the parent area, or null to follow the device.
  Future<String?> loadLanguageCode() async =>
      await _store.record(_localeKey).get(_db) as String?;

  Future<void> saveLanguageCode(String? code) async {
    final record = _store.record(_localeKey);
    code == null ? await record.delete(_db) : await record.put(_db, code);
  }

  /// Whether a donation was seen before, so the supporter plan is known
  /// offline and at startup.
  Future<bool> loadSupporter() async =>
      await _store.record(_supporterKey).get(_db) as bool? ?? false;

  Future<void> saveSupporter() => _store.record(_supporterKey).put(_db, true);
}
