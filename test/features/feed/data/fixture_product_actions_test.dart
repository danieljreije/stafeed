// Product details, Merchant Handoff and Report through the Fixture data
// gateway (ticket #7).
import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/features/feed/data/fixture_data_gateway.dart';
import 'package:stafeed/app/features/feed/models/money.dart';
import 'package:stafeed/app/features/feed/models/offer.dart';
import 'package:stafeed/app/features/feed/models/product.dart';
import 'package:stafeed/app/features/feed/models/product_actions.dart';

Offer _offer(String id, Set<String> shipsTo, {bool isAffiliate = true}) =>
    Offer(
      id: id,
      merchant: 'Merchant $id',
      price: const Money(2500, 'USD'),
      shipsTo: shipsTo,
      url: Uri.parse('https://example.com/$id'),
      isAffiliate: isAffiliate,
    );

const _product = Product(
  id: 'p1',
  title: 'Product p1',
  description: 'A sample',
  brand: 'Brand',
  category: 'samples',
  imageUrls: [],
  offers: [],
);

Product _withOffers(List<Offer> offers) => Product(
  id: _product.id,
  title: _product.title,
  description: _product.description,
  brand: _product.brand,
  category: _product.category,
  imageUrls: _product.imageUrls,
  attributes: const {'Colour': 'Red'},
  offers: offers,
);

void main() {
  group('getProduct', () {
    test('returns the Product with all its details', () async {
      final product = _withOffers([
        _offer('us', {'US'}),
      ]);
      final gateway = FixtureDataGateway(products: [product], brandAds: []);

      final fetched = await gateway.getProduct('p1');

      expect(fetched, isNotNull);
      expect(fetched!.title, 'Product p1');
      expect(fetched.attributes, {'Colour': 'Red'});
      expect(fetched.offers.single.id, 'us');
    });

    test(
      'keeps only the Offers that ship to the Destination Country',
      () async {
        final gateway = FixtureDataGateway(
          products: [
            _withOffers([
              _offer('us', {'US'}),
              _offer('uk', {'GB'}),
              _offer('both', {'US', 'GB'}, isAffiliate: false),
            ]),
          ],
          brandAds: [],
          destinationCountry: 'gb',
        );

        final fetched = await gateway.getProduct('p1');

        expect(fetched!.offers.map((offer) => offer.id), ['uk', 'both']);
      },
    );

    test('is null when no Offer ships to the Destination Country', () async {
      final gateway = FixtureDataGateway(
        products: [
          _withOffers([
            _offer('us', {'US'}),
          ]),
        ],
        brandAds: [],
        destinationCountry: 'AE',
      );

      expect(await gateway.getProduct('p1'), isNull);
    });

    test('is null for a Product the Fixtures do not hold', () async {
      final gateway = FixtureDataGateway();

      expect(await gateway.getProduct('no-such-product'), isNull);
    });

    test('finds every Product the feed shows', () async {
      final gateway = FixtureDataGateway(destinationCountry: 'US');
      final page = await gateway.getFeedPage();

      for (final item in page.items) {
        for (final product in item.products) {
          expect(
            await gateway.getProduct(product.id),
            isNotNull,
            reason: product.id,
          );
        }
      }
    });
  });

  group('Merchant Handoff', () {
    test('each Outbound Click is recorded, in order', () async {
      final gateway = FixtureDataGateway();
      final first = OutboundClick(
        productId: 'p1',
        offerId: 'o1',
        merchant: 'M',
        url: Uri.parse('https://example.com/1'),
      );
      final second = OutboundClick(
        productId: 'p2',
        offerId: 'o2',
        merchant: 'M',
        url: Uri.parse('https://example.com/2'),
      );

      await gateway.recordOutboundClick(first);
      await gateway.recordOutboundClick(second);

      expect(gateway.outboundClicks, [first, second]);
    });
  });

  group('Report', () {
    test('each Report is stored with its reason and note', () async {
      final gateway = FixtureDataGateway();
      const report = ProductReport(
        productId: 'p1',
        offerId: 'o1',
        reason: ReportReason.wrongPrice,
        note: 'Says \$25, the shop says \$40',
      );

      await gateway.submitReport(report);

      expect(gateway.reports, [report]);
    });
  });
}
