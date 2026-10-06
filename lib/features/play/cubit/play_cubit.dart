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
  });

  final Level level;
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

  PlayState copyWith({
    PlayPhase? phase,
    int? cursor,
    bool? playing,
    bool? stepping,
  }) => PlayState(
    level: level,
    phase: phase ?? this.phase,
    result: result,
    cursor: cursor ?? this.cursor,
    playing: playing ?? this.playing,
    stepping: stepping ?? this.stepping,
    issues: issues,
    runs: runs,
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
    if (issues.isNotEmpty || program.body.isEmpty) {
      emit(PlayState(level: level, issues: issues, runs: state.runs));
      return;
    }
    final result = runProgram(program, level);
    emit(
      PlayState(
        level: level,
        phase: PlayPhase.running,
        result: result,
        playing: true,
        stepping: stepping,
        runs: state.runs + 1,
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

  void _finish() => emit(
    state.copyWith(
      phase: state.result!.succeeded ? PlayPhase.succeeded : PlayPhase.failed,
      playing: false,
    ),
  );

  /// Back to editing, with the world at its starting position.
  void reset() => emit(PlayState(level: state.level, runs: state.runs));
}
