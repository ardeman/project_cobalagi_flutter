import 'package:cobalagi/engine/examples/example.dart';
import 'package:flutter_test/flutter_test.dart';

ExampleThing thing(
  ExampleColour colour,
  ExampleShape shape,
  ExampleSize size,
) => ExampleThing(colour: colour, shape: shape, size: size);

void main() {
  const greenCircle = ExampleThing(
    colour: ExampleColour.green,
    shape: ExampleShape.circle,
    size: ExampleSize.big,
  );
  const redTriangle = ExampleThing(
    colour: ExampleColour.red,
    shape: ExampleShape.triangle,
    size: ExampleSize.small,
  );

  test('distance counts colour, shape and size', () {
    expect(exampleDistance(greenCircle, greenCircle), 0);
    expect(
      exampleDistance(
        greenCircle,
        thing(ExampleColour.green, ExampleShape.circle, ExampleSize.medium),
      ),
      1,
    );
    expect(
      exampleDistance(
        greenCircle,
        thing(ExampleColour.green, ExampleShape.circle, ExampleSize.small),
      ),
      2,
    );
    expect(
      exampleDistance(
        greenCircle,
        thing(ExampleColour.red, ExampleShape.star, ExampleSize.small),
      ),
      6,
    );
  });

  test('too-alike examples leave Koba unsure', () {
    final few = [
      const LabeledExample(greenCircle, safe: true),
      const LabeledExample(redTriangle, safe: false),
    ];
    final greenTriangle = thing(
      ExampleColour.green,
      ExampleShape.triangle,
      ExampleSize.medium,
    );
    final redCircle = thing(
      ExampleColour.red,
      ExampleShape.circle,
      ExampleSize.medium,
    );
    expect(classify(greenTriangle, few), isNull);
    expect(classify(redCircle, few), isNull);
    expect(classify(greenTriangle, canonicalExamples), isTrue);
    expect(classify(redCircle, canonicalExamples), isFalse);
  });

  test('the varied set labels every neighbour without a tie', () {
    for (final neighbour in safeNeighbours) {
      expect(
        classify(neighbour, canonicalExamples),
        isTrue,
        reason: '$neighbour',
      );
    }
    for (final neighbour in unsafeNeighbours) {
      expect(
        classify(neighbour, canonicalExamples),
        isFalse,
        reason: '$neighbour',
      );
    }
  });

  test('no examples means unsure', () {
    expect(classify(greenCircle, const []), isNull);
  });

  test('a picture round-trips through JSON', () {
    const example = LabeledExample(greenCircle, safe: true);
    expect(
      LabeledExample.fromJson(example.toJson()).thing.colour,
      greenCircle.colour,
    );
    expect(LabeledExample.fromJson(example.toJson()).safe, isTrue);
  });
}
