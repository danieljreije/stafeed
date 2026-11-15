// Fixtures: hand-made sample Brand Ads for offline development and tests.
// They are NOT real ads. No Brand supplied or paid for them; the Brands are
// invented and the pictures are sample pictures drawn by the app.

import '../../models/feed_item.dart';
import '../../models/media.dart';
import '../../models/product.dart';
import '../../models/sample_art.dart';
import 'fixture_products.dart';

Product _product(String id) =>
    fixtureProducts.firstWhere((product) => product.id == 'fixture-$id');

List<Media> _images(String id, int count, {required String category}) => [
  for (var i = 1; i <= count; i++)
    ImageMedia(sampleArtUrl(category, 'brand-ad-$id-$i')),
];

/// Image-only for now; video Brand Ads arrive with video playback.
final List<BrandAd> fixtureBrandAds = [
  BrandAd(
    id: 'fixture-brand-ad-northstar',
    brand: 'Northstar',
    headline: 'Lace up. The sample run club leaves at dawn.',
    media: _images('northstar', 3, category: 'sneakers'),
    products: [_product('snk-01'), _product('snk-04')],
  ),
  BrandAd(
    id: 'fixture-brand-ad-orbitline',
    brand: 'Orbitline',
    headline: 'Pack light, charge fast, pretend this ad is real.',
    media: _images('orbitline', 2, category: 'bags'),
    products: [_product('bag-01'), _product('bag-05'), _product('tec-01')],
  ),
  BrandAd(
    id: 'fixture-brand-ad-brightmoor',
    brand: 'Brightmoor',
    headline: 'Your living room called. It wants better lighting.',
    media: _images('brightmoor', 1, category: 'home-decor'),
    products: [_product('hom-03'), _product('hom-06')],
  ),
];
