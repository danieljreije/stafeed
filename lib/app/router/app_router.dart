import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/feed/feed_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/product/product_details_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/saved/saved_screen.dart';
import '../features/search/search_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/shopper/providers/shopper_config_provider.dart';

/// Where each screen lives.
abstract final class AppRoutes {
  /// Shown for a moment at launch, while the Shopper's config is read.
  static const starting = '/starting';
  static const onboarding = '/onboarding';

  // The four tabs.
  static const feed = '/feed';
  static const search = '/search';
  static const saved = '/saved';
  static const profile = '/profile';

  /// A Product's details. [offerId] is the Offer the Shopper saw, shown
  /// again if the Product still has it.
  static String productDetails(String productId, {String? offerId}) => Uri(
    path: '/product/${Uri.encodeComponent(productId)}',
    queryParameters: offerId == null ? null : {'offer': offerId},
  ).toString();
}

/// The app's routes: onboarding on first launch, then the four tabs, each
/// keeping its place while the Shopper is on another one.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Asks the router to check its redirect again when onboarding finishes.
  final shopperChanged = ValueNotifier<int>(0);
  ref.listen(shopperConfigProvider, (_, _) => shopperChanged.value++);

  final router = GoRouter(
    initialLocation: AppRoutes.feed,
    refreshListenable: shopperChanged,
    redirect: (context, state) {
      final config = ref.read(shopperConfigProvider);
      final location = state.matchedLocation;

      if (config.isLoading) {
        return location == AppRoutes.starting ? null : AppRoutes.starting;
      }

      final isOnboarded = switch (config) {
        AsyncData(:final value) => value != null,
        _ => false,
      };
      if (!isOnboarded) {
        return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      // Onboarding is shown once: afterwards the app opens on the Feed.
      if (location == AppRoutes.onboarding || location == AppRoutes.starting) {
        return AppRoutes.feed;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.starting,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: OnboardingScreen()),
      ),
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) =>
            NoTransitionPage(child: AppShell(navigationShell: navigationShell)),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.feed,
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.saved,
                builder: (context, state) => const SavedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Opens over the tabs, so Back returns to the tab it came from.
      GoRoute(
        path: '/product/:productId',
        builder: (context, state) => ProductDetailsScreen(
          productId: state.pathParameters['productId']!,
          offerId: state.uri.queryParameters['offer'],
        ),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  ref.onDispose(shopperChanged.dispose);

  return router;
});
