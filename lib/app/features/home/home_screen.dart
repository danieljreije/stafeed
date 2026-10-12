import 'package:stafeed/app/features/feed/feed_screen.dart';
import 'package:flutter/material.dart';

import '../saved/saved_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stafeed')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40.0),

            Text('Discover', style: Theme.of(context).textTheme.headlineLarge),

            const SizedBox(height: 12.0),

            Text(
              'Swipe through products selected just for you.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            const SizedBox(height: 24.0),

            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const FeedScreen()),
                );
              },
              child: const Text('Start Exploring'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SavedScreen()),
                );
              },
              child: const Text('Saved Products'),
            ),
          ],
        ),
      ),
    );
  }
}
