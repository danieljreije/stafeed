
import 'product.dart';

class PaginatedProducts {
  final List<Product> products;
  final int nextSkip;
  final bool hasMore;
  final bool isLoadingMore;
  final String? loadMoreError;

  const PaginatedProducts({
    required this.products,
    required this.nextSkip,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  PaginatedProducts copyWith({
    List<Product>? products,
    int? nextSkip,
    bool? hasMore,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearError = false,
  }) {
    return PaginatedProducts(
      products: products ?? this.products,
      nextSkip: nextSkip ?? this.nextSkip,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: clearError
          ? null
          : loadMoreError ?? this.loadMoreError,
    );
  }
}
