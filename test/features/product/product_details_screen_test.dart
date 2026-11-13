// The Product details screen and its actions (ticket #7): a fresh fetch
// through the data gateway, Merchant Handoff, Share and Report.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/features/feed/models/money.dart';
import 'package:stafeed/app/features/feed/models/offer.dart';
import 'package:stafeed/app/features/feed/models/product.dart';
import 'package:stafeed/app/features/feed/models/product_actions.dart';
import 'package:stafeed/app/features/feed/providers/data_gateway_provider.dart';
import 'package:stafeed/app/features/feed/widgets/sample_data_marker.dart';
import 'package:stafeed/app/features/product/platform/product_platform.dart';
import 'package:stafeed/app/features/product/product_details_screen.dart';

import '../feed/support/scripted_data_gateway.dart';
import 'support/fake_product_platform.dart';

const affiliateNote = 'Stafeed may earn a commission';
const notAnAdNote = 'Stafeed earns nothing on this one';

Offer offer(
  String id, {
  int price = 4500,
  String merchant = 'Acme Store',
  bool isAffiliate = true,
  bool isAvailable = true,
}) => Offer(
  id: id,
  merchant: merchant,
  price: Money(price, 'USD'),
  shipsTo: const {'US'},
  url: Uri.parse('https://merchant.example/$id'),
  isAffiliate: isAffiliate,
  isAvailable: isAvailable,
);

Product product({List<Offer>? offers}) => Product(
  id: 'p1',
  title: 'Trail Runner',
  description: 'A light shoe for rough paths.',
  brand: 'Northstar',
  category: 'sneakers',
  imageUrls: const ['https://img.example/1.jpg', 'https://img.example/2.jpg'],
  attributes: const {'Colour': 'Moss green', 'Material': 'Mesh'},
  offers: offers ?? [offer('o1')],
);

