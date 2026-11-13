// What each kind of Feed Item shows: its labels, a Brand Ad's Product chips,
// and the media carousel (ticket #4).
//
// Photos can't load in widget tests (every request is answered with an
// error), so each picture shows its error fallback here.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:stafeed/app/features/feed/data/fixtures/fixture_brand_ads.dart';
import 'package:stafeed/app/features/feed/feed_screen.dart';
import 'package:stafeed/app/features/feed/models/feed_item.dart';
import 'package:stafeed/app/features/feed/models/media.dart';
import 'package:stafeed/app/features/feed/models/product.dart';
import 'package:stafeed/app/features/feed/providers/data_gateway_provider.dart';
import 'package:stafeed/app/features/feed/widgets/brand_ad_card.dart';
import 'package:stafeed/app/features/feed/widgets/media_carousel.dart';
import 'package:stafeed/app/features/feed/widgets/product_card.dart';

import '../support/scripted_data_gateway.dart';

const adLabel = 'AD';
const sponsoredLabel = 'Sponsored';
const affiliateNote = 'Stafeed may earn a commission';
const notAnAdLabel = 'NOT AN AD';
const notAnAdNote = 'Stafeed earns nothing on this one';

Future<void> pumpCard(WidgetTester tester, Widget card) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: card)));
  await tester.pumpAndSettle();
}

Future<void> pumpProductCard(WidgetTester tester, ProductFeedItem item) =>
    pumpCard(
      tester,
      ProductCard(item: item, isSaved: false, onSaveToggle: () {}),
    );

/// The AD label is there, in bold, and at least as big as the text around it.
void expectBoldAdLabel(WidgetTester tester) {
  expect(find.text(adLabel), findsOneWidget);

  final style = tester.widget<Text>(find.text(adLabel)).style!;
  expect(style.fontWeight!.value, greaterThanOrEqualTo(FontWeight.bold.value));
  expect(style.fontSize, greaterThanOrEqualTo(14));
}

