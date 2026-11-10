// Fixtures: hand-made sample Products for offline development and tests.
// They are NOT real commercial inventory. Brands, Merchants, prices and links
// are invented; links point at example.com and images are random stock
// photos from picsum.photos.

import '../../models/money.dart';
import '../../models/offer.dart';
import '../../models/product.dart';
import '../../models/supported_filters.dart';

const fixtureCategories = [
  ProductCategory(id: 'sneakers', label: 'Sneakers'),
  ProductCategory(id: 'bags', label: 'Bags'),
  ProductCategory(id: 'watches', label: 'Watches'),
  ProductCategory(id: 'tech-accessories', label: 'Tech accessories'),
  ProductCategory(id: 'home-decor', label: 'Home decor'),
];

const _us = {'US'};
const _usUk = {'US', 'GB'};
const _uk = {'GB'};
const _gulf = {'AE', 'LB'};
const _everywhere = {'US', 'GB', 'AE', 'LB'};

// Invented Merchants.
const _sampleOutfitters = 'Sample Outfitters';
const _demoStreet = 'Demo Street Store';
const _fixtureGoods = 'Fixture Goods Co';
const _testbedHome = 'Testbed Home';
const _catalogSample = 'Catalog Sample Store';

Product _fixture(
  String id,
  String title,
  String brand,
  String category,
  int price, {
  required String merchant,
  String currency = 'USD',
  Set<String> shipsTo = _everywhere,
  String? style,
  bool isAd = true,
  bool isAvailable = true,
}) {
  return Product(
    id: 'fixture-$id',
    title: title,
    description:
        '$title by $brand. Sample product for testing; not real inventory.',
    brand: brand,
    category: category,
    attributes: {if (style != null) 'style': style},
    imageUrls: ['https://picsum.photos/seed/stafeed-$id/800/1200'],
    offers: [
      Offer(
        id: 'fixture-offer-$id',
        merchant: merchant,
        price: Money(price, currency),
        shipsTo: shipsTo,
        url: Uri.https('example.com', '/sample/$id'),
        isAffiliate: isAd,
        isAvailable: isAvailable,
      ),
    ],
  );
}

