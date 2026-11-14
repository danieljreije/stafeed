import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/features/feed/data/fixtures/fixture_brand_ads.dart';
import 'package:stafeed/app/features/feed/data/fixtures/fixture_products.dart';
import 'package:stafeed/app/features/feed/models/media.dart';

/// The backend's Fixture source (#15) serves a copy of the app's Fixtures
/// from this file. If you change the app's Fixtures, change it too, so the
/// app on Fixtures and the backend on Fixtures show the same catalog.
const _serverFixtures = 'supabase/functions/_shared/fixtures/fixtures.json';

Map<String, Object?> _media(Media media) => switch (media) {
  ImageMedia(:final url) => {'kind': 'image', 'url': url},
  VideoMedia(:final url, :final posterUrl) => {
    'kind': 'video',
    'url': url,
    'posterUrl': ?posterUrl,
  },
};

Map<String, Object?> _appFixtures() => {
  'categories': [
    for (final category in fixtureCategories)
      {'id': category.id, 'label': category.label},
  ],
  'products': [
    for (final product in fixtureProducts)
      {
        'id': product.id,
        'title': product.title,
        'description': product.description,
        'brand': product.brand,
        'category': product.category,
        'attributes': product.attributes,
        'media': [for (final url in product.imageUrls) _media(ImageMedia(url))],
        'offers': [
          for (final offer in product.offers)
            {
              'id': offer.id,
              'merchant': offer.merchant,
              'price': {
                'minorUnits': offer.price.minorUnits,
                'currency': offer.price.currencyCode,
              },
              'shipsTo': offer.shipsTo.toList(),
              'url': offer.url.toString(),
              'monetisation': offer.isAffiliate ? 'affiliate' : 'none',
              'availability': offer.isAvailable ? 'in_stock' : 'out_of_stock',
            },
        ],
      },
  ],
  'brandAds': [
    for (final brandAd in fixtureBrandAds)
      {
        'id': brandAd.id,
        'brand': brandAd.brand,
        'headline': brandAd.headline,
        'media': [for (final media in brandAd.media) _media(media)],
        'productIds': [for (final product in brandAd.products) product.id],
      },
  ],
};

void main() {
  test('the backend serves the same Fixtures as the app', () {
    final server = jsonDecode(File(_serverFixtures).readAsStringSync());

    // Round-trip through JSON so both sides compare as plain maps and lists.
    final app = jsonDecode(jsonEncode(_appFixtures()));

    expect(server, app);
  });
}
