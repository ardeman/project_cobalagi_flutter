import 'package:go_router/go_router.dart';

import '../features/home/view/home_screen.dart';
import '../features/parent/view/parent_screen.dart';
import '../features/profiles/view/profiles_screen.dart';

GoRouter createRouter() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const ProfilesScreen()),
    GoRoute(
      path: '/play/:profileId',
      builder: (_, state) =>
          HomeScreen(profileId: int.parse(state.pathParameters['profileId']!)),
    ),
    GoRoute(path: '/parent', builder: (_, _) => const ParentScreen()),
  ],
);
