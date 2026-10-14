/// A shape of [unit] steps that repeats in a route, once from each of
/// [rounds]. The last round may stop early, on the flag.
typedef RoutePattern = ({int unit, List<int> rounds});

/// The repeating shape that makes the shortest program for [steps] (shapes
/// of up to half the route, coming at least twice), or null if nothing
/// repeats. A last, partial round counts only where the run stops: on the
/// flag.
///
/// With [gaps] (the Magic Block, which is called anywhere) other steps may
/// come between rounds; otherwise the rounds follow one another, like a
/// repeat. With [toEnd] (until the flag) the rounds must reach the flag.
RoutePattern? findPattern<T>(
  List<T> steps, {
  bool gaps = false,
  bool toEnd = false,
}) {
  RoutePattern? best;
  int? bestBlocks;
  for (var unit = 1; unit * 2 <= steps.length; unit++) {
    for (var start = 0; start + unit * 2 <= steps.length; start++) {
      final rounds = patternRounds(steps, start, unit, gaps: gaps);
      if (rounds.length < 2) continue;
      final end = (rounds.last + unit).clamp(0, steps.length);
      if (toEnd && end != steps.length) continue;
      final covered = [
        for (final r in rounds) (r + unit).clamp(0, steps.length) - r,
      ].fold(0, (a, b) => a + b);
      final blocks = steps.length - covered + unit + (gaps ? rounds.length : 1);
      if (bestBlocks == null || blocks < bestBlocks) {
        best = (unit: unit, rounds: rounds);
        bestBlocks = blocks;
      }
    }
  }
  return best;
}

/// Where each round of the shape `steps[start, start + unit)` starts, taking
/// every round from [start] on (with [gaps], after any other steps). The
/// last round may be partial only if it runs to the end of [steps].
List<int> patternRounds<T>(
  List<T> steps,
  int start,
  int unit, {
  bool gaps = false,
}) {
  final rounds = <int>[];
  var at = start;
  while (at < steps.length) {
    final take = unit < steps.length - at ? unit : steps.length - at;
    var same = true;
    for (var i = 0; i < take && same; i++) {
      same = steps[at + i] == steps[start + i];
    }
    if (same) {
      rounds.add(at);
      at += take;
    } else if (gaps) {
      at++;
    } else {
      break;
    }
  }
  return rounds;
}
