/// Links starting with this are sample pictures drawn by the app itself, not
/// downloaded. Fixtures use them, so the sample feed looks right offline and
/// never shows a random stock photo that has nothing to do with the Product.
const sampleArtScheme = 'sample-art:';

/// The link of a sample picture for a Product in [category]. [key] picks its
/// colours, so the same Product always looks the same.
String sampleArtUrl(String category, String key) =>
    '$sampleArtScheme$category/$key';
