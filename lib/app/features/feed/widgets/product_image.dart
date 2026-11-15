import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/sample_art.dart';

export '../models/sample_art.dart';

/// A Product or Brand Ad picture: a sample picture for a `sample-art:` link,
/// otherwise the picture downloaded from [url].
class ProductImage extends StatelessWidget {
  const ProductImage(this.url, {super.key, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.startsWith(sampleArtScheme)) {
      final rest = url.substring(sampleArtScheme.length);
      final slash = rest.indexOf('/');
      return _SampleArt(
        category: slash < 0 ? rest : rest.substring(0, slash),
        key_: rest,
      );
    }

    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        return const Center(child: Icon(Icons.broken_image_outlined, size: 48));
      },
    );
  }
}

const _palettes = [
  [Color(0xFFFF8A65), Color(0xFFD84315)],
  [Color(0xFF4DB6AC), Color(0xFF00695C)],
  [Color(0xFF7986CB), Color(0xFF283593)],
  [Color(0xFFFFD54F), Color(0xFFEF6C00)],
  [Color(0xFFBA68C8), Color(0xFF6A1B9A)],
  [Color(0xFF81C784), Color(0xFF2E7D32)],
  [Color(0xFF4FC3F7), Color(0xFF01579B)],
  [Color(0xFFF06292), Color(0xFFAD1457)],
];

IconData _iconFor(String category) => switch (category) {
  'sneakers' => Icons.directions_run,
  'bags' => Icons.shopping_bag,
  'watches' => Icons.watch,
  'tech-accessories' => Icons.headphones,
  'home-decor' => Icons.chair,
  _ => Icons.local_offer,
};

/// A stable number for [text]; String.hashCode may differ between runs.
int _stableHash(String text) {
  var hash = 17;
  for (final unit in text.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return hash;
}

class _SampleArt extends StatelessWidget {
  const _SampleArt({required this.category, required this.key_});

  final String category;
  final String key_;

  @override
  Widget build(BuildContext context) {
    final hash = _stableHash(key_);
    final colors = _palettes[hash % _palettes.length];
    final angle = (hash % 360) * math.pi / 180;

    return Semantics(
      label: 'Sample picture',
      image: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            transform: GradientRotation(angle),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest.shortestSide;
            return Stack(
              fit: StackFit.expand,
              children: [
                // Soft circles behind the object, placed by the key.
                Positioned(
                  left: constraints.maxWidth * (0.1 + (hash % 5) / 10),
                  top: constraints.maxHeight * 0.15,
                  child: _Circle(size * 0.8),
                ),
                Positioned(
                  right: constraints.maxWidth * 0.05,
                  bottom: constraints.maxHeight * (0.1 + (hash % 3) / 10),
                  child: _Circle(size * 0.5),
                ),
                Align(
                  alignment: const Alignment(0, -0.15),
                  child: Icon(
                    _iconFor(category),
                    size: size * 0.45,
                    color: Colors.white.withValues(alpha: 0.92),
                    shadows: const [
                      Shadow(blurRadius: 24, color: Colors.black26),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle(this.size);

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.12),
      ),
    );
  }
}
