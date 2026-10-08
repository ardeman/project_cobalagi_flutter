import 'package:flutter/material.dart';
import 'package:cobalagi/core/widgets/centered_scroll_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cobalagi/core/widgets/glass_surface.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/entitlement/entitlement_cubit.dart';
import '../../../core/entitlement/plan.dart';
import '../../../learning/learner_state.dart';
import '../../../learning/progress_report.dart';
import '../../learning/data/curriculum_repository.dart';
import '../../learning/data/parent_placement.dart';
import '../../learning/data/progress_repository.dart';
import '../../learning/view/concepts.dart';
import '../../profiles/cubit/profiles_cubit.dart';
import '../../profiles/view/profile_avatar.dart';
import 'donation_sheet.dart';
import 'placement_dialog.dart';
import 'package:cobalagi/core/widgets/glass_app_bar.dart';

/// One child's progress for a parent. Reached from the parent area, behind the
/// parent gate. The full report is a sponsor feature.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.profileId});

  final int profileId;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

typedef _Loaded = ({
  ParentPlacement placement,
  LearnerState learner,
  ProgressReport report,
});

class _ProgressScreenState extends State<ProgressScreen> {
  late Future<_Loaded> _data = _load();

  /// The Code tab switch as just set, shown before the save completes.
  bool? _code;

  Future<_Loaded> _load() async {
    final progress = context.read<ProgressRepository>();
    final curriculum = await context.read<CurriculumRepository>().load();
    final placement = ParentPlacement(
      progress: progress,
      curriculum: curriculum,
    );
    final learner = await placement.load(widget.profileId);
    final engine = curriculum.engine;
    final report = ProgressReport.build(
      conceptIds: [for (final c in engine.graph.concepts) c.id],
      learner: learner,
      config: engine.config,
      lessons: curriculum.lessonIds,
      attempts: await progress.attemptLog(widget.profileId),
      now: DateTime.now(),
    );
    return (placement: placement, learner: learner, report: report);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = context.watch<ProfilesCubit>().state.byId(widget.profileId);
    final plan = context.watch<EntitlementCubit>().state;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Text(l10n.progressTitle(profile?.nickname ?? '')),
      ),
      body: FutureBuilder(
        future: _data,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (profile == null || data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return CenteredScrollView(
            padding: belowBars(context, const EdgeInsets.all(24)),
            maxWidth: 720,
            centerVertically: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ProfileAvatar(avatar: profile.avatar, size: 56),
                  title: Text(
                    profile.nickname,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text(
                    placementSummary(
                      l10n,
                      data.placement.curriculum,
                      data.learner,
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.flag_rounded),
                    label: Text(l10n.changeStartingIsland),
                    onPressed: () async {
                      await showPlacementDialog(
                        context,
                        profile: profile,
                        placement: data.placement,
                      );
                      setState(() => _data = _load());
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.code_rounded),
                  title: Text(l10n.codeTab),
                  subtitle: Text(l10n.codeTabHint),
                  value: _code ?? data.learner.placement?.readsWords ?? false,
                  onChanged: (on) {
                    setState(() => _code = on);
                    data.placement.setCodeTab(widget.profileId, on: on);
                  },
                ),
                const SizedBox(height: 24),
                if (plan == Plan.full)
                  _Report(report: data.report)
                else
                  const _SponsorOnly(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Report extends StatelessWidget {
  const _Report({required this.report});

  final ProgressReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final headerStyle = Theme.of(context).textTheme.titleMedium;
    final lastPlayed = report.lastPlayed;
    return GlassSurface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.progressThisWeek, style: headerStyle),
          const SizedBox(height: 8),
          _Stats(
            puzzles: report.weekPuzzlesSolved,
            playTime: report.weekPlayTime,
          ),
          const SizedBox(height: 24),
          Text(l10n.progressAllTime, style: headerStyle),
          const SizedBox(height: 8),
          _Stats(puzzles: report.puzzlesSolved, playTime: report.playTime),
          const SizedBox(height: 8),
          Text(
            lastPlayed == null
                ? l10n.progressNotPlayed
                : l10n.progressLastPlayed(
                    DateFormat.yMMMMd(l10n.localeName).format(lastPlayed),
                  ),
          ),
          const SizedBox(height: 32),
          Text(l10n.progressIslands, style: headerStyle),
          for (final concept in report.concepts) _IslandRow(concept: concept),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.puzzles, required this.playTime});

  final int puzzles;
  final Duration playTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final minutes = (playTime.inSeconds / 60).round();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _Stat(
          icon: Icons.extension_rounded,
          text: l10n.progressPuzzles(puzzles),
        ),
        _Stat(icon: Icons.timer_outlined, text: l10n.progressMinutes(minutes)),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon),
    label: Text(text),
    padding: const EdgeInsets.all(8),
  );
}

class _IslandRow extends StatelessWidget {
  const _IslandRow({required this.concept});

  final ConceptReport concept;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final id = concept.conceptId;
    final status = switch (concept.status) {
      ConceptStatus.notStarted => l10n.statusNotStarted,
      ConceptStatus.practising => l10n.statusPractising,
      ConceptStatus.mastered => l10n.statusMastered,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(conceptIcon(id), color: conceptColor(id), size: 40),
      title: Text(conceptName(l10n, id)),
      subtitle: Text(
        '$status · '
        '${l10n.progressLevels(concept.solvedLessons, concept.totalLessons)}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Icon(
              i < concept.stars
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: Colors.amber.shade700,
            ),
        ],
      ),
    );
  }
}

/// What the free plan sees instead of the report: what sponsors get, and the
/// way to donate. Only shown in the parent area.
class _SponsorOnly extends StatelessWidget {
  const _SponsorOnly();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GlassSurface(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.lock_outline_rounded, size: 40),
            const SizedBox(height: 12),
            Text(l10n.progressSponsorOnly, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => showDonationSheet(context),
              child: Text(l10n.supportCobaLagi),
            ),
          ],
        ),
      ),
    );
  }
}
