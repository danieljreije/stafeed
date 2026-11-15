import 'package:flutter/foundation.dart';

import 'money.dart';

/// What a feed shows: For You narrowed by a category or a search, or a
/// Shopping Session's feed when [sessionId] is set.
@immutable
class FeedFilter {
  const FeedFilter({
    this.category,
    this.query = '',
    this.brand,
    this.maxPrice,
    this.sessionId,
  });

  final String? category;

  /// Words to match, e.g. "white sneakers". For a Shopping Session, its goal.
  final String query;

  /// Only Feed Items of this Brand. Shopping Sessions only.
  final String? brand;

  /// Only Offers at or under this price, in the same currency (prices are
  /// not converted yet). Shopping Sessions only.
  final Money? maxPrice;

  /// The Shopping Session this feed belongs to. Null is For You.
  final String? sessionId;

  bool get isSession => sessionId != null;

  @override
  bool operator ==(Object other) =>
      other is FeedFilter &&
      other.category == category &&
      other.query == query &&
      other.brand == brand &&
      other.maxPrice?.minorUnits == maxPrice?.minorUnits &&
      other.maxPrice?.currencyCode == maxPrice?.currencyCode &&
      other.sessionId == sessionId;

  @override
  int get hashCode => Object.hash(
    category,
    query,
    brand,
    maxPrice?.minorUnits,
    maxPrice?.currencyCode,
    sessionId,
  );

  @override
  String toString() =>
      'FeedFilter(category: $category, query: $query, brand: $brand, '
      'maxPrice: ${maxPrice?.format()}, sessionId: $sessionId)';
}