void main() {
  group('Affiliate Ad', () {
    testWidgets('shows a bold AD label and the commission note', (
      tester,
    ) async {
      await pumpProductCard(tester, feedItem('a'));

      expectBoldAdLabel(tester);
      expect(find.text(affiliateNote), findsOneWidget);
    });

    testWidgets('is not labelled Sponsored or Not an Ad', (tester) async {
      await pumpProductCard(tester, feedItem('a'));

      expect(find.text(sponsoredLabel), findsNothing);
      expect(find.text(notAnAdLabel), findsNothing);
      expect(find.text(notAnAdNote), findsNothing);
    });

    testWidgets('still shows the Product, its Merchant and price', (
      tester,
    ) async {
      final item = feedItem('a');

      await pumpProductCard(tester, item);

      expect(find.text(item.product.title), findsOneWidget);
      expect(find.textContaining(item.offer.merchant), findsOneWidget);
      expect(find.text(item.offer.price.format()), findsOneWidget);
    });
  });

  group('Not an Ad', () {
    testWidgets('shows the Not an Ad label and its honest note', (
      tester,
    ) async {
      await pumpProductCard(tester, notAnAd('n'));

      expect(find.text(notAnAdLabel), findsOneWidget);
      expect(find.text(notAnAdNote), findsOneWidget);
    });

    testWidgets('has no AD label, no Sponsored and no commission note', (
      tester,
    ) async {
      await pumpProductCard(tester, notAnAd('n'));

      expect(find.text(adLabel), findsNothing);
      expect(find.text(sponsoredLabel), findsNothing);
      expect(find.text(affiliateNote), findsNothing);
    });
  });

  group('Brand Ad', () {
    final linked = [sampleProduct('p1'), sampleProduct('p2')];

    testWidgets('shows a bold AD label and Sponsored', (tester) async {
      final ad = brandAd('b', products: linked);

      await pumpCard(tester, BrandAdCard(ad: ad, onProductTap: (_) {}));

      expectBoldAdLabel(tester);
      expect(find.text(sponsoredLabel), findsOneWidget);
      expect(find.text(ad.brand), findsOneWidget);
      expect(find.text(ad.headline), findsOneWidget);
    });

    testWidgets('has no commission note and no Not an Ad label', (
      tester,
    ) async {
      await pumpCard(
        tester,
        BrandAdCard(
          ad: brandAd('b', products: linked),
          onProductTap: (_) {},
        ),
      );

      expect(find.text(affiliateNote), findsNothing);
      expect(find.text(notAnAdLabel), findsNothing);
    });

    testWidgets('shows one chip per linked Product', (tester) async {
      await pumpCard(
        tester,
        BrandAdCard(
          ad: brandAd('b', products: linked),
          onProductTap: (_) {},
        ),
      );

      expect(find.byType(ActionChip), findsNWidgets(2));
      for (final product in linked) {
        expect(find.widgetWithText(ActionChip, product.title), findsOneWidget);
      }
    });

    testWidgets('tapping a chip identifies that Product', (tester) async {
      final tapped = <Product>[];
      await pumpCard(
        tester,
        BrandAdCard(
          ad: brandAd('b', products: linked),
          onProductTap: tapped.add,
        ),
      );

      await tester.tap(find.widgetWithText(ActionChip, linked[1].title));
      await tester.pump();

      expect(tapped, [linked[1]]);

      await tester.tap(find.widgetWithText(ActionChip, linked[0].title));
      await tester.pump();

      expect(tapped, [linked[1], linked[0]]);
    });

    testWidgets('with no linked Products shows no chips', (tester) async {
      await pumpCard(
        tester,
        BrandAdCard(ad: brandAd('b'), onProductTap: (_) {}),
      );

      expect(find.byType(ActionChip), findsNothing);
      expectBoldAdLabel(tester);
    });
  });

  group('Media carousel', () {
    const threeImages = [
      ImageMedia('https://example.com/1.jpg'),
      ImageMedia('https://example.com/2.jpg'),
      ImageMedia('https://example.com/3.jpg'),
    ];

    Future<void> pumpCarousel(WidgetTester tester, List<Media> media) =>
        pumpCard(tester, MediaCarousel(media: media));

    testWidgets('swipes sideways through several images', (tester) async {
      await pumpCarousel(tester, threeImages);

      expect(find.bySemanticsLabel('Image 1 of 3'), findsOneWidget);

      await tester.drag(find.byType(MediaCarousel), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Image 2 of 3'), findsOneWidget);

      await tester.drag(find.byType(MediaCarousel), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Image 3 of 3'), findsOneWidget);
    });

    testWidgets('a single image has no position marker', (tester) async {
      await pumpCarousel(tester, const [
        ImageMedia('https://example.com/1.jpg'),
      ]);

      expect(
        find.bySemanticsLabel(RegExp(r'^Image \d+ of \d+$')),
        findsNothing,
      );
    });

    testWidgets('an image that fails to load shows the fallback, not an '
        'error', (tester) async {
      await pumpCarousel(tester, threeImages);

      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no media at all shows the no-image fallback', (tester) async {
      await pumpCarousel(tester, const []);

      expect(find.byIcon(Icons.image_not_supported_outlined), findsOneWidget);
    });

    testWidgets('a video is not played: its poster image stands in', (
      tester,
    ) async {
      await pumpCarousel(tester, const [
        VideoMedia(
          'https://example.com/clip.mp4',
          posterUrl: 'https://example.com/poster.jpg',
        ),
      ]);

      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as NetworkImage).url,
        'https://example.com/poster.jpg',
      );
    });

    testWidgets('a video without a poster shows a video placeholder', (
      tester,
    ) async {
      await pumpCarousel(tester, const [
        VideoMedia('https://example.com/clip.mp4'),
      ]);

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.videocam_outlined), findsOneWidget);
    });

    testWidgets("an Affiliate Ad's card swipes through the Product's images", (
      tester,
    ) async {
      await pumpProductCard(
        tester,
        feedItem(
          'a',
          imageUrls: ['https://example.com/1.jpg', 'https://example.com/2.jpg'],
        ),
      );

      expect(find.bySemanticsLabel('Image 1 of 2'), findsOneWidget);

      await tester.drag(find.byType(MediaCarousel), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Image 2 of 2'), findsOneWidget);
    });

    testWidgets("a Brand Ad's card swipes through its media", (tester) async {
      await pumpCard(
        tester,
        BrandAdCard(
          ad: brandAd('b', media: threeImages),
          onProductTap: (_) {},
        ),
      );

      expect(find.bySemanticsLabel('Image 1 of 3'), findsOneWidget);

      await tester.drag(find.byType(MediaCarousel), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Image 2 of 3'), findsOneWidget);
    });
  });

  group('In the feed', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
    });

    /// Opens the feed on a first page holding [items].
    Future<void> pumpFeedWith(WidgetTester tester, List<FeedItem> items) async {
      final gateway = ScriptedDataGateway();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dataGatewayProvider.overrideWithValue(gateway)],
          child: const MaterialApp(home: FeedScreen()),
        ),
      );
      await tester.pump();
      gateway.requests.single.succeed(items);
      await tester.pumpAndSettle();
    }

    testWidgets('each kind gets its own labels as the Shopper swipes', (
      tester,
    ) async {
      await pumpFeedWith(tester, [
        feedItem('a'),
        brandAd('b', products: [sampleProduct('p1')]),
        notAnAd('n'),
      ]);

      expect(find.text(adLabel), findsOneWidget);
      expect(find.text(affiliateNote), findsOneWidget);

      await tester.drag(find.byType(PageView).first, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text(adLabel), findsOneWidget);
      expect(find.text(sponsoredLabel), findsOneWidget);
      expect(find.text(affiliateNote), findsNothing);
      expect(find.widgetWithText(ActionChip, 'Product p1'), findsOneWidget);

      await tester.drag(find.byType(PageView).first, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text(notAnAdLabel), findsOneWidget);
      expect(find.text(adLabel), findsNothing);
    });

    testWidgets("tapping a Brand Ad's chip names that Product", (tester) async {
      await pumpFeedWith(tester, [
        brandAd('b', products: [sampleProduct('p1'), sampleProduct('p2')]),
      ]);

      await tester.tap(find.widgetWithText(ActionChip, 'Product p2'));
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.textContaining('Product p2'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a Brand Ad has no Save button', (tester) async {
      await pumpFeedWith(tester, [brandAd('b')]);

      expect(find.byIcon(Icons.favorite_border), findsNothing);
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('every Fixture Brand Ad fits a phone screen, labels and chips '
        'clear of the search box and chips', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      for (final ad in fixtureBrandAds) {
        await pumpFeedWith(tester, [ad]);

        expect(tester.takeException(), isNull, reason: ad.id);

        final controlsBottom = tester
            .getRect(find.textContaining('Sample data'))
            .bottom;
        expect(
          tester.getRect(find.text(adLabel)).top,
          greaterThan(controlsBottom),
          reason: ad.id,
        );
        for (final product in ad.products) {
          final chip = find.widgetWithText(ActionChip, product.title);
          expect(chip, findsOneWidget, reason: ad.id);
          expect(tester.getRect(chip).bottom, lessThan(844), reason: ad.id);
        }

        // A fresh screen for the next ad.
        await tester.pumpWidget(const SizedBox());
      }
    });
  });
}
