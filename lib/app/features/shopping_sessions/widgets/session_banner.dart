import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../feed/models/money.dart';
import '../models/shopping_session.dart';
import '../providers/shopping_sessions_provider.dart';

/// Shows on top of the feed while a Shopping Session is active:
/// "Session: (name) ✕". The ✕ goes back to For You.
class SessionBanner extends ConsumerWidget {
  const SessionBanner({super.key, required this.session});

  final ShoppingSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Session: ${session.name}',
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Back to For You',
              icon: const Icon(Icons.close),
              color: theme.colorScheme.onPrimaryContainer,
              onPressed: () =>
                  ref.read(shoppingSessionsProvider.notifier).end(),
            ),
          ],
        ),
      ),
    );
  }
}

/// A Shopping Session's feed with nothing in it: says why, and offers the
/// changes most likely to bring results back.
class SessionNoResults extends ConsumerWidget {
  const SessionNoResults({super.key, required this.session});

  final ShoppingSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.read(shoppingSessionsProvider.notifier);

    void change({
      String? goal,
      String? Function()? category,
      String? Function()? brand,
      Money? Function()? maxPrice,
    }) {
      final changed = session.copyWith(
        goal: goal,
        category: category,
        brand: brand,
        maxPrice: maxPrice,
      );
      sessions.changeFilters(
        session.id,
        goal: changed.goal,
        category: changed.category,
        brand: changed.brand,
        maxPrice: changed.maxPrice,
      );
    }

    final budget = session.maxPrice;
    final raised = budget == null ? null : _raise(budget);
    final suggestions = [
      if (raised != null)
        OutlinedButton(
          onPressed: () => change(maxPrice: () => raised),
          child: Text('Raise budget to ${raised.format()}'),
        ),
      if (session.brand != null)
        OutlinedButton(
          onPressed: () => change(brand: () => null),
          child: const Text('Any Brand'),
        ),
      if (session.category != null)
        OutlinedButton(
          onPressed: () => change(category: () => null),
          child: const Text('Any category'),
        ),
      if (session.goal.isNotEmpty)
        OutlinedButton(
          onPressed: () => change(goal: ''),
          child: Text('Drop "${session.goal}"'),
        ),
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nothing matches this session',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              suggestions.isEmpty ? 'Try again later.' : 'Try one of these:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: suggestions,
            ),
          ],
        ),
      ),
    );
  }

  /// Half as much again, rounded up to a whole unit.
  static Money _raise(Money budget) {
    final raised = (budget.minorUnits * 3 + 1) ~/ 2;
    final whole = ((raised + 99) ~/ 100) * 100;
    return Money(whole, budget.currencyCode);
  }
}
