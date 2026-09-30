import '../models/product.dart';

const sampleProducts = [
  Product(
    id: 'shoe-001',
    name: 'Air Runner',
    brand: 'Northstar',
    priceInCents: 12900,
    currencyCode: 'USD',
    category: 'Shoes',
    imageUrl: 'https://picsum.photos/seed/shoe1/800/1200',
  ),
  Product(
    id: 'shoe-002',
    name: 'Street Classic',
    brand: 'Motion',
    priceInCents: 9900,
    currencyCode: 'USD',
    category: 'Shoes',
    imageUrl: 'https://picsum.photos/seed/shoe2/800/1200',
  ),
  Product(
    id: 'watch-001',
    name: 'Minimal Steel',
    brand: 'Chrona',
    priceInCents: 18900,
    currencyCode: 'USD',
    category: 'Watches',
    imageUrl: 'https://picsum.photos/seed/watch1/800/1200',
  ),
];