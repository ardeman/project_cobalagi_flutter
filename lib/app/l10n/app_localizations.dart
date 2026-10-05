import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Coba Lagi'**
  String get appTitle;

  /// No description provided for @whoIsPlaying.
  ///
  /// In en, this message translates to:
  /// **'Who\'s playing?'**
  String get whoIsPlaying;

  /// No description provided for @addPlayer.
  ///
  /// In en, this message translates to:
  /// **'New player'**
  String get addPlayer;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @chooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose a friend'**
  String get chooseAvatar;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @greeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}!'**
  String greeting(String name);

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon!'**
  String get comingSoon;

  /// No description provided for @askAGrownUp.
  ///
  /// In en, this message translates to:
  /// **'Ask a grown-up'**
  String get askAGrownUp;

  /// No description provided for @parentGateQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is {a} × {b}?'**
  String parentGateQuestion(int a, int b);

  /// No description provided for @parentGateWrong.
  ///
  /// In en, this message translates to:
  /// **'Not quite. Try again.'**
  String get parentGateWrong;

  /// No description provided for @parentArea.
  ///
  /// In en, this message translates to:
  /// **'Parent area'**
  String get parentArea;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Same as device'**
  String get languageSystem;

  /// No description provided for @languageIndonesian.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get languageIndonesian;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get plan;

  /// No description provided for @planFree.
  ///
  /// In en, this message translates to:
  /// **'Free: 1 player'**
  String get planFree;

  /// No description provided for @planFull.
  ///
  /// In en, this message translates to:
  /// **'Supporter: up to {count} players'**
  String planFull(int count);

  /// No description provided for @supportCobaLagi.
  ///
  /// In en, this message translates to:
  /// **'Support Coba Lagi'**
  String get supportCobaLagi;

  /// No description provided for @debugPlanOverride.
  ///
  /// In en, this message translates to:
  /// **'Debug: use full version'**
  String get debugPlanOverride;

  /// No description provided for @players.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get players;

  /// No description provided for @deletePlayerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {name} and all their progress?'**
  String deletePlayerConfirm(String name);

  /// No description provided for @playerLimitReached.
  ///
  /// In en, this message translates to:
  /// **'This version has room for one player. Ask a grown-up.'**
  String get playerLimitReached;

  /// No description provided for @run.
  ///
  /// In en, this message translates to:
  /// **'Go!'**
  String get run;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'One step'**
  String get step;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get reset;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Remove last block'**
  String get undo;

  /// No description provided for @clearBlocks.
  ///
  /// In en, this message translates to:
  /// **'Remove all blocks'**
  String get clearBlocks;

  /// No description provided for @blockForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get blockForward;

  /// No description provided for @blockTurnLeft.
  ///
  /// In en, this message translates to:
  /// **'Turn left'**
  String get blockTurnLeft;

  /// No description provided for @blockTurnRight.
  ///
  /// In en, this message translates to:
  /// **'Turn right'**
  String get blockTurnRight;

  /// No description provided for @blockRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get blockRepeat;

  /// No description provided for @successTitle.
  ///
  /// In en, this message translates to:
  /// **'Hooray!'**
  String get successTitle;

  /// No description provided for @nextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextLevel;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again!'**
  String get tryAgain;

  /// No description provided for @feedbackBumped.
  ///
  /// In en, this message translates to:
  /// **'Oops, something is in the way.'**
  String get feedbackBumped;

  /// No description provided for @feedbackStoppedShort.
  ///
  /// In en, this message translates to:
  /// **'Almost! Keep going to the flag.'**
  String get feedbackStoppedShort;

  /// No description provided for @feedbackMissedStars.
  ///
  /// In en, this message translates to:
  /// **'Collect all the stars first.'**
  String get feedbackMissedStars;

  /// No description provided for @feedbackTooManySteps.
  ///
  /// In en, this message translates to:
  /// **'That\'s a lot of steps! Try fewer.'**
  String get feedbackTooManySteps;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @conceptDirections.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get conceptDirections;

  /// No description provided for @conceptSequencing.
  ///
  /// In en, this message translates to:
  /// **'Step by step'**
  String get conceptSequencing;

  /// No description provided for @conceptLoops.
  ///
  /// In en, this message translates to:
  /// **'Loops'**
  String get conceptLoops;

  /// No description provided for @decisionAdvance.
  ///
  /// In en, this message translates to:
  /// **'New island unlocked!'**
  String get decisionAdvance;

  /// No description provided for @decisionPractice.
  ///
  /// In en, this message translates to:
  /// **'Let\'s try another one!'**
  String get decisionPractice;

  /// No description provided for @bonusAdventure.
  ///
  /// In en, this message translates to:
  /// **'Bonus adventure!'**
  String get bonusAdventure;

  /// No description provided for @decisionReview.
  ///
  /// In en, this message translates to:
  /// **'Let\'s hunt for treasure on an earlier island.'**
  String get decisionReview;

  /// No description provided for @decisionReturn.
  ///
  /// In en, this message translates to:
  /// **'Back to your adventure!'**
  String get decisionReturn;

  /// No description provided for @decisionMapComplete.
  ///
  /// In en, this message translates to:
  /// **'You explored every island!'**
  String get decisionMapComplete;

  /// No description provided for @goodTry.
  ///
  /// In en, this message translates to:
  /// **'Good try!'**
  String get goodTry;

  /// No description provided for @skipPuzzle.
  ///
  /// In en, this message translates to:
  /// **'Try a different one'**
  String get skipPuzzle;

  /// No description provided for @hint.
  ///
  /// In en, this message translates to:
  /// **'Show me the way'**
  String get hint;

  /// No description provided for @repeatMore.
  ///
  /// In en, this message translates to:
  /// **'One more time'**
  String get repeatMore;

  /// No description provided for @repeatFewer.
  ///
  /// In en, this message translates to:
  /// **'One time fewer'**
  String get repeatFewer;

  /// No description provided for @dropBlocksHere.
  ///
  /// In en, this message translates to:
  /// **'Put blocks here'**
  String get dropBlocksHere;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
