// Golden (screenshot) tests for the feed (ticket #35).
//
// Each test drives the whole app (StafeedApp, starting at Home) on Fixtures
// through the data gateway seam, then compares the screen to a saved image
// under test/goldens/goldens/.
//
// Golden images are only made and compared on Linux (GitHub's CI machines),
// because text renders slightly differently on Windows and macOS. Elsewhere
// these tests are skipped, so `flutter test` still passes on any PC.
//
// To update the images after an intended UI change, run the "Update goldens"
// workflow on your PR branch (see PROJECT_STATUS.md), or on Linux:
//   flutter test --tags golden --update-goldens
@Tags(['golden'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:stafeed/app/features/feed/data/data_gateway.dart';
import 'package:stafeed/app/features/feed/data/fixture_data_gateway.dart';
import 'package:stafeed/app/features/feed/models/feed_filter.dart';
import 'package:stafeed/app/features/feed/models/feed_item.dart';
import 'package:stafeed/app/features/feed/models/feed_page.dart';
import 'package:stafeed/app/features/feed/models/supported_filters.dart';
import 'package:stafeed/app/features/feed/providers/data_gateway_provider.dart';
import 'package:stafeed/main.dart';

/// Goldens only run on Linux; see the note at the top of this file.
final bool _isLinux = Platform.isLinux;

/// A phone-sized screen, kept small so the images stay light.
const _screenSize = Size(390, 844);

/// One golden per Feed Item kind the app shows today. Add a row here when a
/// new kind arrives (Brand Ad, Not an Ad, ...).
final _feedItemKinds = <String, bool Function(FeedItem)>{
  'affiliate_ad': (item) => item.isAd,
};

void main() {
  setUpAll(() async {
    if (_isLinux) await _loadRealFonts();
  });

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('Feed Item kinds', () {
    for (final MapEntry(key: name, value: isKind) in _feedItemKinds.entries) {
      testWidgets(name, skip: !_isLinux, (tester) async {
        final item = (await FixtureDataGateway().getFeedPage()).items
            .firstWhere(isKind);

        await _openFeed(
          tester,
          _FakeGateway(
            page: Future.value(FeedPage(items: [item], nextCursor: null)),
          ),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/feed_item_$name.png'),
        );
      });
    }
  });

  group('Feed states', () {
    testWidgets('loading', skip: !_isLinux, (tester) async {
      final gateway = _FakeGateway(page: Completer<FeedPage>().future);

      await _openFeed(tester, gateway);
      // The spinner never stops, so step the clock instead of settling.
      await tester.pump(const Duration(milliseconds: 500));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/feed_state_loading.png'),
      );
    });

    testWidgets('empty', skip: !_isLinux, (tester) async {
      final gateway = _FakeGateway(
        page: Future.value(const FeedPage(items: [], nextCursor: null)),
      );

      await _openFeed(tester, gateway);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/feed_state_empty.png'),
      );
    });

    testWidgets('error', skip: !_isLinux, (tester) async {
      final gateway = _FakeGateway(
        page: Future.error(Exception('Sample outage')),
      );

      await _openFeed(tester, gateway);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/feed_state_error.png'),
      );
    });
  });
}

/// Starts the real app on [gateway] and taps through Home into the feed.
Future<void> _openFeed(WidgetTester tester, DataGateway gateway) async {
  tester.view.physicalSize = _screenSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [dataGatewayProvider.overrideWithValue(gateway)],
      child: const StafeedApp(),
    ),
  );
  await tester.tap(find.text('Start Exploring'));
  // Let the page transition finish without waiting on endless spinners.
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

/// Fixtures' real category chips, but the feed page is whatever [page] gives:
/// one chosen Feed Item, or the feed's loading, empty or error state.
class _FakeGateway implements DataGateway {
  _FakeGateway({required this.page}) {
    // A failing page must not count as an unhandled error before the feed
    // listens to it.
    page.ignore();
  }

  final Future<FeedPage> page;
  final _fixtures = FixtureDataGateway();

  @override
  bool get servesSampleData => true;

  @override
  Future<FeedPage> getFeedPage({
    FeedFilter filter = const FeedFilter(),
    FeedCursor? cursor,
  }) => page;

  @override
  Future<SupportedFilters> getSupportedFilters() =>
      _fixtures.getSupportedFilters();
}

/// Tests draw text with a blocky placeholder font by default. Load real
/// Roboto and Material Icons (copied from the Flutter SDK into
/// test/goldens/fonts, with their licence files) so the
/// images look like the app and a broken layout is easy to spot.
Future<void> _loadRealFonts() async {
  Future<ByteData> read(String name) async => ByteData.sublistView(
    await File('test/goldens/fonts/$name').readAsBytes(),
  );

  final roboto = FontLoader('Roboto');
  for (final weight in ['regular', 'medium', 'bold']) {
    roboto.addFont(read('roboto-$weight.ttf'));
  }
  await roboto.load();

  await (FontLoader(
    'MaterialIcons',
  )..addFont(read('materialicons-regular.otf'))).load();
}
