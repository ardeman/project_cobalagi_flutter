import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/adventure_map/view/adventure_map_screen.dart';
import '../features/learning/view/child_scope.dart';
import '../features/parent/view/parent_screen.dart';
import '../features/play/view/play_screen.dart';
import '../features/profiles/view/profiles_screen.dart';

GoRouter createRouter() => GoRouter(
  routes: [
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
          ],
        ),
      ],
    ),
    GoRoute(path: '/parent', builder: (_, _) => const ParentScreen()),
  ],
);

int _profileId(GoRouterState state) =>
    int.parse(state.pathParameters['profileId']!);
