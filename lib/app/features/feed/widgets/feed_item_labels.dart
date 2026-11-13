import 'package:flutter/material.dart';

import '../../../app_name.dart';

/// The bold AD label every Ad carries, with "Sponsored" beside it when a
/// Brand or Merchant pays Stafeed directly.
class AdLabel extends StatelessWidget {
  const AdLabel({super.key, this.isSponsored = false});

  final bool isSponsored;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Badge(
          text: 'AD',
          background: Colors.white,
          foreground: Colors.black,
        ),
        if (isSponsored) ...[
          const SizedBox(width: 8),
          const Text(
            'Sponsored',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// The honest label on a Feed Item that earns Stafeed nothing.
class NotAnAdLabel extends StatelessWidget {
  const NotAnAdLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Badge(
      text: 'NOT AN AD',
      background: Colors.black54,
      foreground: Colors.white,
      border: Colors.white,
    );
  }
}

/// The small print under an Ad or a Not an Ad Feed Item.
class FeedItemNote extends StatelessWidget {
  const FeedItemNote(this.text, {super.key});

  /// On every Affiliate Ad.
  static const affiliate = '$appName may earn a commission';

  /// On every Not an Ad Feed Item.
  static const notAnAd = '$appName earns nothing on this one';

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white70, fontSize: 12),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.background,
    required this.foreground,
    this.border,
  });

  final String text;
  final Color background;
  final Color foreground;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          text,
          style: TextStyle(
            color: foreground,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
