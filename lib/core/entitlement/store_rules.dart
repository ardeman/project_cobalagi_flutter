import 'package:flutter/foundation.dart';

/// What the store this build is sold through allows.
///
/// Apple's App Store bans unlocking features outside in-app purchase
/// (guideline 3.1.1), so unlock codes are off there, and only nonprofits may
/// take donations (3.2.2), so purchases are called tips. Google Play and
/// GitHub builds keep unlock codes and donations.
///
/// Codes bought on the website work only in GitHub builds, made with
/// `--dart-define=GITHUB_RELEASE=true`: Google Play and the App Store forbid
/// unlocking with a purchase made outside their billing.
class StoreRules {
  const StoreRules({required this.appStore, this.githubRelease = false});

  /// The rules for this build: the iOS app only ships through the App Store
  /// (the web app on an iPhone doesn't); a macOS build for the Mac App Store
  /// is made with `--dart-define=APP_STORE=true`.
  factory StoreRules.current() => StoreRules(
    appStore:
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ||
        const bool.fromEnvironment('APP_STORE'),
    githubRelease: const bool.fromEnvironment('GITHUB_RELEASE'),
  );

  final bool appStore;

  /// Whether this build is one published on GitHub Releases.
  final bool githubRelease;

  /// Whether "Have a code?" may unlock the sponsor plan.
  bool get allowsUnlockCodes => !appStore;

  /// Whether "Have a code?" also takes codes bought on the website.
  bool get allowsPurchasedCodes => githubRelease && !appStore;

  /// Whether purchases go through store billing on [platform]: Google Play
  /// on Android, and the App Store on iOS and in Mac App Store builds. Other
  /// builds (GitHub's macOS, Windows and Linux, the web) have no store, so
  /// they stay on the free plan unless a code unlocks it.
  bool storeBilling(TargetPlatform platform) =>
      !kIsWeb && (platform == TargetPlatform.android || appStore);
}
