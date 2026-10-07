import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/adventure_map/view/adventure_map_screen.dart';
import '../features/adventure_map/view/island_screen.dart';
import '../features/learning/view/child_scope.dart';
import '../features/parent/view/parent_screen.dart';
import '../features/parent/view/progress_screen.dart';
import '../features/play/view/play_screen.dart';
import '../features/play/view/replay_screen.dart';
import '../features/pretest/view/pretest_screen.dart';
import '../features/profiles/view/profiles_screen.dart';
import '../features/splash/view/splash_screen.dart';
import '../features/tutorial/view/tutorial_screen.dart';
import '../features/warm_up/view/warm_up_game_screen.dart';
import '../features/warm_up/view/warm_up_island_screen.dart';
import '../learning/warm_up/warm_up.dart';

GoRouter createRouter({String initialLocation = '/splash'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/', builder: (_, _) => const ProfilesScreen()),
    // Everything a child sees shares one learning loop.
    ShellRoute(
      builder: (_, state, child) => ChildScope(
        key: ValueKey(_profileId(state)),
        profileId: _profileId(state),
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/child/:profileId',
          builder: (_, state) =>
              AdventureMapScreen(profileId: _profileId(state)),
          routes: [
            GoRoute(
              path: 'play',
              builder: (_, state) => PlayScreen(profileId: _profileId(state)),
            ),
            GoRoute(
              path: 'island/:conceptId',
              builder: (_, state) => IslandScreen(
                profileId: _profileId(state),
                conceptId: state.pathParameters['conceptId']!,
              ),
            ),
            GoRoute(
              path: 'tutorial/:conceptId',
              builder: (_, state) => TutorialScreen(
                profileId: _profileId(state),
                conceptId: state.pathParameters['conceptId']!,
              ),
            ),
            GoRoute(
              path: 'replay/:levelId',
              builder: (_, state) => ReplayScreen(
                profileId: _profileId(state),
                levelId: state.pathParameters['levelId']!,
              ),
            ),
            GoRoute(
              path: 'warm-up',
              builder: (_, state) =>
                  WarmUpIslandScreen(profileId: _profileId(state)),
              routes: [
                GoRoute(
                  path: ':game',
                  builder: (_, state) => WarmUpGameScreen(
                    profileId: _profileId(state),
                    game: WarmUpGame.values.byName(
                      state.pathParameters['game']!,
                    ),
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'pretest',
              builder: (_, state) =>
                  PretestScreen(profileId: _profileId(state)),
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: '/parent', builder: (_, _) => const ParentScreen()),
    GoRoute(
      path: '/parent/progress/:profileId',
      builder: (_, state) => ProgressScreen(
        profileId: int.parse(state.pathParameters['profileId']!),
      ),
    ),
  ],
);

int _profileId(GoRouterState state) =>
    int.parse(state.pathParameters['profileId']!);
