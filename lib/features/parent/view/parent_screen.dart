import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cobalagi/core/widgets/centered_scroll_view.dart';
import 'package:cobalagi/features/play_time/cubit/break_reminder_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/audio/music_cubit.dart';
import '../../../core/audio/sound_effects_cubit.dart';
import '../../../core/entitlement/entitlement_cubit.dart';
import '../../../core/entitlement/plan.dart';
import 'package:cobalagi/core/settings/app_language.dart';
import '../../../core/settings/hint_arrows_cubit.dart';
import '../../../core/settings/settings_cubit.dart';
import '../../../core/version/app_version_text.dart';
import '../../../learning/learner_state.dart';
import '../../learning/data/curriculum_repository.dart';
import '../../learning/data/parent_placement.dart';
import '../../learning/data/progress_repository.dart';
import '../../profiles/cubit/profiles_cubit.dart';
import '../../profiles/data/profile.dart';
import '../../profiles/view/profile_avatar.dart';
import 'donation_sheet.dart';
import 'placement_dialog.dart';
import 'package:cobalagi/core/widgets/glass_popups.dart';
import 'package:cobalagi/core/widgets/glass_app_bar.dart';

/// Reached only through the parent gate.
class ParentScreen extends StatelessWidget {
  const ParentScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, Profile profile) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showGlassDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.deletePlayerConfirm(profile.nickname)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ProfilesCubit>().delete(profile.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = context.watch<SettingsCubit>().state?.languageCode;
    final plan = context.watch<EntitlementCubit>().state;
    final profiles = context.watch<ProfilesCubit>().state.profiles;
    final headerStyle = Theme.of(context).textTheme.titleMedium;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(title: Text(l10n.parentArea)),
      // Below the Scaffold, so the padding includes the app bar.
      body: Builder(
        builder: (context) => CenteredScrollView(
          padding: belowBars(context, const EdgeInsets.all(24)),
          maxWidth: 720,
          centerVertically: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.language, style: headerStyle),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (code, name) in [
                    (null, l10n.languageSystem),
                    for (final language in AppLanguage.values)
                      (language.code, language.name),
                  ])
                    ChoiceChip(
                      label: Text(name),
                      selected: languageCode == code,
                      onSelected: (_) =>
                          context.read<SettingsCubit>().setLanguageCode(code),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.music_note_rounded),
                title: Text(l10n.soundEffects),
                subtitle: Text(l10n.soundEffectsHint),
                value: context.watch<SoundEffectsCubit>().state,
                onChanged: (on) =>
                    context.read<SoundEffectsCubit>().set(on: on),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.queue_music_rounded),
                title: Text(l10n.music),
                value: context.watch<MusicCubit>().state,
                onChanged: (on) => context.read<MusicCubit>().set(on: on),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.turn_right_rounded),
                title: Text(l10n.hintArrowsFollowRoad),
                subtitle: Text(l10n.hintArrowsFollowRoadHint),
                value: context.watch<HintArrowsCubit>().state,
                onChanged: (on) =>
                    context.read<HintArrowsCubit>().set(followRoad: on),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bedtime_rounded),
                title: Text(l10n.breakReminder),
                subtitle: Text(l10n.breakReminderHint),
              ),
              SegmentedButton<int>(
                segments: [
                  for (final minutes in BreakReminderCubit.choices)
                    ButtonSegment(
                      value: minutes,
                      label: Text(
                        minutes == 0
                            ? l10n.breakOff
                            : l10n.breakMinutes(minutes),
                      ),
                    ),
                ],
                selected: {context.watch<BreakReminderCubit>().state},
                onSelectionChanged: (s) =>
                    context.read<BreakReminderCubit>().set(s.first),
              ),
              const SizedBox(height: 32),
              Text(l10n.plan, style: headerStyle),
              // The button wraps under the plan name on narrow phones.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Text(
                      plan == Plan.free
                          ? l10n.planFree
                          : l10n.planFull(Plan.full.maxProfiles),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    plan == Plan.free
                        ? FilledButton(
                            onPressed: () => showDonationSheet(context),
                            child: Text(l10n.supportCobaLagi),
                          )
                        : const Icon(
                            Icons.favorite_rounded,
                            color: Colors.pink,
                          ),
                  ],
                ),
              ),
              if (kDebugMode)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.debugPlanOverride),
                  value: plan == Plan.full,
                  onChanged: (full) => context
                      .read<EntitlementCubit>()
                      .debugOverride(full ? Plan.full : Plan.free),
                ),
              const SizedBox(height: 32),
              Text(l10n.players, style: headerStyle),
              for (final profile in profiles)
                _PlayerTile(
                  key: ValueKey(profile.id),
                  profile: profile,
                  onDelete: () => _confirmDelete(context, profile),
                ),
              const SizedBox(height: 32),
              const AppVersionText(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A player row: shows where they start; tap for their progress, where the
/// player is edited.
class _PlayerTile extends StatefulWidget {
  const _PlayerTile({super.key, required this.profile, required this.onDelete});

  final Profile profile;
  final VoidCallback onDelete;

  @override
  State<_PlayerTile> createState() => _PlayerTileState();
}

class _PlayerTileState extends State<_PlayerTile> {
  late final Future<Curriculum> _curriculum = context
      .read<CurriculumRepository>()
      .load();
  ParentPlacement? _placement;
  LearnerState? _learner;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final progress = context.read<ProgressRepository>();
    final placement = ParentPlacement(
      progress: progress,
      curriculum: await _curriculum,
    );
    final learner = await placement.load(widget.profile.id);
    if (mounted) {
      setState(() {
        _placement = placement;
        _learner = learner;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final placement = _placement;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ProfileAvatar(avatar: widget.profile.avatar, size: 40),
      title: Text(widget.profile.nickname),
      subtitle: placement == null
          ? null
          : Text(placementSummary(l10n, placement.curriculum, _learner)),
      // The progress screen also changes the start, so refresh on return.
      onTap: () async {
        await context.push('/parent/progress/${widget.profile.id}');
        await _refresh();
      },
      // Editing sits on the progress screen; only Delete stays here.
      trailing: IconButton(
        tooltip: l10n.delete,
        style: IconButton.styleFrom(minimumSize: const Size(64, 64)),
        color: Theme.of(context).colorScheme.error,
        icon: const Icon(Icons.delete_outline),
        onPressed: widget.onDelete,
      ),
    );
  }
}
