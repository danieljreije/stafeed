import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../feed/models/supported_filters.dart';
import '../feed/providers/data_gateway_provider.dart';
import '../shopper/providers/shopper_config_provider.dart';

/// The Profile tab. For now it shows what the Shopper chose at onboarding;
/// changing it, settings and history arrive with #13.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(shopperConfigProvider).asData?.value;
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
              ],
            ),
    );
  }
}
