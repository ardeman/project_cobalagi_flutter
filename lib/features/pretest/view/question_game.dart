import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cobalagi/core/widgets/centered_scroll_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/voice_clips.dart';
import '../../../core/feedback/cheers.dart';
import '../../../core/responsive/window_class.dart';
import '../../../learning/placement/pretest_question.dart';
import '../../../learning/placement/question_round.dart';
import 'question_views.dart';
import 'package:cobalagi/core/widgets/glass_app_bar.dart';

/// Plays a [QuestionRound] by voice and pictures: the placement warm-up
/// game and the Warm-up island's games. After each answer the right option
/// lights up green; a wrong tap wobbles in orange and the child hears which
/// answer was right, always with encouraging words.
class QuestionGame extends StatefulWidget {
  const QuestionGame({
    super.key,
    required this.round,
    required this.steps,
    required this.onClose,
    required this.onFinished,
    required this.doneClip,
    required this.done,
  });

  final QuestionRound round;

  /// Footprints in the top bar, filled as [QuestionRound.progress] grows.
  final int steps;
  final VoidCallback onClose;

  /// Saves the result, once, after the last answer.
  final Future<void> Function() onFinished;

  /// Spoken when the round is over.
  final String doneClip;

  /// Shown when the round is over.
  final WidgetBuilder done;

  @override
  State<QuestionGame> createState() => _QuestionGameState();
}

class _QuestionGameState extends State<QuestionGame> {
  QuestionRound get _round => widget.round;
  final _cheers = CheerPicker();

  /// Shown briefly after each answer, over the question just answered.
  ({PretestQuestion question, int chosen, bool right, Cheer cheer})? _feedback;
  var _saved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  String get _language => Localizations.localeOf(context).languageCode;

  void _speak() {
    if (!mounted) return;
    final question = _round.current;
    final clip = question == null
        ? widget.doneClip
        : promptFor(AppLocalizations.of(context), question).$2;
    context.read<AudioService>().playVoice(clip, languageCode: _language);
  }

  Future<void> _answer(int option) async {
    if (_feedback != null) return;
    final question = _round.current!;
    final right = _round.answer(option);
    final cheer = _cheers.next(
      AppLocalizations.of(context),
      right ? CheerMood.celebrate : CheerMood.encourage,
    );
    setState(
      () => _feedback = (
        question: question,
        chosen: option,
        right: right,
        cheer: cheer,
      ),
    );
    final audio = context.read<AudioService>();
    final language = _language;
    Future<void> speak() async {
      await audio.playVoice(cheer.clip, languageCode: language);
      if (!right) {
        await audio.playVoice(
          VoiceClips.pretestAnswerWas,
          languageCode: language,
          queue: true,
        );
      }
      await audio.whenIdle();
    }

    // Move on only after the voice has finished, so the next prompt never
    // cuts it off, and after long enough to see the answer (longer after a
    // wrong tap). The timeout keeps a stuck clip from freezing the game.
    await Future.wait([
      Future<void>.delayed(Duration(milliseconds: right ? 1300 : 2000)),
      speak().timeout(const Duration(seconds: 8), onTimeout: () {}),
    ]);
    if (!mounted) return;
    if (_round.isFinished && !_saved) {
      _saved = true;
      await widget.onFinished();
    }
    if (!mounted) return;
    setState(() => _feedback = null);
    _speak();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final question = _round.current;
    final feedback = _feedback;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        leading: CloseButton(onPressed: widget.onClose),
        title: _Footprints(steps: widget.steps, progress: _round.progress),
      ),
      // The scroll view pads itself, so content passes under the bar.
      body: SafeArea(
        top: false,
        bottom: false,
        child: WindowClassBuilder(
          builder: (context, windowClass) {
            final media = MediaQuery.of(context);
            // Also fit the height, so a phone held sideways shows the
            // answers without scrolling.
            final height = media.size.height - media.padding.vertical - 48;
            final size = min(switch (windowClass) {
              WindowClass.compact => 110.0,
              WindowClass.medium => 150.0,
              WindowClass.expanded => 190.0,
            }, max(80.0, height / 3.4));
            return CenteredScrollView(
              padding: belowBars(context, const EdgeInsets.all(24)),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: feedback != null
                    ? Column(
                        key: ValueKey('feedback-${_round.questionsAsked}'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FeedbackBanner(cheer: feedback.cheer),
                          SizedBox(height: size * 0.2),
                          QuestionView(
                            question: feedback.question,
                            size: size,
                            onAnswer: null,
                            chosen: feedback.chosen,
                            answerLabel: l10n.answerWas,
                          ),
                          // Room for the label under the right answer.
                          SizedBox(height: size * 0.6),
                        ],
                      )
                    : question == null
                    ? KeyedSubtree(
                        key: const ValueKey('done'),
                        child: widget.done(context),
                      )
                    : Column(
                        key: ValueKey(_round.questionsAsked),
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

/// One footprint per step, filled as the game goes on.
class _Footprints extends StatelessWidget {
  const _Footprints({required this.steps, required this.progress});

  final int steps;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final done = (progress * steps).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < steps; i++)
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

/// The cheer after an answer.
class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.cheer});

  final Cheer cheer;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      CheerBadge(cheer: cheer, size: 72),
      const SizedBox(width: 16),
      Flexible(
        child: Text(
          cheer.text,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    ],
  );
}
