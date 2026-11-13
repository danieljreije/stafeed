import 'package:flutter/material.dart';

import '../models/media.dart';

/// A Feed Item's pictures, filling the card. Several are swiped through
/// sideways, with dots showing the place. Video isn't played yet: its poster
/// image stands in for it.
class MediaCarousel extends StatefulWidget {
  const MediaCarousel({super.key, required this.media});

  final List<Media> media;

  @override
  State<MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<MediaCarousel> {
  int _current = 0;

  @override
  void didUpdateWidget(MediaCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_current >= widget.media.length) _current = 0;
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;

    if (media.isEmpty) {
      return const _Placeholder(Icons.image_not_supported_outlined);
    }
    if (media.length == 1) return _MediaView(media.single);

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: media.length,
          onPageChanged: (index) => setState(() => _current = index),
          itemBuilder: (context, index) => _MediaView(media[index]),
        ),
        // A little above the middle of the card: clear of the feed's search
        // box and chips on top, and of the card's own text at the bottom.
        Align(
          alignment: const Alignment(0, -0.2),
          child: IgnorePointer(
            child: _Dots(count: media.length, current: _current),
          ),
        ),
      ],
    );
  }
}

class _MediaView extends StatelessWidget {
  const _MediaView(this.media);

  final Media media;

  @override
  Widget build(BuildContext context) {
    final url = switch (media) {
      ImageMedia(:final url) => url,
      VideoMedia(:final posterUrl) => posterUrl,
    };

    if (url == null) return const _Placeholder(Icons.videocam_outlined);

    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        return const _Placeholder(Icons.broken_image_outlined);
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(child: Icon(icon, size: 48));
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Image ${current + 1} of $count',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < count; i++)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == current ? Colors.white : Colors.white38,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
