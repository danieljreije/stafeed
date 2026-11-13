import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/features/feed/models/feed_item.dart';
import 'package:stafeed/app/features/feed/models/media.dart';

import '../support/scripted_data_gateway.dart';

/// Names a Feed Item's kind. It only compiles while it covers every kind, so
/// a new kind can't be added without deciding how it is labelled.
String kindOf(FeedItem item) => switch (item) {
  AffiliateAd() => 'Affiliate Ad',
  BrandAd() => 'Brand Ad',
  NotAnAd() => 'Not an Ad',
};

void main() {
  group('Affiliate Ad', () {
    test('is an Ad for one Product with one Offer, and not Sponsored', () {
      final item = feedItem('a');

      expect(kindOf(item), 'Affiliate Ad');
      expect(item.isAd, isTrue);
      expect(item.isSponsored, isFalse);
      expect(item.id, item.product.id);
      expect(item.products, [item.product]);
      expect(item.offer, same(item.product.offers.single));
    });

    test("its media are the Product's images, in order", () {
      final item = feedItem(
        'a',
        imageUrls: ['https://example.com/1.jpg', 'https://example.com/2.jpg'],
      );

      expect(item.media, const [
        ImageMedia('https://example.com/1.jpg'),
        ImageMedia('https://example.com/2.jpg'),
      ]);
    });

    test('refuses an Offer that earns Stafeed nothing', () {
      final earnsNothing = notAnAd('a');

      expect(
        () => AffiliateAd(
          product: earnsNothing.product,
          offer: earnsNothing.offer,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Not an Ad', () {
    test('is not an Ad and not Sponsored', () {
      final item = notAnAd('n');

      expect(kindOf(item), 'Not an Ad');
      expect(item.isAd, isFalse);
      expect(item.isSponsored, isFalse);
      expect(item.id, item.product.id);
      expect(item.products, [item.product]);
    });

    test('refuses an Offer that earns Stafeed money', () {
      final earns = feedItem('a');

      expect(
        () => NotAnAd(product: earns.product, offer: earns.offer),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Brand Ad', () {
    test('is an Ad, always Sponsored, linked to its Products', () {
      final linked = [sampleProduct('p1'), sampleProduct('p2')];
      final item = brandAd('b', products: linked);

      expect(kindOf(item), 'Brand Ad');
      expect(item.isAd, isTrue);
      expect(item.isSponsored, isTrue);
      expect(item.id, 'b');
      expect(item.products, linked);
    });

    test('its media list can hold images and video', () {
      final item = brandAd(
        'b',
        media: const [
          ImageMedia('https://example.com/1.jpg'),
          VideoMedia(
            'https://example.com/clip.mp4',
            posterUrl: 'https://example.com/poster.jpg',
          ),
          VideoMedia('https://example.com/no-poster.mp4'),
        ],
      );

      expect(item.media, hasLength(3));
      expect(item.media[0], isA<ImageMedia>());
      final video = item.media[1] as VideoMedia;
      expect(video.url, 'https://example.com/clip.mp4');
      expect(video.posterUrl, 'https://example.com/poster.jpg');
      expect((item.media[2] as VideoMedia).posterUrl, isNull);
    });
  });
}
