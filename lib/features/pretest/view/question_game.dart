import 'dart:math';

import 'package:flutter/material.dart';

import 'package:cobalagi/core/gamepad/gamepad_shortcut.dart';
import 'package:cobalagi/core/gamepad/pad_input.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/audio/voice_clips.dart';
import '../../../core/feedback/cheers.dart';
import '../../../core/responsive/window_class.dart';
import '../../../learning/placement/pretest_question.dart';
import '../../../learning/placement/question_round.dart';
import 'package:cobalagi/core/widgets/coach_tour.dart';
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
    this.tour = false,
    this.onTourDone,
  });

  /// Opens with Koba showing how to play: listen, tap a picture, the paw
  /// prints. "?" shows it again any time.
  final bool tour;

  /// The opening tour has been seen.
  final VoidCallback? onTourDone;

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
  var _touring = false;
  final _listenKey = GlobalKey();
  final _answersKey = GlobalKey();
  final _pawsKey = GlobalKey();

  void _endTour() {
    if (!_touring) return;
    setState(() => _touring = false);
    widget.onTourDone?.call();
    _speak();
  }

  @override
  void initState() {
    super.initState();
    _touring = widget.tour;
    // The question is asked once the tour is over.
    if (!_touring) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
    }
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
    final game = Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        leading: CloseButton(onPressed: widget.onClose),
        title: KeyedSubtree(
          key: _pawsKey,
          // On a narrow phone the prints shrink to leave room for "?".
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: _Footprints(steps: widget.steps, progress: _round.progress),
          ),
        ),
        actions: [
          GamepadShortcut(
            button: PadButton.view,
            onPressed: _touring || question == null
                ? null
                : () => setState(() => _touring = true),
            child: IconButton.filledTonal(
              tooltip: l10n.tourHelp,
              onPressed: _touring || question == null
                  ? null
                  : () => setState(() => _touring = true),
              icon: const Icon(Icons.question_mark_rounded),
            ),
          ),
        ],
      ),
      // The game pads itself below the bar.
      body: SafeArea(
        top: false,
        bottom: false,
        child: WindowClassBuilder(
          builder: (context, windowClass) {
            final media = MediaQuery.of(context);
            // A phone held sideways has little height: slimmer margins and
            // prompt row leave more of it to the pictures.
            final short = media.size.height < 480;
            final topRow = short ? 64.0 : 96.0;
            final padding = belowBars(
              context,
              EdgeInsets.symmetric(horizontal: 24, vertical: short ? 8 : 24),
            );
            // Also fit the height, so a phone held sideways shows the
            // answers without scrolling.
            final height = media.size.height - padding.vertical;
            final size = min(switch (windowClass) {
              WindowClass.compact => 110.0,
              WindowClass.medium => 150.0,
              WindowClass.expanded => 190.0,
            }, max(80.0, height / 3.4));
            // Never a scroll: a game taller than the screen (many things to
            // count, a long row of steps) shrinks as a whole to fit. The
            // question and its answer are the same height, so they shrink
            // alike and the pictures stay put.
            return Padding(
              padding: padding,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: media.size.width - padding.horizontal,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: feedback != null
                          // The question and its answer share one layout: the
                          // same top row height, the same room under the cards,
                          // so the pictures stay put when the child answers.
                          ? Column(
                              key: ValueKey(
                                'feedback-${_round.questionsAsked}',
                              ),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: topRow,
                                  child: Center(
                                    child: _FeedbackBanner(
                                      cheer: feedback.cheer,
                                      size: min(72, topRow),
                                    ),
                                  ),
                                ),
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
                                SizedBox(
                                  height: topRow,
                                  child: Center(
                                    child: _Prompt(
                                      listenKey: _touring ? _listenKey : null,
                                      text: promptFor(l10n, question).$1,
                                      onListen: _speak,
                                    ),
                                  ),
                                ),
                                SizedBox(height: size * 0.2),
                                KeyedSubtree(
                                  key: _touring ? _answersKey : null,
                                  child: QuestionView(
                                    question: question,
                                    size: size,
                                    onAnswer: _answer,
                                    answerLabel: l10n.answerWas,
                                  ),
                                ),
                                SizedBox(height: size * 0.6),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    return Stack(
      children: [
        game,
        if (_touring)
          CoachTour(
            onDone: _endTour,
            steps: [
              CoachStep(
                target: _listenKey,
                text: l10n.tourWarmUpListen,
                clip: VoiceClips.tourWarmUpListen,
              ),
              CoachStep(
                target: _answersKey,
                text: l10n.tourWarmUpAnswer,
                clip: VoiceClips.tourWarmUpAnswer,
              ),
              CoachStep(
                target: _pawsKey,
                text: l10n.tourWarmUpSteps,
                clip: VoiceClips.tourWarmUpSteps,
              ),
            ],
          ),
      ],
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.text, required this.onListen, this.listenKey});

  final Key? listenKey;

  final String text;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      GamepadShortcut(
        button: PadButton.menu,
        onPressed: onListen,
        child: IconButton.filled(
          key: listenKey,
          tooltip: AppLocalizations.of(context).listenAgain,
          iconSize: 40,
          onPressed: onListen,
          icon: const Icon(Icons.volume_up_rounded),
        ),
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
  const _FeedbackBanner({required this.cheer, required this.size});

  final Cheer cheer;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      CheerBadge(cheer: cheer, size: size),
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
