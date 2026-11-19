/// Picture examples Koba learns from on the Teach Koba planet.
///
/// A thing is only colour, shape and size, so a child can tell two apart
/// without reading. The model is nearest neighbour: the label of the closest
/// example, or unsure when the closest examples disagree. Pure Dart, so the
/// interpreter can ask it while the eye block looks ahead.
enum ExampleColour { green, red, blue, yellow }

enum ExampleShape { circle, square, triangle, star }

/// Small, medium, big. One step apart counts half as much as a different
/// colour or shape; small to big counts the same as a different colour.
enum ExampleSize { small, medium, big }

final class ExampleThing {
  const ExampleThing({
    required this.colour,
    required this.shape,
    required this.size,
  });

  factory ExampleThing.fromJson(Map<String, Object?> json) => ExampleThing(
    colour: ExampleColour.values.byName(json['colour']! as String),
    shape: ExampleShape.values.byName(json['shape']! as String),
    size: ExampleSize.values.byName(json['size']! as String),
  );

  final ExampleColour colour;
  final ExampleShape shape;
  final ExampleSize size;

  Map<String, Object?> toJson() => {
    'colour': colour.name,
    'shape': shape.name,
    'size': size.name,
  };
}

/// An example the child has sorted: a [thing] that is [safe] to pass, or not.
final class LabeledExample {
  const LabeledExample(this.thing, {required this.safe});

  factory LabeledExample.fromJson(Map<String, Object?> json) =>
      LabeledExample(ExampleThing.fromJson(json), safe: json['safe']! as bool);

  final ExampleThing thing;
  final bool safe;

  Map<String, Object?> toJson() => {...thing.toJson(), 'safe': safe};
}

/// One round of the sorting screen: [show] indexes into the lesson's
/// examples (the child sorts these), then [ask] indexes into the lesson's
/// asks (Koba labels these from what was sorted so far).
final class SortRound {
  const SortRound({required this.show, required this.ask});

  factory SortRound.fromJson(Map<String, Object?> json) => SortRound(
    show: (json['show']! as List).cast<int>(),
    ask: (json['ask']! as List).cast<int>(),
  );

  final List<int> show;
  final List<int> ask;

  Map<String, Object?> toJson() => {'show': show, 'ask': ask};
}

/// How far apart two things are. Colour and shape each add 2 when they
/// differ. Size adds the number of steps between them (0, 1 or 2), so one
/// step is half a colour change and small-to-big matches a colour change.
int exampleDistance(ExampleThing a, ExampleThing b) =>
    (a.colour == b.colour ? 0 : 2) +
    (a.shape == b.shape ? 0 : 2) +
    (a.size.index - b.size.index).abs();

/// The label of the nearest example in [examples], or null when there are
/// none, or when the nearest distance is shared by both labels (Koba is
/// not sure). Several examples at that distance vote; the majority wins.
bool? classify(ExampleThing thing, List<LabeledExample> examples) {
  if (examples.isEmpty) return null;
  var best = 1 << 30;
  var safeVotes = 0;
  var unsafeVotes = 0;
  for (final example in examples) {
    final distance = exampleDistance(thing, example.thing);
    if (distance < best) {
      best = distance;
      safeVotes = example.safe ? 1 : 0;
      unsafeVotes = example.safe ? 0 : 1;
    } else if (distance == best) {
      if (example.safe) {
        safeVotes++;
      } else {
        unsafeVotes++;
      }
    }
  }
  if (safeVotes > unsafeVotes) return true;
  if (unsafeVotes > safeVotes) return false;
  return null;
}

