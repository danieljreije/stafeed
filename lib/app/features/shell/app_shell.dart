import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The tabs, in the order they sit in the bar.
enum AppTab { feed, search, saved, profile }

/// The four tabs at the bottom of the app. Each tab keeps its place while
/// the Shopper is on another one.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Tapping the tab the Shopper is already on goes back to its
          // first screen.
          initialLocation: index == navigationShell.currentIndex,
        ),
        // The Saved tab is a bookmark, not a heart: the heart is the Save
        // button on a Feed Item.
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.travel_explore),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
