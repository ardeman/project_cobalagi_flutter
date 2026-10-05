import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../profiles/cubit/profiles_cubit.dart';
import '../../profiles/view/profile_avatar.dart';

/// Placeholder start screen for a child; becomes the adventure map in Phase 3.
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

    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.go('/'))),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfileAvatar(avatar: profile.avatar, size: 160),
            const SizedBox(height: 24),
            Text(
              l10n.greeting(profile.nickname),
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow_rounded, size: 48),
              label: Text(l10n.play),
              onPressed: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.comingSoon))),
            ),
          ],
        ),
      ),
    );
  }
}
