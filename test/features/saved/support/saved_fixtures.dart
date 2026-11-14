import 'package:stafeed/app/features/feed/models/money.dart';
import 'package:stafeed/app/features/feed/models/offer.dart';
import 'package:stafeed/app/features/feed/models/product.dart';
import 'package:stafeed/app/features/saved/data/saved_products_storage.dart';
import 'package:stafeed/app/features/saved/models/saved_product.dart';

Offer savedTestOffer(
  String id, {
  int price = 4500,
  String merchant = 'Acme Store',
  bool isAvailable = true,
}) => Offer(
  id: id,
  merchant: merchant,
  price: Money(price, 'USD'),
  shipsTo: const {'US'},
  url: Uri.parse('https://merchant.example/$id'),
  isAffiliate: true,
  isAvailable: isAvailable,
);

Product savedTestProduct(
  String id, {
  String? title,
  List<String> imageUrls = const ['https://img.example/1.jpg'],
  List<Offer>? offers,
}) => Product(
  id: id,
  title: title ?? 'Product $id',
  description: 'About $id.',
  brand: 'Northstar',
  category: 'sneakers',
  imageUrls: imageUrls,
  offers: offers ?? [savedTestOffer('$id-offer')],
);

SavedProduct savedSnapshot(
  String id, {
  String? title,
  DateTime? savedAt,
  int price = 4500,
  String merchant = 'Acme Store',
}) => SavedProduct.snapshot(
  savedTestProduct(id, title: title),
  savedTestOffer('$id-offer', price: price, merchant: merchant),
  savedAt: savedAt ?? DateTime.utc(2026, 11, 14, 9),
);

/// Storage whose writes fail with [error] while it is set. Reads still
/// work, like a full disk.
class FlakySavedProductsStorage extends SavedProductsStorage {
  Object? error;

  @override
  Future<void> save(List<SavedProduct> savedProducts) async {
    if (error case final error?) throw error;
    await super.save(savedProducts);
  }
}

/// Storage whose reads fail with [error] while it is set.
class UnreadableSavedProductsStorage extends SavedProductsStorage {
  Object? error = StateError('storage unreadable');

  @override
  Future<List<SavedProduct>> load() async {
    if (error case final error?) throw error;
    return super.load();
  }
}
