import 'package:go_router/go_router.dart';
import '../../presentation/screens/detail/anime_detail_screen.dart';
import '../../presentation/screens/main_navigation_screen.dart';
import '../../presentation/screens/player/video_player_screen.dart';
import '../../presentation/screens/search/search_screen.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/detail',
        builder: (context, state) {
          final urlId = state.extra as String? ?? '';
          return AnimeDetailScreen(urlId: urlId);
        },
      ),
      GoRoute(
        path: '/player',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return VideoPlayerScreen(arguments: args);
        },
      ),
    ],
  );
}
