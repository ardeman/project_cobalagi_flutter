import 'package:sembast/sembast.dart';

import 'profile.dart';

class ProfileRepository {
  ProfileRepository(this._db);

  final Database _db;
  static final _store = intMapStoreFactory.store('profiles');

  Future<List<Profile>> loadAll() async {
    final records = await _store.find(
      _db,
      finder: Finder(sortOrders: [SortOrder('createdAt')]),
    );
    return [for (final r in records) Profile.fromMap(r.key, r.value)];
  }

  Future<Profile> add({required String nickname, required int avatar}) async {
    final map = {
      'nickname': nickname,
      'avatar': avatar,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
    final id = await _store.add(_db, map);
    return Profile.fromMap(id, map);
  }

  Future<void> delete(int id) => _store.record(id).delete(_db);
}
