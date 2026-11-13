/// The app's visible name. Every screen and line of copy that says the name
/// reads it from here, so a rename is one edit.
///
/// "Stafeed" is a working name (the final one is chosen in #30). The
/// launcher label and browser tab title live in the platform folders
/// (`android/`, `ios/`, `web/`), which can't read Dart.
const String appName = 'Stafeed';
