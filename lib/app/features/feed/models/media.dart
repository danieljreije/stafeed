import 'package:flutter/foundation.dart';

/// One picture or clip a Feed Item shows. A Feed Item carries a list of
/// these, shown in order.
@immutable
sealed class Media {
  const Media();
}

/// A still image.
final class ImageMedia extends Media {
  const ImageMedia(this.url);

  final String url;

  @override
  bool operator ==(Object other) => other is ImageMedia && other.url == url;

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'ImageMedia($url)';
}

/// A video clip. The app doesn't play video yet: it shows [posterUrl], the
/// still image that stands in for the clip, when there is one.
final class VideoMedia extends Media {
  const VideoMedia(this.url, {this.posterUrl});

  final String url;

  /// A still image to show in place of the clip.
  final String? posterUrl;

  @override
  bool operator ==(Object other) =>
      other is VideoMedia && other.url == url && other.posterUrl == posterUrl;

  @override
  int get hashCode => Object.hash(url, posterUrl);

  @override
  String toString() => 'VideoMedia($url, posterUrl: $posterUrl)';
}
