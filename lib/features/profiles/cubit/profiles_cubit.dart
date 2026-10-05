import 'package:flutter_bloc/flutter_bloc.dart';

import '../../learning/data/progress_repository.dart';
import '../data/profile.dart';
import '../data/profile_repository.dart';

class ProfilesState {
  const ProfilesState({this.profiles = const [], this.loaded = false});

  final List<Profile> profiles;
  final bool loaded;

  Profile? byId(int id) {
    for (final p in profiles) {
      if (p.id == id) return p;
    }
    return null;
  }
}

class ProfilesCubit extends Cubit<ProfilesState> {
  ProfilesCubit(this._repository, {ProgressRepository? progress})
    : _progress = progress,
      super(const ProfilesState());

  final ProfileRepository _repository;
  final ProgressRepository? _progress;

  Future<void> load() async =>
      emit(ProfilesState(profiles: await _repository.loadAll(), loaded: true));

  /// Returns the new profile, or null when [maxProfiles] is already reached.
  Future<Profile?> add({
    required String nickname,
    required int avatar,
    required int maxProfiles,
  }) async {
    if (state.profiles.length >= maxProfiles) return null;
    final profile = await _repository.add(nickname: nickname, avatar: avatar);
    emit(ProfilesState(profiles: [...state.profiles, profile], loaded: true));
    return profile;
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);
    await _progress?.deleteFor(id);
    emit(
      ProfilesState(
        profiles: [
          for (final p in state.profiles)
            if (p.id != id) p,
        ],
        loaded: true,
      ),
    );
  }
}
