import 'package:flutter/foundation.dart';

/// What the store this build is sold through allows.
///
/// Apple's App Store bans unlocking features outside in-app purchase
/// (guideline 3.1.1), so unlock codes are off there, and only nonprofits may
/// take donations (3.2.2), so purchases are called tips. Google Play and
/// GitHub builds keep unlock codes and donations.
class StoreRules {
  const StoreRules({required this.appStore});

  /// The rules for this build: the iOS app only ships through the App Store
  /// (the web app on an iPhone doesn't); a macOS build for the Mac App Store
  /// is made with `--dart-define=APP_STORE=true`.
  factory StoreRules.current() => StoreRules(
    appStore:
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ||
        const bool.fromEnvironment('APP_STORE'),
  );

  final bool appStore;

  /// Whether "Have a code?" may unlock the sponsor plan.
  bool get allowsUnlockCodes => !appStore;
}
