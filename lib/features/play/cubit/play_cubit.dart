import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../engine/interpreter/interpreter.dart';
import '../../../engine/interpreter/run_event.dart';
import '../../../engine/program/program.dart';
import '../../../engine/program/validation.dart';
import '../../../engine/world/level.dart';

enum PlayPhase { editing, running, succeeded, failed }

class PlayState {
  const PlayState({
    required this.level,
    this.phase = PlayPhase.editing,
    this.result,
    this.cursor = 0,
    this.playing = false,
    this.stepping = false,
    this.issues = const [],
    this.runs = 0,
    this.tries = 0,
    this.board = 0,
  });

  final Level level;

  /// Which of [level]'s boards is shown (see [Level.boards]): the one a run
  /// is on, or while editing the one the child peeks at. [result] is the
  /// run on this board; a run starts on the first and goes on to the next
  /// only once it solves one.
  final int board;

  /// The board being shown.
  Level get shownBoard => level.boards[board];

  /// Whether more boards follow this one when a run solves it.
  bool get hasNextBoard => board + 1 < level.boards.length;
  final PlayPhase phase;
  final RunResult? result;

  /// Index of the event being shown during a run.
  final int cursor;

  /// Whether the world should animate the event at [cursor] now.
  final bool playing;

  /// Step mode: pause after each event until [PlayCubit.step] is pressed.
  final bool stepping;

  /// Problems found before running; nothing runs while any exist.
  final List<ProgramIssue> issues;

  /// Number of runs started on this level so far.
  final int runs;

  /// Presses of Go or Step with blocks placed, including ones stopped by
  /// [issues] before running: how often the child has tried. Unlike [runs],
  /// these don't lower the score.
  final int tries;

  RunEvent? get currentEvent {
    final events = result?.events;
    if (phase != PlayPhase.running || !playing || events == null) return null;
    return cursor < events.length ? events[cursor] : null;
  }

  /// The saved value shown so far in playback, cleared when editing resets.
  int? get storedSteps {
    final events = result?.events;
    if (events == null) return null;
    final shown = phase == PlayPhase.running ? events.take(cursor + 1) : events;
    return shown.whereType<StepsStored>().lastOrNull?.value;
  }

  /// The editor block to highlight while running.
  String? get activeBlockId {
    final events = result?.events;
    if (phase != PlayPhase.running || events == null || events.isEmpty) {
      return null;
    }
    return events[cursor.clamp(0, events.length - 1)].blockId;
  }

  /// While the Magic Block's own blocks run: the call that runs them, so
  /// the child sees which Magic Block is at work.
  String? get activeCallId {
    final calls = result?.callIds;
    if (phase != PlayPhase.running || calls == null || calls.isEmpty) {
      return null;
    }
    return calls[cursor.clamp(0, calls.length - 1)];
  }

  /// After a run that walked into a rock: the block that made the move,
  /// so the child sees which one to fix. Other runs that fail are missing
  /// blocks rather than a wrong one, so they mark none.
  String? get bumpedBlockId {
    final last = result?.events.lastOrNull;
    if (phase != PlayPhase.failed || last is! Bumped) return null;
    return last.blockId;
  }

  PlayState copyWith({
    PlayPhase? phase,
    int? cursor,
    bool? playing,
    bool? stepping,
  }) => PlayState(
    level: level,
    board: board,
    phase: phase ?? this.phase,
    result: result,
    cursor: cursor ?? this.cursor,
    playing: playing ?? this.playing,
    stepping: stepping ?? this.stepping,
    issues: issues,
    runs: runs,
    tries: tries,
  );
}

/// Runs a program on the level and paces its playback with the world view,
/// which calls [eventShown] after animating each event.
class PlayCubit extends Cubit<PlayState> {
  PlayCubit(Level level) : super(PlayState(level: level));

  /// Plays the whole run. While paused in step mode, continues without pauses.
  void run(Program program) {
    if (state.phase == PlayPhase.running) {
      emit(state.copyWith(stepping: false, playing: true));
    } else {
      _start(program, stepping: false);
    }
  }

  /// Shows one event at a time.
  void step(Program program) {
    if (state.phase == PlayPhase.running) {
      if (!state.playing) emit(state.copyWith(playing: true));
    } else {
      _start(program, stepping: true);
    }
  }

  void _start(Program program, {required bool stepping}) {
    final level = state.level;
    final issues = validateProgram(program, level);
    final tries = state.tries + (program.body.isEmpty ? 0 : 1);
    if (issues.isNotEmpty || program.body.isEmpty) {
      emit(
        PlayState(
          level: level,
          board: state.board,
          issues: issues,
          runs: state.runs,
          tries: tries,
        ),
      );
      return;
    }
    _program = program;
    _runBoard(0, runs: state.runs + 1, tries: tries, stepping: stepping);
  }

  /// The program being run, for the boards still to come.
  Program? _program;

  void _runBoard(
    int board, {
    required int runs,
    required int tries,
    required bool stepping,
  }) {
    final result = runProgram(_program!, state.level.boards[board]);
    emit(
      PlayState(
        level: state.level,
        board: board,
        phase: PlayPhase.running,
        result: result,
        playing: board == 0 || !stepping,
        stepping: stepping,
        runs: runs,
        tries: tries,
      ),
    );
    if (result.events.isEmpty) _finish();
  }

  void eventShown() {
    if (state.phase != PlayPhase.running) return;
    final next = state.cursor + 1;
    if (next >= state.result!.events.length) {
      _finish();
    } else {
      emit(state.copyWith(cursor: next, playing: !state.stepping));
    }
  }

  void _finish() {
    final succeeded = state.result!.succeeded;
    if (succeeded && state.hasNextBoard) {
      _runBoard(
        state.board + 1,
        runs: state.runs,
        tries: state.tries,
        stepping: state.stepping,
      );
      return;
    }
    emit(
      state.copyWith(
        phase: succeeded ? PlayPhase.succeeded : PlayPhase.failed,
        playing: false,
      ),
    );
  }

  /// Back to editing, with the world at its starting position. The board
  /// a run stopped on stays in view, so the child sees what went wrong.
  void reset() => emit(
    PlayState(
      level: state.level,
      board: state.board,
      runs: state.runs,
      tries: state.tries,
    ),
  );

  /// While editing, shows another of the level's boards.
  void peek(int board) {
    if (state.phase != PlayPhase.editing || board == state.board) return;
    if (board < 0 || board >= state.level.boards.length) return;
    emit(
      PlayState(
        level: state.level,
        board: board,
        issues: state.issues,
        runs: state.runs,
        tries: state.tries,
      ),
    );
  }
}
