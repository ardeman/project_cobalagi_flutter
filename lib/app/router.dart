import 'package:go_router/go_router.dart';

import '../features/home/view/home_screen.dart';
import '../features/parent/view/parent_screen.dart';
import '../features/play/view/play_screen.dart';
import '../features/profiles/view/profiles_screen.dart';

GoRouter createRouter() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const ProfilesScreen()),
    GoRoute(
      path: '/child/:profileId',
      builder: (_, state) => HomeScreen(profileId: _profileId(state)),
      routes: [
        GoRoute(
          path: 'level/:index',
          builder: (_, state) => PlayScreen(
            profileId: _profileId(state),
            levelIndex: int.parse(state.pathParameters['index']!),
          ),
        ),
      ],
    ),
    GoRoute(path: '/parent', builder: (_, _) => const ParentScreen()),
  ],
);

int _profileId(GoRouterState state) =>
    int.parse(state.pathParameters['profileId']!);
