import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../feed/models/supported_filters.dart';
import '../feed/providers/data_gateway_provider.dart';
import '../feed/providers/feed_filter_provider.dart';
import '../shell/app_shell.dart';
import '../shopping_sessions/models/shopping_session.dart';
import '../shopping_sessions/providers/shopping_sessions_provider.dart';
import '../shopping_sessions/session_editor_screen.dart';

/// The Search tab: the Shopper's Shopping Sessions, a quick search, and
/// categories to browse. A session shows in the Feed tab; a search or a
/// category narrows For You.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  void _goToFeed() =>
      StatefulNavigationShell.of(context).goBranch(AppTab.feed.index);

  /// A search or a category narrows For You, so any session ends.
  void _showInFeed(void Function(FeedFilterNotifier filter) change) {
    ref.read(shoppingSessionsProvider.notifier).end();
    change(ref.read(feedFilterProvider.notifier));
    _goToFeed();
  }

  Future<void> _newSession() async {
    if (await openSessionEditor(context) && mounted) _goToFeed();
  }

  Future<void> _resume(ShoppingSession session) async {
    await ref.read(shoppingSessionsProvider.notifier).start(session.id);
    if (mounted) _goToFeed();
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
    final sessions =
        ref.watch(shoppingSessionsProvider).value ?? const ShoppingSessions();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Shopping sessions',
                    style: textTheme.titleMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _newSession,
                  icon: const Icon(Icons.add),
                  label: const Text('New session'),
                ),
              ],
            ),
          ),
          if (sessions.sessions.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Shopping for something special? Start a session: it gets '
                'its own feed and never changes For You.',
              ),
            ),
          for (final session in sessions.sessions)
            _SessionTile(
              session: session,
              isActive: session.id == sessions.activeId,
              onResume: () => _resume(session),
            ),
          const Divider(height: 32),
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
                hintText: 'Quick search in For You',
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
            child: Text('Browse a category', style: textTheme.titleMedium),
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

enum _SessionAction { edit, rename, reset, delete }

class _SessionTile extends ConsumerWidget {
  const _SessionTile({
    required this.session,
    required this.isActive,
    required this.onResume,
  });

  final ShoppingSession session;
  final bool isActive;
  final VoidCallback onResume;

  String get _summary => [
    if (session.goal.isNotEmpty) '"${session.goal}"',
    if (session.maxPrice case final price?) 'under ${price.format()}',
    ?session.brand,
    ?session.category,
  ].join(' · ');

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    _SessionAction action,
  ) async {
    final sessions = ref.read(shoppingSessionsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case _SessionAction.edit:
        await openSessionEditor(context, session: session);
      case _SessionAction.rename:
        final name = await showDialog<String>(
          context: context,
          builder: (_) => _RenameDialog(name: session.name),
        );
        if (name != null) await sessions.rename(session.id, name);
      case _SessionAction.reset:
        await sessions.reset(session.id);
        messenger.showSnackBar(
          SnackBar(content: Text('"${session.name}" starts afresh.')),
        );
      case _SessionAction.delete:
        await sessions.delete(session.id);
        messenger.showSnackBar(
          SnackBar(content: Text('"${session.name}" deleted.')),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(
        isActive ? Icons.play_circle : Icons.shopping_bag_outlined,
        color: isActive ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(session.name),
      subtitle: Text(
        [
          if (isActive) 'Showing in Feed',
          _summary,
        ].where((part) => part.isNotEmpty).join(' · '),
      ),
      onTap: onResume,
      trailing: PopupMenuButton<_SessionAction>(
        tooltip: 'Session options',
        onSelected: (action) => _act(context, ref, action),
        itemBuilder: (_) => const [
          PopupMenuItem(value: _SessionAction.edit, child: Text('Edit')),
          PopupMenuItem(value: _SessionAction.rename, child: Text('Rename')),
          PopupMenuItem(value: _SessionAction.reset, child: Text('Reset')),
          PopupMenuItem(value: _SessionAction.delete, child: Text('Delete')),
        ],
      ),
    );
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.name});

  final String name;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.name);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename session'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Name'),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Rename'),
        ),
      ],
    );
  }
}
