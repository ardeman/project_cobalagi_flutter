import 'package:sembast/sembast.dart';

import '../../../learning/exercise_result.dart';
import '../../../learning/learner_state.dart';

/// Per-profile learning state plus a log of every finished exercise.
class ProgressRepository {
  ProgressRepository(this._db);

  final Database _db;
  static final _learners = intMapStoreFactory.store('learners');
  static final _attempts = intMapStoreFactory.store('attempts');

  Future<LearnerState?> load(int profileId) async {
    final json = await _learners.record(profileId).get(_db);
    return json == null ? null : LearnerState.fromJson(json);
  }

  Future<void> save(int profileId, LearnerState state) =>
      _learners.record(profileId).put(_db, state.toJson());

  Future<void> logAttempt(int profileId, ExerciseResult result) =>
      _attempts.add(_db, {
        'profile': profileId,
        'at': DateTime.now().millisecondsSinceEpoch,
        ...result.toJson(),
      });

  Future<List<ExerciseResult>> attempts(int profileId) async {
    final records = await _attempts.find(
      _db,
      finder: Finder(
        filter: Filter.equals('profile', profileId),
        sortOrders: [SortOrder('at')],
      ),
    );
    return [for (final r in records) ExerciseResult.fromJson(r.value)];
  }

  /// Removes all progress of a deleted profile.
  Future<void> deleteFor(int profileId) => _db.transaction((txn) async {
    await _learners.record(profileId).delete(txn);
    await _attempts.delete(
      txn,
      finder: Finder(filter: Filter.equals('profile', profileId)),
    );
  });
}
