import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/audio/audio_service.dart';
import 'package:cobalagi/features/play_time/data/play_clock.dart';
import 'package:cobalagi/features/play_time/view/break_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Records the voice clips asked for.
class _Voices extends SilentAudioService {
  final played = <String>[];

  @override
  Future<void> playVoice(
    String clipId, {
    required String languageCode,
    bool queue = false,
  }) async => played.add(clipId);
}

void main() {
  group('PlayClock', () {
    late DateTime now;
    late PlayClock clock;
    setUp(() {
      now = DateTime(2026, 10, 7, 9);
      clock = PlayClock(now: () => now);
    });

    test('counts only while playing', () {
      now = now.add(const Duration(minutes: 5));
      expect(clock.played, Duration.zero);
      clock.start();
      now = now.add(const Duration(minutes: 10));
      clock.stop();
      now = now.add(const Duration(minutes: 30));
      clock.start();
      now = now.add(const Duration(minutes: 6));
      expect(clock.played, const Duration(minutes: 16));
      expect(clock.isDue(15), isTrue);
      expect(clock.isDue(30), isFalse);
      expect(clock.isDue(0), isFalse, reason: 'off');
    });

    test('pauses while the app is in the background', () {
      clock.start();
      now = now.add(const Duration(minutes: 3));
      clock.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(hours: 1));
      clock.didChangeAppLifecycleState(AppLifecycleState.resumed);
      now = now.add(const Duration(minutes: 2));
      expect(clock.played, const Duration(minutes: 5));
    });

    test('a break starts counting from zero again', () {
      clock.start();
      now = now.add(const Duration(minutes: 20));
      clock.reset();
      expect(clock.played, Duration.zero);
      now = now.add(const Duration(minutes: 4));
      expect(clock.played, const Duration(minutes: 4), reason: 'still playing');
    });
  });

  testWidgets('the break screen speaks; a grown-up continues', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var now = DateTime(2026, 10, 7, 9);
    final clock = PlayClock(now: () => now)..start();
    now = now.add(const Duration(minutes: 40));
    final voices = _Voices();
    var continued = 0;
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('players')),
        GoRoute(
          path: '/break',
          builder: (_, _) => BreakScreen(onContinue: () => continued++),
        ),
      ],
      initialLocation: '/break',
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AudioService>.value(value: voices),
          RepositoryProvider.value(value: clock),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Time for a break!'), findsOneWidget);
    expect(voices.played, ['break_time']);

    // Continuing asks a grown-up first.
    await tester.tap(find.text('A grown-up can continue'));
    await tester.pumpAndSettle();
    final question = find.textContaining(RegExp(r'What is \d+ × \d+\?'));
    final match = RegExp(
      r'(\d+) × (\d+)',
    ).firstMatch(tester.widget<Text>(question).data!)!;
    await tester.enterText(
      find.byKey(const Key('parentGateAnswer')),
      '${int.parse(match[1]!) * int.parse(match[2]!)}',
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(continued, 1);
    expect(clock.played, Duration.zero, reason: 'the break resets the time');

    // Or the child goes back to the players.
    await tester.tap(find.text('Back to players'));
    await tester.pumpAndSettle();
    expect(find.text('players'), findsOneWidget);
  });
}
