import 'package:stafeed/app/features/product/platform/product_platform.dart';

/// Records the links the app asks to open instead of leaving the app.
class FakeExternalLinks implements ExternalLinks {
  FakeExternalLinks({this.opens = true});

  /// What [open] answers: whether the link "opened".
  final bool opens;

  final List<Uri> opened = [];

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return opens;
  }
}

/// Records what the app hands the share sheet.
class FakeShareSheet implements ShareSheet {
  final List<String> shared = [];

  @override
  Future<void> share({required String text, String? subject}) async {
    shared.add(text);
  }
}
