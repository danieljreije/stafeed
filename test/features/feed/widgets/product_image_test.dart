import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stafeed/app/features/feed/data/fixture_data_gateway.dart';
import 'package:stafeed/app/features/feed/data/fixtures/fixture_brand_ads.dart';
import 'package:stafeed/app/features/feed/data/fixtures/fixture_products.dart';
import 'package:stafeed/app/features/feed/models/media.dart';
import 'package:stafeed/app/features/feed/widgets/product_image.dart';

Future<void> pumpImage(WidgetTester tester, String url) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(width: 300, height: 450, child: ProductImage(url)),
    ),
  );
}

void main() {
  testWidgets('a sample picture is drawn in the app, with no download', (
    tester,
  ) async {
    await pumpImage(tester, sampleArtUrl('sneakers', 'snk-01'));

    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.directions_run), findsOneWidget);
    expect(find.bySemanticsLabel('Sample picture'), findsOneWidget);
  });

  testWidgets('each category gets its own picture', (tester) async {
    final icons = <IconData>{};
    for (final category in fixtureCategories) {
      await pumpImage(tester, sampleArtUrl(category.id, 'x'));
      icons.add(tester.widget<Icon>(find.byType(Icon)).icon!);
    }

    expect(icons, hasLength(fixtureCategories.length));
  });

  testWidgets('a real picture is still loaded from its link', (tester) async {
    await pumpImage(tester, 'https://example.com/1.jpg');

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, 'https://example.com/1.jpg');
  });

  test('every Fixture picture is a sample picture, so the app works '
      'offline', () async {
    final urls = [
      for (final product in fixtureProducts) ...product.imageUrls,
      for (final ad in fixtureBrandAds)
        for (final media in ad.media)
          if (media case ImageMedia(:final url)) url,
    ];

    expect(urls, isNotEmpty);
    expect(urls, everyElement(startsWith(sampleArtScheme)));
    // The gateway hands out the same pictures.
    final page = await FixtureDataGateway().getFeedPage();
    expect(page.items, isNotEmpty);
  });
}
