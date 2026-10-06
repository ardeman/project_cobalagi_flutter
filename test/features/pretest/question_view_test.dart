import 'dart:math';

import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/features/pretest/view/question_views.dart';
import 'package:cobalagi/learning/placement/pretest_generator.dart';
import 'package:cobalagi/learning/placement/pretest_question.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpQuestion(
  WidgetTester tester,
  PretestQuestion question, {
  int? chosen,
  double size = 150,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: QuestionView(
            question: question,
            size: size,
            onAnswer: chosen == null ? (_) {} : null,
            chosen: chosen,
            answerLabel: 'The answer is this one!',
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('left and right choices fit a narrow phone with large targets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(312, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final side = PretestGenerator(
      objects: const ['sun', 'star', 'house', 'car'],
      colors: const ['red', 'blue', 'green'],
      random: Random(1),
    ).question(PretestSkill.direction, 1);
    await pumpQuestion(tester, side, size: 110);
    expect(tester.takeException(), isNull);
    final cards = find.byType(Card);
    expect(cards, findsNWidgets(2));
    for (final card in [cards.at(0), cards.at(1)]) {
      expect(tester.getSize(card).width, greaterThanOrEqualTo(64));
      expect(tester.getTopLeft(card).dx, greaterThanOrEqualTo(0));
      expect(tester.getTopRight(card).dx, lessThanOrEqualTo(312));
    }
  });

  final question = PretestGenerator(
    objects: const ['sun', 'star', 'house', 'car'],
    colors: const ['red', 'blue', 'green'],
    random: Random(1),
  ).question(PretestSkill.pattern, 1);
  final wrong = (question.correct + 1) % question.optionCount;

  testWidgets('before answering, no option is marked', (tester) async {
    await pumpQuestion(tester, question);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets('a right answer gets a check mark only', (tester) async {
    await pumpQuestion(tester, question, chosen: question.correct);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(find.text('The answer is this one!'), findsNothing);
  });

  testWidgets('a wrong answer is marked and the right one is shown', (
    tester,
  ) async {
    await pumpQuestion(tester, question, chosen: wrong);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    // The check sits on the right option, the cross on the tapped one.
    final cards = find.byType(Card);
    final check = tester.getCenter(find.byIcon(Icons.check_rounded));
    final cross = tester.getCenter(find.byIcon(Icons.close_rounded));
    double distanceTo(int i, Offset p) =>
        (tester.getTopRight(cards.at(i)) - p).distance;
    expect(distanceTo(question.correct, check), lessThan(60));
    expect(distanceTo(wrong, cross), lessThan(60));
  });

  testWidgets('after a wrong tap, the label sits under the right option', (
    tester,
  ) async {
    await pumpQuestion(tester, question, chosen: wrong);
    final label = find.text('The answer is this one!');
    expect(label, findsOneWidget);
    final card = find.byType(Card).at(question.correct);
    expect(
      tester.getTopLeft(label).dy,
      greaterThan(tester.getBottomLeft(card).dy),
      reason: 'below the card',
    );
    expect(
      (tester.getCenter(label).dx - tester.getCenter(card).dx).abs(),
      lessThan(4),
      reason: 'centred under it',
    );
  });
}