/// The varied set practice puzzles train on: green and blue are safe, red
/// and yellow are not, with shapes and sizes mixed so one feature is not
/// the whole story. Hand-made lessons use their own smaller sets.
const canonicalExamples = <LabeledExample>[
  LabeledExample(
    ExampleThing(
      colour: ExampleColour.green,
      shape: ExampleShape.circle,
      size: ExampleSize.big,
    ),
    safe: true,
  ),
  LabeledExample(
    ExampleThing(
      colour: ExampleColour.green,
      shape: ExampleShape.triangle,
      size: ExampleSize.small,
    ),
    safe: true,
  ),
  LabeledExample(
    ExampleThing(
      colour: ExampleColour.green,
      shape: ExampleShape.square,
      size: ExampleSize.medium,
    ),
    safe: true,
  ),
  LabeledExample(
    ExampleThing(
      colour: ExampleColour.blue,
      shape: ExampleShape.circle,
      size: ExampleSize.small,
    ),
    safe: true,
  ),
  LabeledExample(
    ExampleThing(
      colour: ExampleColour.blue,
      shape: ExampleShape.star,
      size: ExampleSize.big,
    ),
    safe: true,
  ),
  LabeledExample(
    ExampleThing(
      colour: ExampleColour.red,
      shape: ExampleShape.triangle,
      size: ExampleSize.small,
    ),
    safe: false,
  ),
  LabeledExample(
    ExampleThing(
      colour: ExampleColour.red,
      shape: ExampleShape.circle,
      size: ExampleSize.big,
    ),
    safe: false,
  ),
  LabeledExample(
    ExampleThing(
      colour: ExampleColour.red,
      shape: ExampleShape.square,
      size: ExampleSize.medium,
    ),
    safe: false,
  ),
  LabeledExample(
    ExampleThing(
      colour: ExampleColour.yellow,
      shape: ExampleShape.star,
      size: ExampleSize.small,
    ),
    safe: false,
  ),
  LabeledExample(
    ExampleThing(
      colour: ExampleColour.yellow,
      shape: ExampleShape.circle,
      size: ExampleSize.medium,
    ),
    safe: false,
  ),
];

/// New things one size step from a [canonicalExamples] entry, so the full
/// set labels each of them without a tie. Practice mazes place these.
const safeNeighbours = <ExampleThing>[
  ExampleThing(
    colour: ExampleColour.green,
    shape: ExampleShape.circle,
    size: ExampleSize.medium,
  ),
  ExampleThing(
    colour: ExampleColour.green,
    shape: ExampleShape.triangle,
    size: ExampleSize.medium,
  ),
  ExampleThing(
    colour: ExampleColour.green,
    shape: ExampleShape.square,
    size: ExampleSize.small,
  ),
  ExampleThing(
    colour: ExampleColour.green,
    shape: ExampleShape.square,
    size: ExampleSize.big,
  ),
  ExampleThing(
    colour: ExampleColour.blue,
    shape: ExampleShape.circle,
    size: ExampleSize.medium,
  ),
  ExampleThing(
    colour: ExampleColour.blue,
    shape: ExampleShape.star,
    size: ExampleSize.medium,
  ),
];

const unsafeNeighbours = <ExampleThing>[
  ExampleThing(
    colour: ExampleColour.red,
    shape: ExampleShape.triangle,
    size: ExampleSize.medium,
  ),
  ExampleThing(
    colour: ExampleColour.red,
    shape: ExampleShape.circle,
    size: ExampleSize.medium,
  ),
  ExampleThing(
    colour: ExampleColour.red,
    shape: ExampleShape.square,
    size: ExampleSize.small,
  ),
  ExampleThing(
    colour: ExampleColour.red,
    shape: ExampleShape.square,
    size: ExampleSize.big,
  ),
  ExampleThing(
    colour: ExampleColour.yellow,
    shape: ExampleShape.star,
    size: ExampleSize.medium,
  ),
  ExampleThing(
    colour: ExampleColour.yellow,
    shape: ExampleShape.circle,
    size: ExampleSize.small,
  ),
  ExampleThing(
    colour: ExampleColour.yellow,
    shape: ExampleShape.circle,
    size: ExampleSize.big,
  ),
];
