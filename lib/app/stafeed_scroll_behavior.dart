import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Lets a mouse or trackpad drag the feed and the picture carousels, like a
/// finger does. Flutter leaves mouse dragging off by default, which made the
/// web version stuck on the first Feed Item when used on a computer.
class StafeedScrollBehavior extends MaterialScrollBehavior {
  const StafeedScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };
}
