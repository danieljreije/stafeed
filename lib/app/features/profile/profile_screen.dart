import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../events/models/event.dart';
import '../events/providers/events_provider.dart';
import '../feed/models/supported_filters.dart';
import '../feed/providers/data_gateway_provider.dart';
import '../shopper/providers/shopper_config_provider.dart';

/// The Profile tab: how many Ads the Shopper watched this week, what they
/// chose at onboarding and the debug Events screen. Changing the choices,
/// settings and history arrive with #13.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(shopperConfigProvider).asData?.value;
    final adsWatched = ref.watch(adsWatchedThisWeekProvider);
    final categories =
        ref.watch(supportedFiltersProvider).asData?.value.categories ??
        const <ProductCategory>[];

    String label(String categoryId) {
      for (final category in categories) {
        if (category.id == categoryId) return category.label;
      }
      return categoryId;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: config == null
          ? const SizedBox.shrink()
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    adsWatchedLine(adsWatched),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.local_shipping_outlined),
                  title: const Text('Destination Country'),
                  subtitle: Text(config.destinationCountry.label),
                ),
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text('Currency'),
                  subtitle: Text(config.currencyCode),
                ),
                ListTile(
                  leading: const Icon(Icons.interests_outlined),
                  title: const Text('Interests'),
                  subtitle: Text(
                    config.interests.isEmpty
                        ? 'None picked'
                        : config.interests.map(label).join(', '),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: const Text('Events (debug)'),
                  subtitle: const Text('What this phone has recorded'),
                  onTap: () => context.push(AppRoutes.events),
                ),
              ],
            ),
    );
  }
}