final List<Product> fixtureProducts = [
  // Sneakers: running.
  _fixture('snk-01', 'Air Runner', 'Northstar', 'sneakers', 12900,
      merchant: _sampleOutfitters, style: 'Running'),
  _fixture('snk-02', 'Tempo Glide', 'Kestrel', 'sneakers', 14500,
      merchant: _sampleOutfitters, style: 'Running', shipsTo: _usUk),
  _fixture('snk-03', 'Long Mile 3', 'Tidewell', 'sneakers', 11000,
      merchant: _demoStreet, currency: 'GBP', style: 'Running',
      shipsTo: _uk),
  _fixture('snk-04', 'Pace Lite', 'Northstar', 'sneakers', 9900,
      merchant: _fixtureGoods, style: 'Running', shipsTo: _us),
  _fixture('snk-05', 'Trail Spark', 'Halden', 'sneakers', 13500,
      merchant: _sampleOutfitters, style: 'Running'),
  _fixture('snk-06', 'Cloud Stride', 'Kestrel', 'sneakers', 15900,
      merchant: _catalogSample, style: 'Running', isAd: false),

  // Sneakers: casual.
  _fixture('snk-07', 'Street Classic', 'Ferrovia', 'sneakers', 8900,
      merchant: _sampleOutfitters, style: 'Casual'),
  _fixture('snk-08', 'White Court Low', 'Halden', 'sneakers', 9500,
      merchant: _demoStreet, currency: 'GBP', style: 'Casual',
      shipsTo: _usUk),
  _fixture('snk-09', 'Canvas Daybreak', 'Saltmarsh', 'sneakers', 6500,
      merchant: _fixtureGoods, style: 'Casual', shipsTo: _gulf),
  _fixture('snk-10', 'Suede Slip-On', 'Ferrovia', 'sneakers', 7900,
      merchant: _sampleOutfitters, style: 'Casual'),
  _fixture('snk-11', 'Retro Court 84', 'Northstar', 'sneakers', 11900,
      merchant: _demoStreet, currency: 'GBP', style: 'Casual',
      shipsTo: _uk),
  _fixture('snk-12', 'Weekend Knit', 'Tidewell', 'sneakers', 8500,
      merchant: _sampleOutfitters, style: 'Casual', shipsTo: _us),

  // Sneakers: basketball.
  _fixture('snk-13', 'Hangtime High', 'Kestrel', 'sneakers', 17900,
      merchant: _sampleOutfitters, style: 'Basketball'),
  _fixture('snk-14', 'Baseline Pro', 'Halden', 'sneakers', 16500,
      merchant: _fixtureGoods, style: 'Basketball', shipsTo: _usUk),
  _fixture('snk-15', 'Fast Break Mid', 'Ferrovia', 'sneakers', 13900,
      merchant: _sampleOutfitters, style: 'Basketball'),
  _fixture('snk-16', 'Rim Rocker', 'Northstar', 'sneakers', 14900,
      merchant: _demoStreet, currency: 'GBP', style: 'Basketball',
      shipsTo: _uk),
  _fixture('snk-17', 'Crossover Low', 'Saltmarsh', 'sneakers', 12500,
      merchant: _fixtureGoods, style: 'Basketball', shipsTo: _gulf),
  _fixture('snk-18', 'Full Court 2', 'Kestrel', 'sneakers', 18900,
      merchant: _catalogSample, style: 'Basketball', isAd: false),

  // Sneakers: boots.
  _fixture('snk-19', 'Ridge Boot', 'Tidewell', 'sneakers', 19900,
      merchant: _sampleOutfitters, style: 'Boots'),
  _fixture('snk-20', 'Urban Hiker', 'Halden', 'sneakers', 17500,
      merchant: _demoStreet, currency: 'GBP', style: 'Boots',
      shipsTo: _usUk),
  _fixture('snk-21', 'Chelsea Sneakboot', 'Ferrovia', 'sneakers', 15500,
      merchant: _fixtureGoods, style: 'Boots'),
  _fixture('snk-22', 'Snowline Mid', 'Saltmarsh', 'sneakers', 21900,
      merchant: _sampleOutfitters, style: 'Boots', shipsTo: _us),
  _fixture('snk-23', 'Desert Lace-Up', 'Northstar', 'sneakers', 13900,
      merchant: _fixtureGoods, style: 'Boots', shipsTo: _gulf),
  _fixture('snk-24', 'Workday Boot', 'Tidewell', 'sneakers', 16900,
      merchant: _demoStreet, currency: 'GBP', style: 'Boots',
      shipsTo: _uk),

  // Bags.
  _fixture('bag-01', 'Everyday Tote', 'Orbitline', 'bags', 6900,
      merchant: _sampleOutfitters),
  _fixture('bag-02', 'Commuter Backpack', 'Halden', 'bags', 11900,
      merchant: _demoStreet, currency: 'GBP', shipsTo: _usUk),
  _fixture('bag-03', 'Mini Crossbody', 'Lumenhaus', 'bags', 5900,
      merchant: _fixtureGoods, shipsTo: _gulf),
  _fixture('bag-04', 'Weekender Duffel', 'Saltmarsh', 'bags', 14900,
      merchant: _sampleOutfitters),
  _fixture('bag-05', 'Laptop Sleeve 14"', 'Orbitline', 'bags', 4500,
      merchant: _fixtureGoods, shipsTo: _us),
  _fixture('bag-06', 'Canvas Messenger', 'Ferrovia', 'bags', 7900,
      merchant: _demoStreet, currency: 'GBP', shipsTo: _uk),
  _fixture('bag-07', 'Roll-Top Pack', 'Tidewell', 'bags', 9900,
      merchant: _sampleOutfitters),
  _fixture('bag-08', 'Leather Belt Bag', 'Lumenhaus', 'bags', 8500,
      merchant: _catalogSample, isAd: false),

  // Watches.
  _fixture('wat-01', 'Field Automatic', 'Quillon', 'watches', 34900,
      merchant: _sampleOutfitters),
  _fixture('wat-02', 'Minimal Mesh 38', 'Brightmoor', 'watches', 12900,
      merchant: _demoStreet, currency: 'GBP', shipsTo: _usUk),
  _fixture('wat-03', 'Dive 200', 'Quillon', 'watches', 42900,
      merchant: _fixtureGoods),
  _fixture('wat-04', 'Chrono Sport', 'Kestrel', 'watches', 22900,
      merchant: _sampleOutfitters, shipsTo: _us),
  _fixture('wat-05', 'Pocket Square Dial', 'Brightmoor', 'watches', 15900,
      merchant: _fixtureGoods, shipsTo: _gulf),
  _fixture('wat-06', 'Solar Field', 'Quillon', 'watches', 27500,
      merchant: _demoStreet, currency: 'GBP', shipsTo: _uk),
  _fixture('wat-07', 'Smart Band Lite', 'Orbitline', 'watches', 7900,
      merchant: _sampleOutfitters),
  _fixture('wat-08', 'GMT Traveller', 'Brightmoor', 'watches', 129900,
      merchant: _sampleOutfitters, isAvailable: false),

  // Tech accessories.
  _fixture('tec-01', 'Wireless Earbuds', 'Orbitline', 'tech-accessories',
      8900,
      merchant: _sampleOutfitters),
  _fixture('tec-02', 'Fast Charger 65W', 'Lumenhaus', 'tech-accessories',
      4900,
      merchant: _fixtureGoods, shipsTo: _usUk),
  _fixture('tec-03', 'Magnetic Power Bank', 'Orbitline', 'tech-accessories',
      5900,
      merchant: _demoStreet, currency: 'GBP', shipsTo: _uk),
  _fixture('tec-04', 'Mechanical Keyboard', 'Quillon', 'tech-accessories',
      13900,
      merchant: _sampleOutfitters),
  _fixture('tec-05', 'Phone Grip Stand', 'Brightmoor', 'tech-accessories',
      1900,
      merchant: _fixtureGoods, shipsTo: _gulf),
  _fixture('tec-06', 'Noise-Cancelling Headphones', 'Orbitline',
      'tech-accessories', 24900,
      merchant: _sampleOutfitters, shipsTo: _us),
  _fixture('tec-07', 'USB-C Hub 7-in-1', 'Lumenhaus', 'tech-accessories',
      3900,
      merchant: _demoStreet, currency: 'GBP', shipsTo: _usUk),
  _fixture('tec-08', 'Desk Mic Mini', 'Quillon', 'tech-accessories', 6900,
      merchant: _fixtureGoods),

  // Home decor.
  _fixture('hom-01', 'Ceramic Vase Set', 'Lumenhaus', 'home-decor', 5400,
      merchant: _testbedHome, currency: 'GBP'),
  _fixture('hom-02', 'Linen Throw', 'Saltmarsh', 'home-decor', 6900,
      merchant: _sampleOutfitters, shipsTo: _usUk),
  _fixture('hom-03', 'Arc Floor Lamp', 'Brightmoor', 'home-decor', 18900,
      merchant: _fixtureGoods, shipsTo: _us),
  _fixture('hom-04', 'Woven Wall Hanging', 'Lumenhaus', 'home-decor', 4900,
      merchant: _testbedHome, currency: 'GBP', shipsTo: _uk),
  _fixture('hom-05', 'Scented Candle Trio', 'Saltmarsh', 'home-decor', 3900,
      merchant: _sampleOutfitters),
  _fixture('hom-06', 'Round Wall Mirror', 'Brightmoor', 'home-decor', 12900,
      merchant: _fixtureGoods, shipsTo: _gulf),
  _fixture('hom-07', 'Terracotta Planter', 'Tidewell', 'home-decor', 2900,
      merchant: _testbedHome, currency: 'GBP', shipsTo: _usUk),
  _fixture('hom-08', 'Oak Side Table', 'Halden', 'home-decor', 21900,
      merchant: _catalogSample, isAd: false),
];