void main() {
  late ScriptedDataGateway gateway;
  late FakeExternalLinks links;
  late FakeShareSheet shareSheet;

  /// Opens the details screen for Product p1, as the Shopper does from a
  /// Feed Item showing [offerId]. The gateway answers with [answer], or
  /// through [onGetProduct] when given.
  Future<void> openDetails(
    WidgetTester tester, {
    Product? answer,
    Future<Product?> Function(String productId)? onGetProduct,
    bool servesSampleData = false,
    String? offerId,
    bool linksOpen = true,
  }) async {
    gateway = ScriptedDataGateway(
      servesSampleData: servesSampleData,
      products: {'p1': ?answer},
    )..onGetProduct = onGetProduct;
    links = FakeExternalLinks(opens: linksOpen);
    shareSheet = FakeShareSheet();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataGatewayProvider.overrideWithValue(gateway),
          externalLinksProvider.overrideWithValue(links),
          shareSheetProvider.overrideWithValue(shareSheet),
        ],
        child: MaterialApp(
          home: ProductDetailsScreen(productId: 'p1', offerId: offerId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  group('Details', () {
    testWidgets('shows the media, description, attributes, Merchant, price, '
        'availability and affiliate note', (tester) async {
      await openDetails(tester, answer: product());

      expect(find.text('Trail Runner'), findsOneWidget);
      expect(find.text('A light shoe for rough paths.'), findsOneWidget);
      expect(find.text('Colour'), findsOneWidget);
      expect(find.text('Moss green'), findsOneWidget);
      expect(find.text('Material'), findsOneWidget);
      expect(find.text('Mesh'), findsOneWidget);
      expect(find.text('Sold by Acme Store'), findsOneWidget);
      expect(find.text(r'$45.00'), findsOneWidget);
      expect(find.text('In stock'), findsOneWidget);
      expect(find.text(affiliateNote), findsOneWidget);
      // Both pictures, swiped through sideways with a position marker.
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('names the Brand', (tester) async {
      await openDetails(tester, answer: product());

      expect(find.text('Northstar'), findsWidgets);
    });

    testWidgets('fetches the Product fresh through the gateway on open', (
      tester,
    ) async {
      await openDetails(tester, answer: product());

      expect(gateway.productRequests, ['p1']);
    });

    testWidgets("shows today's price and availability from the gateway", (
      tester,
    ) async {
      await openDetails(
        tester,
        answer: product(offers: [offer('o1', price: 3900, isAvailable: false)]),
      );

      expect(find.text(r'$39.00'), findsOneWidget);
      expect(find.text('Out of stock'), findsOneWidget);
    });

    testWidgets('shows the Offer the Shopper saw in the feed', (tester) async {
      await openDetails(
        tester,
        offerId: 'o2',
        answer: product(
          offers: [
            offer('o1', merchant: 'First Store'),
            offer('o2', merchant: 'Second Store', price: 5000),
          ],
        ),
      );

      expect(find.text('Sold by Second Store'), findsOneWidget);
      expect(find.text(r'$50.00'), findsOneWidget);
    });

    testWidgets('an Offer that earns nothing says so', (tester) async {
      await openDetails(
        tester,
        answer: product(offers: [offer('o1', isAffiliate: false)]),
      );

      expect(find.text(notAnAdNote), findsOneWidget);
      expect(find.text(affiliateNote), findsNothing);
    });

    testWidgets('marks Fixtures as sample data', (tester) async {
      await openDetails(tester, answer: product(), servesSampleData: true);

      expect(find.byType(SampleDataMarker), findsOneWidget);
    });

    testWidgets('shows a spinner while the Product loads', (tester) async {
      final pending = Completer<Product?>();
      gateway = ScriptedDataGateway()..onGetProduct = (_) => pending.future;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [dataGatewayProvider.overrideWithValue(gateway)],
          child: const MaterialApp(home: ProductDetailsScreen(productId: 'p1')),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      pending.complete(product());
      await tester.pumpAndSettle();

      expect(find.text('Trail Runner'), findsOneWidget);
    });

    testWidgets('a failed fetch offers Retry, which asks again', (
      tester,
    ) async {
      var fail = true;
      await openDetails(
        tester,
        onGetProduct: (_) async {
          if (fail) throw Exception('Scripted outage');
          return product();
        },
      );

      expect(find.text("Couldn't load this Product."), findsOneWidget);

      fail = false;
      await tapText(tester, 'Retry');

      expect(gateway.productRequests, ['p1', 'p1']);
      expect(find.text('Trail Runner'), findsOneWidget);
    });

    testWidgets('a Product no longer available says so', (tester) async {
      await openDetails(tester);

      expect(
        find.text("This Product isn't available any more."),
        findsOneWidget,
      );
      expect(find.textContaining('View at'), findsNothing);
    });
  });

  group('Merchant Handoff', () {
    testWidgets('a real Offer opens its Merchant link outside the app', (
      tester,
    ) async {
      await openDetails(tester, answer: product());

      await tapText(tester, 'View at Acme Store');

      expect(links.opened, [Uri.parse('https://merchant.example/o1')]);
    });

    testWidgets('records an Outbound Click through the gateway', (
      tester,
    ) async {
      await openDetails(tester, answer: product());

      await tapText(tester, 'View at Acme Store');

      expect(gateway.outboundClicks, [
        OutboundClick(
          productId: 'p1',
          offerId: 'o1',
          merchant: 'Acme Store',
          url: Uri.parse('https://merchant.example/o1'),
        ),
      ]);
    });

    testWidgets('says so when the Merchant link would not open', (
      tester,
    ) async {
      await openDetails(tester, answer: product(), linksOpen: false);

      await tapText(tester, 'View at Acme Store');

      expect(find.text("Couldn't open Acme Store."), findsOneWidget);
    });

    testWidgets('still goes to the Merchant when recording the click fails', (
      tester,
    ) async {
      await openDetails(tester, answer: product());
      gateway.actionError = Exception('Scripted outage');

      await tapText(tester, 'View at Acme Store');

      expect(links.opened, [Uri.parse('https://merchant.example/o1')]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a Fixture opens an in-app page explaining it instead', (
      tester,
    ) async {
      await openDetails(tester, answer: product(), servesSampleData: true);

      await tapText(tester, 'View at Acme Store');

      expect(links.opened, isEmpty);
      expect(
        find.textContaining('the real app would open Acme Store'),
        findsOneWidget,
      );
      expect(find.textContaining('Stafeed never takes payment'), findsOne);
      expect(gateway.outboundClicks, hasLength(1));
    });

    testWidgets('back from the Fixture page returns to the details', (
      tester,
    ) async {
      await openDetails(tester, answer: product(), servesSampleData: true);
      await tapText(tester, 'View at Acme Store');

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Sold by Acme Store'), findsOneWidget);
    });
  });

  group('Share', () {
    testWidgets('a real Offer shares name, Brand, price and Merchant link', (
      tester,
    ) async {
      await openDetails(tester, answer: product());

      await tester.tap(find.byTooltip('Share'));
      await tester.pumpAndSettle();

      final shared = shareSheet.shared.single;
      expect(shared, contains('Trail Runner'));
      expect(shared, contains('Northstar'));
      expect(shared, contains(r'$45.00'));
      expect(shared, contains('Acme Store'));
      expect(shared, contains('https://merchant.example/o1'));
    });

    testWidgets("a Fixture shares name, Brand and 'found on Stafeed' only", (
      tester,
    ) async {
      await openDetails(tester, answer: product(), servesSampleData: true);

      await tester.tap(find.byTooltip('Share'));
      await tester.pumpAndSettle();

      expect(shareSheet.shared, [
        'Trail Runner by Northstar, found on Stafeed',
      ]);
    });
  });

  group('Report', () {
    Future<void> openReport(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Report'));
      await tester.pumpAndSettle();
    }

    testWidgets('offers the five reasons', (tester) async {
      await openDetails(tester, answer: product());
      await openReport(tester);

      for (final reason in [
        'Wrong price',
        'Misleading',
        'Prohibited item',
        'Broken link',
        'Other',
      ]) {
        expect(find.text(reason), findsOneWidget, reason: reason);
      }
    });

    testWidgets('cannot be sent before a reason is picked', (tester) async {
      await openDetails(tester, answer: product());
      await openReport(tester);

      await tapText(tester, 'Send report');

      expect(gateway.reports, isEmpty);
      expect(find.text('Send report'), findsOneWidget);
    });

    testWidgets('stores the reason and note through the gateway', (
      tester,
    ) async {
      await openDetails(tester, answer: product());
      await openReport(tester);

      await tapText(tester, 'Wrong price');
      await tester.enterText(find.byType(TextField), 'Shop says \$60');
      await tapText(tester, 'Send report');

      expect(gateway.reports, [
        const ProductReport(
          productId: 'p1',
          offerId: 'o1',
          reason: ReportReason.wrongPrice,
          note: 'Shop says \$60',
        ),
      ]);
      // Back on the details, with a thank-you.
      expect(find.text('Sold by Acme Store'), findsOneWidget);
      expect(find.text("Thanks. We'll take a look."), findsOneWidget);
    });

    testWidgets('Other with a note is stored too', (tester) async {
      await openDetails(tester, answer: product());
      await openReport(tester);

      await tapText(tester, 'Other');
      await tester.enterText(find.byType(TextField), 'Duplicate of another');
      await tapText(tester, 'Send report');

      expect(gateway.reports.single.reason, ReportReason.other);
      expect(gateway.reports.single.note, 'Duplicate of another');
    });

    testWidgets('says so when the Report could not be sent', (tester) async {
      await openDetails(tester, answer: product());
      gateway.actionError = Exception('Scripted outage');
      await openReport(tester);

      await tapText(tester, 'Misleading');
      await tapText(tester, 'Send report');

      expect(find.text("Couldn't send the report. Try again."), findsOneWidget);
      expect(find.text("Thanks. We'll take a look."), findsNothing);
    });

    testWidgets('closing it stores nothing', (tester) async {
      await openDetails(tester, answer: product());
      await openReport(tester);
      await tapText(tester, 'Broken link');

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(gateway.reports, isEmpty);
      expect(find.text('Sold by Acme Store'), findsOneWidget);
    });
  });
}
