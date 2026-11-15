import 'package:flutter/foundation.dart';

import '../../feed/models/feed_filter.dart';
import '../../feed/models/money.dart';

/// A named, temporary shopping goal (e.g. "white sneakers under $150") with
/// its own filters and its own taste signals.
@immutable
class ShoppingSession {
  const ShoppingSession({
    required this.id,
    required this.name,
    this.goal = '',
    this.category,
    this.brand,
    this.maxPrice,
  });

  /// Also the session ID on the Events recorded in it. A reset gives the
  /// session a new ID, so its old taste signals no longer count.
  final String id;
  final String name;

  /// What the Shopper typed, e.g. "white sneakers".
  final String goal;
  final String? category;
  final String? brand;
  final Money? maxPrice;

  /// The feed this session shows.
  FeedFilter get filter => FeedFilter(
    sessionId: id,
    query: goal.trim(),
    category: category,
    brand: brand,
    maxPrice: maxPrice,
  );

  ShoppingSession copyWith({
    String? id,
    String? name,
    String? goal,
    String? Function()? category,
    String? Function()? brand,
    Money? Function()? maxPrice,
  }) => ShoppingSession(
    id: id ?? this.id,
    name: name ?? this.name,
    goal: goal ?? this.goal,
    category: category != null ? category() : this.category,
    brand: brand != null ? brand() : this.brand,
    maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'goal': goal,
    if (category != null) 'category': category,
    if (brand != null) 'brand': brand,
    if (maxPrice != null)
      'maxPrice': {
        'minorUnits': maxPrice!.minorUnits,
        'currency': maxPrice!.currencyCode,
      },
  };

  /// Null when [json] isn't a stored session.
  static ShoppingSession? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final name = json['name'];
    if (id is! String || name is! String) return null;

    final price = json['maxPrice'];
    Money? maxPrice;
    if (price is Map &&
        price['minorUnits'] is int &&
        price['currency'] is String) {
      maxPrice = Money(price['minorUnits'] as int, price['currency'] as String);
    }

    String? text(String key) =>
        json[key] is String ? json[key] as String : null;

    return ShoppingSession(
      id: id,
      name: name,
      goal: text('goal') ?? '',
      category: text('category'),
      brand: text('brand'),
      maxPrice: maxPrice,
    );
  }
}

/// Every Shopping Session kept, newest first, and the active one.
@immutable
class ShoppingSessions {
  const ShoppingSessions({this.sessions = const [], this.activeId});

  final List<ShoppingSession> sessions;

  /// Null while For You shows.
  final String? activeId;

  ShoppingSession? get active {
    for (final session in sessions) {
      if (session.id == activeId) return session;
    }
    return null;
  }
}
