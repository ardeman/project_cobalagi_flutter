import 'package:cobalagi/core/entitlement/plan.dart';
import 'package:cobalagi/features/profiles/cubit/profiles_cubit.dart';
import 'package:cobalagi/features/profiles/data/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  late ProfilesCubit cubit;

  setUp(() async {
    final db = await newDatabaseFactoryMemory().openDatabase('test.db');
    cubit = ProfilesCubit(ProfileRepository(db));
    await cubit.load();
  });

  tearDown(() => cubit.close());

  test('free plan allows exactly one profile', () async {
    final max = Plan.free.maxProfiles;
    expect(
      await cubit.add(nickname: 'Ayu', avatar: 0, maxProfiles: max),
      isNotNull,
    );
    expect(
      await cubit.add(nickname: 'Budi', avatar: 1, maxProfiles: max),
      isNull,
    );
    expect(cubit.state.profiles.map((p) => p.nickname), ['Ayu']);
  });

  test('full plan allows several profiles, persisted in order', () async {
    final max = Plan.full.maxProfiles;
    await cubit.add(nickname: 'Ayu', avatar: 0, maxProfiles: max);
    await cubit.add(nickname: 'Budi', avatar: 1, maxProfiles: max);
    await cubit.load();
    expect(cubit.state.profiles.map((p) => p.nickname), ['Ayu', 'Budi']);
  });

  test('delete removes the profile', () async {
    final p = await cubit.add(nickname: 'Ayu', avatar: 0, maxProfiles: 1);
    await cubit.delete(p!.id);
    await cubit.load();
    expect(cubit.state.profiles, isEmpty);
  });

  test('a player can be renamed and given another avatar later', () async {
    final p = await cubit.add(nickname: 'Ayu', avatar: 0, maxProfiles: 1);
    await cubit.edit(p!.id, nickname: 'Ayu Rocket', avatar: 4);
    expect(cubit.state.profiles.single.nickname, 'Ayu Rocket');
    await cubit.load();
    final saved = cubit.state.profiles.single;
    expect((saved.id, saved.nickname, saved.avatar), (p.id, 'Ayu Rocket', 4));
    expect(saved.createdAt, p.createdAt);
  });
}
