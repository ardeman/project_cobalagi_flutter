import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cobalagi/core/widgets/glass_surface.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/entitlement/entitlement_cubit.dart';
import '../../../core/responsive/window_class.dart';
import '../../parent/view/parent_gate.dart';
import '../cubit/profiles_cubit.dart';
import 'add_profile_dialog.dart';
import 'profile_avatar.dart';
import 'package:cobalagi/core/widgets/glass_app_bar.dart';

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});

  Future<void> _addProfile(BuildContext context, int maxProfiles) async {
    final result = await showAddProfileDialog(context);
    if (result == null || !context.mounted) return;
    final (nickname, avatar) = result;
    await context.read<ProfilesCubit>().add(
      nickname: nickname,
      avatar: avatar,
      maxProfiles: maxProfiles,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<ProfilesCubit>().state;
    final maxProfiles = context.watch<EntitlementCubit>().state.maxProfiles;
    final canAdd = state.profiles.length < maxProfiles;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text(l10n.whoIsPlaying),
        actions: [
          // Labelled, so parents find it and it doesn't look like the lock
          // on a full "new player" tile.
          Tooltip(
            message: l10n.parentArea,
            child: TextButton.icon(
              icon: const Icon(Icons.family_restroom_rounded),
              label: Text(l10n.parentArea),
              onPressed: () async {
                if (await showParentGate(context) && context.mounted) {
                  context.push('/parent');
                }
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: !state.loaded
          ? const Center(child: CircularProgressIndicator())
          : WindowClassBuilder(
              builder: (context, windowClass) {
                final tileSize = switch (windowClass) {
                  WindowClass.compact => 160.0,
                  WindowClass.medium => 200.0,
                  WindowClass.expanded => 240.0,
                };
                return GridView.extent(
                  maxCrossAxisExtent: tileSize,
                  padding: belowBars(context, const EdgeInsets.all(24)),
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  children: [
                    for (final profile in state.profiles)
                      _Tile(
                        label: profile.nickname,
                        onTap: () => context.go('/child/${profile.id}'),
                        child: ProfileAvatar(
                          avatar: profile.avatar,
                          size: tileSize * 0.6,
                        ),
                      ),
                    _Tile(
                      label: l10n.addPlayer,
                      onTap: canAdd
                          ? () => _addProfile(context, maxProfiles)
                          : () => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.playerLimitReached)),
                            ),
                      child: Icon(
                        canAdd ? Icons.add_circle : Icons.lock,
                        size: tileSize * 0.5,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.onTap, required this.child});

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => GlassSurface(
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: FittedBox(child: child)),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
