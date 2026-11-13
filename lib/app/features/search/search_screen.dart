import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../feed/models/supported_filters.dart';
import '../feed/providers/data_gateway_provider.dart';
import '../feed/providers/feed_filter_provider.dart';
import '../shell/app_shell.dart';

/// The Search tab: say what you're shopping for, or browse a category.
/// Either one sets the feed's filter and takes the Shopper to the Feed.
/// Shopping Sessions (#11) will live here.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  void _showInFeed(void Function(FeedFilterNotifier filter) change) {
    change(ref.read(feedFilterProvider.notifier));
    StatefulNavigationShell.of(context).goBranch(AppTab.feed.index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        ref.watch(supportedFiltersProvider).asData?.value.categories ??
        const <ProductCategory>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (query) {
                if (query.trim().isEmpty) return;
                _showInFeed((filter) => filter.setSearch(query));
              },
              decoration: InputDecoration(
                hintText: 'What are you shopping for?',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Browse a category',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final category in categories)
            ListTile(
              title: Text(category.label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  _showInFeed((filter) => filter.setCategory(category.id)),
            ),
        ],
      ),
    );
  }
}
