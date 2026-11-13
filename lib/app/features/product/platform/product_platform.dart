import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens links outside the app (the Merchant's page, in the browser or the
/// Merchant's own app).
abstract interface class ExternalLinks {
  /// True when the link opened.
  Future<bool> open(Uri url);
}

/// The phone's own share sheet.
abstract interface class ShareSheet {
  Future<void> share({required String text, String? subject});
}

class _UrlLauncherLinks implements ExternalLinks {
  const _UrlLauncherLinks();

  @override
  Future<bool> open(Uri url) async {
    try {
      return await launchUrl(url, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}

class _SystemShareSheet implements ShareSheet {
  const _SystemShareSheet();

  @override
  Future<void> share({required String text, String? subject}) =>
      SharePlus.instance.share(ShareParams(text: text, subject: subject));
}

final externalLinksProvider = Provider<ExternalLinks>(
  (ref) => const _UrlLauncherLinks(),
);

final shareSheetProvider = Provider<ShareSheet>(
  (ref) => const _SystemShareSheet(),
);
