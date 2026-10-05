import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/voice_clips.dart';
import '../../../core/feedback/cheers.dart';
import '../../../core/responsive/window_class.dart';
import '../../../learning/placement/pretest_question.dart';
import '../../../learning/placement/pretest_session.dart';
import '../../learning/cubit/learning_cubit.dart';
import 'question_views.dart';

/// The voice-led warm-up game that places a child on the map. Every answer
/// gets a varied, positive response, so it never feels like a test.
class PretestScreen extends StatefulWidget {
  const PretestScreen({super.key, required this.profileId});

  final int profileId;

  @override
  State<PretestScreen> createState() => _PretestScreenState();
}

class _PretestScreenState extends State<PretestScreen> {
  late final PretestSession _session = context
      .read<LearningCubit>()
      .startPretest();
  final _cheers = CheerPicker();

  /// Shown briefly after each answer.
  Cheer? _cheer;
  var _saved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  String get _language => Localizations.localeOf(context).languageCode;

  void _speak() {
    if (!mounted) return;
    final question = _session.current;
    final clip = question == null
        ? VoiceClips.pretestDone
        : promptFor(AppLocalizations.of(context), question).$2;
    context.read<AudioService>().playVoice(clip, languageCode: _language);
  }

  Future<void> _answer(int option) async {
    if (_cheer != null) return;
    final right = _session.answer(option);
    final cheer = _cheers.next(
      AppLocalizations.of(context),
      right ? CheerMood.celebrate : CheerMood.encourage,
    );
    setState(() => _cheer = cheer);
    context.read<AudioService>().playVoice(cheer.clip, languageCode: _language);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    if (_session.isFinished && !_saved) {
      _saved = true;
      await context.read<LearningCubit>().completePretest(_session.levels);
    }
    if (!mounted) return;
    setState(() => _cheer = null);
    _speak();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final question = _session.current;
    return Scaffold(
      appBar: AppBar(
        leading: CloseButton(
          onPressed: () => context.go('/child/${widget.profileId}'),
        ),
        title: _Footprints(progress: _session.progress),
      ),
      body: SafeArea(
        child: WindowClassBuilder(
          builder: (context, windowClass) {
            final size = switch (windowClass) {
              WindowClass.compact => 110.0,
              WindowClass.medium => 150.0,
              WindowClass.expanded => 190.0,
            };
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _cheer != null
                      ? _CheerView(
                          key: ValueKey(_cheer),
                          cheer: _cheer!,
                          size: size,
                        )
                      : question == null
                      ? _Done(
                          key: const ValueKey('done'),
                          onGo: () => context.go('/child/${widget.profileId}'),
                        )
                      : Column(
                          key: ValueKey(_session.questionsAsked),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Prompt(
                              text: promptFor(l10n, question).$1,
                              onListen: _speak,
                            ),
                            SizedBox(height: size * 0.2),
                            QuestionView(
                              question: question,
                              size: size,
                              onAnswer: _answer,
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.text, required this.onListen});

  final String text;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton.filled(
        tooltip: AppLocalizations.of(context).listenAgain,
        iconSize: 40,
        onPressed: onListen,
        icon: const Icon(Icons.volume_up_rounded),
      ),
      const SizedBox(width: 16),
      Flexible(
        child: Text(text, style: Theme.of(context).textTheme.headlineMedium),
      ),
    ],
  );
}

/// One footprint per skill, filled as the game goes on.
class _Footprints extends StatelessWidget {
  const _Footprints({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final done = (progress * PretestSkill.values.length).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < PretestSkill.values.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              Icons.pets_rounded,
              size: 32,
              color: i < done
                  ? const Color(0xFFFF7A59)
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
      ],
    );
  }
}

class _CheerView extends StatelessWidget {
  const _CheerView({super.key, required this.cheer, required this.size});

  final Cheer cheer;
  final double size;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CheerBadge(cheer: cheer, size: size),
      Text(cheer.text, style: Theme.of(context).textTheme.displaySmall),
    ],
  );
}

class _Done extends StatelessWidget {
  const _Done({super.key, required this.onGo});

  final VoidCallback onGo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.emoji_events_rounded,
          size: 160,
          color: Color(0xFFFFC83D),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.pretestDone,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: onGo,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(l10n.startAdventure),
        ),
      ],
    );
  }
}
