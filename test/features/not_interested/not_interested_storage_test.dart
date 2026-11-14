import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stafeed/app/features/not_interested/data/not_interested_storage.dart';
import 'package:stafeed/app/features/not_interested/providers/not_interested_provider.dart';

import '../../support/shopper.dart';

void main() {
  setUp(useEmptyDeviceStorage);

  ProviderContainer launch() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test('nothing is hidden on a new phone', () async {
    expect(await launch().read(notInterestedProvider.future), isEmpty);
  });

  test('a mark is kept across a restart', () async {
    await launch().read(notInterestedProvider.notifier).mark('p1');
    await launch().read(notInterestedProvider.notifier).mark('p2');

    expect(await launch().read(notInterestedProvider.future), {'p1', 'p2'});
    expect(await NotInterestedStorage().load(), {'p1', 'p2'});
  });

  test(
    'a mark made while the stored ones are still being read keeps them',
    () async {
      await NotInterestedStorage().save({'p1'});
      final container = launch();

      await container.read(notInterestedProvider.notifier).mark('p2');

      expect(container.read(notInterestedProvider).value, {'p1', 'p2'});
      expect(await NotInterestedStorage().load(), {'p1', 'p2'});
    },
  );

  test('unreadable storage hides nothing instead of failing', () async {
    await SharedPreferencesAsync().setString(
      'not_interested_products',
      '{not json',
    );

    expect(await launch().read(notInterestedProvider.future), isEmpty);
  });
}
