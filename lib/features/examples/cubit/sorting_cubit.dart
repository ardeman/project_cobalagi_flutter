import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../engine/examples/example.dart';
import '../../../engine/world/level.dart';

enum SortingPhase { placing, results }

/// Where the sorting screen is: which pictures are in a bin, which one is
/// picked, and whether Koba is showing what it guessed.
final class SortingState {
  const SortingState({
    required this.round,
    required this.placed,
    this.selected,
    this.wobble,
    required this.phase,
  });

  /// Starts on the first round, with nothing sorted.
  factory SortingState.initial() =>
      const SortingState(round: 0, placed: {}, phase: SortingPhase.placing);

  final int round;

  /// Example indexes the child has put in the right bin.
  final Set<int> placed;

  /// A picture waiting for a bin, or null.
  final int? selected;

  /// A picture that just went in the wrong bin, so it can shake.
  final int? wobble;

  final SortingPhase phase;

  SortingState copyWith({
    int? round,
    Set<int>? placed,
    int? Function()? selected,
    int? Function()? wobble,
    SortingPhase? phase,
  }) => SortingState(
    round: round ?? this.round,
    placed: placed ?? this.placed,
    selected: selected != null ? selected() : this.selected,
    wobble: wobble != null ? wobble() : this.wobble,
    phase: phase ?? this.phase,
  );
}

/// The child sorts the lesson's pictures. A wrong bin shakes the picture
/// back; the right bin keeps it. When the round is sorted, Koba labels the
/// new pictures from those examples.
class SortingCubit extends Cubit<SortingState> {
  SortingCubit(this.level) : super(SortingState.initial());

  final Level level;

  SortRound get _round => level.rounds[state.round];

  /// Pictures of this round that are still loose.
  List<int> get loose => [
    for (final index in _round.show)
      if (!state.placed.contains(index)) index,
  ];

  /// Picks [index] so the next bin tap, or a drop, places it.
  void pick(int index) {
    if (state.phase != SortingPhase.placing) return;
    if (!loose.contains(index)) return;
    emit(state.copyWith(selected: () => index, wobble: () => null));
  }

  /// Picks [index], or puts it down when it was already picked.
  void tap(int index) {
    if (state.selected == index) {
      emit(state.copyWith(selected: () => null));
      return;
    }
    pick(index);
  }

  /// Puts the picked picture in the safe bin or the other one.
  void place(bool safe) {
    if (state.phase != SortingPhase.placing) return;
    final index = state.selected;
    if (index == null) return;
    final right = level.examples[index].safe == safe;
    if (!right) {
      emit(state.copyWith(selected: () => null, wobble: () => index));
      return;
    }
    final placed = {...state.placed, index};
    final done = _round.show.every(placed.contains);
    emit(
      state.copyWith(
        placed: placed,
        selected: () => null,
        wobble: () => null,
        phase: done ? SortingPhase.results : SortingPhase.placing,
      ),
    );
  }

  /// The next round's pictures, after Koba got some wrong.
  void morePictures() {
    if (state.phase != SortingPhase.results) return;
    if (state.round + 1 >= level.rounds.length) return;
    emit(
      state.copyWith(
        round: state.round + 1,
        phase: SortingPhase.placing,
        selected: () => null,
        wobble: () => null,
      ),
    );
  }

  /// What Koba says each new picture is, from the pictures sorted so far.
  List<bool?> get guesses {
    final known = [for (final index in state.placed) level.examples[index]];
    return [
      for (final index in _round.ask) classify(level.asks[index].thing, known),
    ];
  }

  /// Every new picture of this round landed on its true bin.
  bool get guessesRight {
    final round = _round;
    final guessed = guesses;
    for (var i = 0; i < round.ask.length; i++) {
      if (guessed[i] != level.asks[round.ask[i]].safe) return false;
    }
    return round.ask.isNotEmpty;
  }
}
