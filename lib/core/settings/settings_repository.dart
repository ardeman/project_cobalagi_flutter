import 'package:sembast/sembast.dart';

class SettingsRepository {
  SettingsRepository(this._db);

  final Database _db;
  static final _store = StoreRef<String, Object?>('settings');
  static const _localeKey = 'locale';
  static const _supporterKey = 'supporter';
  static const _effectsKey = 'soundEffects';
  static const _musicKey = 'music';
  static const _breakKey = 'breakMinutes';

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

  /// Whether sound effects play; on unless a parent turned them off.
  Future<bool> loadSoundEffects() async =>
      await _store.record(_effectsKey).get(_db) as bool? ?? true;

  Future<void> saveSoundEffects(bool on) =>
      _store.record(_effectsKey).put(_db, on);

  /// Whether background music plays; on unless a parent turned it off.
  Future<bool> loadMusic() async =>
      await _store.record(_musicKey).get(_db) as bool? ?? true;

  Future<void> saveMusic(bool on) => _store.record(_musicKey).put(_db, on);

  /// Minutes of play before a break reminder; 0 (off) unless a parent set it.
  Future<int> loadBreakMinutes() async =>
      await _store.record(_breakKey).get(_db) as int? ?? 0;

  Future<void> saveBreakMinutes(int minutes) =>
      _store.record(_breakKey).put(_db, minutes);
}
