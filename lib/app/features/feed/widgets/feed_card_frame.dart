import 'package:flutter/material.dart';

import '../models/media.dart';
import 'media_carousel.dart';

/// What every Feed Item card shares: its media filling the card, a dark
/// fade so text stays readable, and the card's own text at the bottom left.
class FeedCardFrame extends StatelessWidget {
  const FeedCardFrame({
    super.key,
    required this.media,
    required this.details,
    this.sideActions,
  });

  final List<Media> media;

  /// Labels and text, top to bottom, at the bottom left of the card.
  final List<Widget> details;

  /// Buttons halfway down the right edge, if the card has any.
  final Widget? sideActions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade200),
      child: Stack(
        fit: StackFit.expand,
        children: [
          MediaCarousel(media: media),
          // Only for looks: swipes pass through to the pictures.
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black54],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: details,
            ),
          ),
          // Halfway down the right edge: the feed's search box and chips
          // float over the top of the card and would cover it there.
          if (sideActions != null)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [sideActions!],
              ),
            ),
        ],
      ),
    );
  }
}
