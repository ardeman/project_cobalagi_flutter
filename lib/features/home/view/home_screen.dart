import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../play/data/level_repository.dart';
import '../../profiles/cubit/profiles_cubit.dart';
import '../../profiles/view/profile_avatar.dart';

/// A child's start screen. Becomes the adventure map in Phase 3; until then it
/// lists the hand-made levels.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.profileId});

  final int profileId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = context.watch<ProfilesCubit>().state.byId(profileId);
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    String levelPath(int index) => '/child/$profileId/level/$index';

    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.go('/'))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              ProfileAvatar(avatar: profile.avatar, size: 140),
              const SizedBox(height: 16),
              Text(
                l10n.greeting(profile.nickname),
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow_rounded, size: 48),
                label: Text(l10n.play),
                onPressed: () => context.go(levelPath(0)),
              ),
              const SizedBox(height: 32),
              Text(l10n.levels, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              FutureBuilder(
                future: context.read<LevelRepository>().loadAll(),
                builder: (context, snapshot) => Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    for (var i = 0; i < (snapshot.data?.length ?? 0); i++)
                      FilledButton.tonal(
                        onPressed: () => context.go(levelPath(i)),
                        child: Text('${i + 1}'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
