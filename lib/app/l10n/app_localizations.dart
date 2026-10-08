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
  /// **'Regular: 1 player'**
  String get planFree;

  /// No description provided for @planFull.
  ///
  /// In en, this message translates to:
  /// **'Sponsor: up to {count} players'**
  String planFull(int count);

  /// Installed app version at the bottom of the parent area.
  ///
  /// In en, this message translates to:
  /// **'App version {version} ({build})'**
  String appVersion(String version, String build);

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s progress'**
  String progressTitle(String name);

  /// No description provided for @changeStartingIsland.
  ///
  /// In en, this message translates to:
  /// **'Change starting island'**
  String get changeStartingIsland;

  /// No description provided for @progressThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get progressThisWeek;

  /// No description provided for @progressAllTime.
  ///
  /// In en, this message translates to:
  /// **'Since the start'**
  String get progressAllTime;

  /// No description provided for @progressPuzzles.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 puzzle solved} other{{count} puzzles solved}}'**
  String progressPuzzles(int count);

  /// No description provided for @progressMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute of play} other{{count} minutes of play}}'**
  String progressMinutes(int count);

  /// No description provided for @progressLastPlayed.
  ///
  /// In en, this message translates to:
  /// **'Last played: {date}'**
  String progressLastPlayed(String date);

  /// No description provided for @progressNotPlayed.
  ///
  /// In en, this message translates to:
  /// **'Hasn\'t finished a puzzle yet'**
  String get progressNotPlayed;

  /// No description provided for @progressIslands.
  ///
  /// In en, this message translates to:
  /// **'Islands'**
  String get progressIslands;

  /// No description provided for @statusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get statusNotStarted;

  /// No description provided for @statusPractising.
  ///
  /// In en, this message translates to:
  /// **'Practising'**
  String get statusPractising;

  /// No description provided for @statusMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get statusMastered;

  /// No description provided for @progressLevels.
  ///
  /// In en, this message translates to:
  /// **'{solved} of {total} levels solved'**
  String progressLevels(int solved, int total);

  /// No description provided for @progressSponsorOnly.
  ///
  /// In en, this message translates to:
  /// **'Sponsors see the full progress report: puzzles solved, time played and progress on each island.'**
  String get progressSponsorOnly;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Background music'**
  String get music;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get soundEffects;

  /// No description provided for @soundEffectsHint.
  ///
  /// In en, this message translates to:
  /// **'Voices always play.'**
  String get soundEffectsHint;

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
  /// **'Undo'**
  String get undo;

  /// No description provided for @redo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redo;

  /// No description provided for @clearBlocks.
  ///
  /// In en, this message translates to:
  /// **'Remove all blocks'**
  String get clearBlocks;

  /// No description provided for @removeBlock.
  ///
  /// In en, this message translates to:
  /// **'Remove this block'**
  String get removeBlock;

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

  /// No description provided for @blockStar.
  ///
  /// In en, this message translates to:
  /// **'My block'**
  String get blockStar;

  /// No description provided for @toMap.
  ///
  /// In en, this message translates to:
  /// **'To the map'**
  String get toMap;

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

  /// No description provided for @conceptFunctions.
  ///
  /// In en, this message translates to:
  /// **'Magic Block'**
  String get conceptFunctions;

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

  /// No description provided for @pretestWelcome.
  ///
  /// In en, this message translates to:
  /// **'Let\'s play a warm-up game!'**
  String get pretestWelcome;

  /// No description provided for @pretestStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get pretestStart;

  /// No description provided for @listenAgain.
  ///
  /// In en, this message translates to:
  /// **'Listen again'**
  String get listenAgain;

  /// No description provided for @promptReading.
  ///
  /// In en, this message translates to:
  /// **'Which picture matches the words?'**
  String get promptReading;

  /// No description provided for @promptCounting.
  ///
  /// In en, this message translates to:
  /// **'How many are there?'**
  String get promptCounting;

  /// No description provided for @promptSideLeft.
  ///
  /// In en, this message translates to:
  /// **'Tap the one on the left.'**
  String get promptSideLeft;

  /// No description provided for @promptSideRight.
  ///
  /// In en, this message translates to:
  /// **'Tap the one on the right.'**
  String get promptSideRight;

  /// No description provided for @promptTurnLeft.
  ///
  /// In en, this message translates to:
  /// **'The arrow turns left. Which way does it point now?'**
  String get promptTurnLeft;

  /// No description provided for @promptTurnRight.
  ///
  /// In en, this message translates to:
  /// **'The arrow turns right. Which way does it point now?'**
  String get promptTurnRight;

  /// No description provided for @promptPattern.
  ///
  /// In en, this message translates to:
  /// **'What comes next?'**
  String get promptPattern;

  /// No description provided for @promptSequencing.
  ///
  /// In en, this message translates to:
  /// **'Which steps reach the flag?'**
  String get promptSequencing;

  /// No description provided for @pretestDone.
  ///
  /// In en, this message translates to:
  /// **'All done! Your adventure starts now.'**
  String get pretestDone;

  /// No description provided for @startAdventure.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go!'**
  String get startAdventure;

  /// No description provided for @wordSun.
  ///
  /// In en, this message translates to:
  /// **'sun'**
  String get wordSun;

  /// No description provided for @wordStar.
  ///
  /// In en, this message translates to:
  /// **'star'**
  String get wordStar;

  /// No description provided for @wordHouse.
  ///
  /// In en, this message translates to:
  /// **'house'**
  String get wordHouse;

  /// No description provided for @wordCar.
  ///
  /// In en, this message translates to:
  /// **'car'**
  String get wordCar;

  /// No description provided for @wordTree.
  ///
  /// In en, this message translates to:
  /// **'tree'**
  String get wordTree;

  /// No description provided for @wordBall.
  ///
  /// In en, this message translates to:
  /// **'ball'**
  String get wordBall;

  /// No description provided for @wordFlower.
  ///
  /// In en, this message translates to:
  /// **'flower'**
  String get wordFlower;

  /// No description provided for @wordBoat.
  ///
  /// In en, this message translates to:
  /// **'boat'**
  String get wordBoat;

  /// No description provided for @wordBird.
  ///
  /// In en, this message translates to:
  /// **'bird'**
  String get wordBird;

  /// No description provided for @wordCake.
  ///
  /// In en, this message translates to:
  /// **'cake'**
  String get wordCake;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'red'**
  String get colorRed;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'blue'**
  String get colorBlue;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'green'**
  String get colorGreen;

  /// No description provided for @colorYellow.
  ///
  /// In en, this message translates to:
  /// **'yellow'**
  String get colorYellow;

  /// No description provided for @wordsWithColor.
  ///
  /// In en, this message translates to:
  /// **'{color} {object}'**
  String wordsWithColor(String color, String object);

  /// No description provided for @startingIsland.
  ///
  /// In en, this message translates to:
  /// **'Starting island'**
  String get startingIsland;

  /// No description provided for @retakePretest.
  ///
  /// In en, this message translates to:
  /// **'Play the warm-up game again'**
  String get retakePretest;

  /// No description provided for @placementNowAt.
  ///
  /// In en, this message translates to:
  /// **'Now at: {island}'**
  String placementNowAt(String island);

  /// No description provided for @placementNotYet.
  ///
  /// In en, this message translates to:
  /// **'Warm-up game not played yet'**
  String get placementNotYet;

  /// No description provided for @setByParent.
  ///
  /// In en, this message translates to:
  /// **'set by a grown-up'**
  String get setByParent;

  /// No description provided for @cheerCelebrate1.
  ///
  /// In en, this message translates to:
  /// **'Great!'**
  String get cheerCelebrate1;

  /// No description provided for @cheerCelebrate2.
  ///
  /// In en, this message translates to:
  /// **'Awesome!'**
  String get cheerCelebrate2;

  /// No description provided for @cheerCelebrate3.
  ///
  /// In en, this message translates to:
  /// **'You got it!'**
  String get cheerCelebrate3;

  /// No description provided for @cheerCelebrate4.
  ///
  /// In en, this message translates to:
  /// **'Super!'**
  String get cheerCelebrate4;

  /// No description provided for @cheerCelebrate5.
  ///
  /// In en, this message translates to:
  /// **'Wow, well done!'**
  String get cheerCelebrate5;

  /// No description provided for @cheerCelebrate6.
  ///
  /// In en, this message translates to:
  /// **'Fantastic!'**
  String get cheerCelebrate6;

  /// No description provided for @cheerEncourage1.
  ///
  /// In en, this message translates to:
  /// **'Good thinking!'**
  String get cheerEncourage1;

  /// No description provided for @cheerEncourage2.
  ///
  /// In en, this message translates to:
  /// **'Nice try!'**
  String get cheerEncourage2;

  /// No description provided for @cheerEncourage3.
  ///
  /// In en, this message translates to:
  /// **'Let\'s keep going!'**
  String get cheerEncourage3;

  /// No description provided for @cheerEncourage4.
  ///
  /// In en, this message translates to:
  /// **'Thanks for trying!'**
  String get cheerEncourage4;

  /// No description provided for @cheerEncourage5.
  ///
  /// In en, this message translates to:
  /// **'You\'re doing great!'**
  String get cheerEncourage5;

  /// No description provided for @donateExplainer.
  ///
  /// In en, this message translates to:
  /// **'Coba Lagi is free. A donation of any size unlocks sponsor features for your family and helps us build more adventures.'**
  String get donateExplainer;

  /// No description provided for @donateUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Donations aren\'t available on this device.'**
  String get donateUnavailable;

  /// No description provided for @restoreDonation.
  ///
  /// In en, this message translates to:
  /// **'Restore an earlier donation'**
  String get restoreDonation;

  /// Opens a field for a code that unlocks the sponsor plan without a donation.
  ///
  /// In en, this message translates to:
  /// **'Have a code?'**
  String get haveUnlockCode;

  /// No description provided for @unlockCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get unlockCode;

  /// No description provided for @useUnlockCode.
  ///
  /// In en, this message translates to:
  /// **'Use code'**
  String get useUnlockCode;

  /// No description provided for @unlockCodeRejected.
  ///
  /// In en, this message translates to:
  /// **'That code doesn\'t work. Check it and try again.'**
  String get unlockCodeRejected;

  /// No description provided for @thanksForSupport.
  ///
  /// In en, this message translates to:
  /// **'Thank you for supporting Coba Lagi!'**
  String get thanksForSupport;

  /// No description provided for @playGoal.
  ///
  /// In en, this message translates to:
  /// **'Help me reach the flag!'**
  String get playGoal;

  /// No description provided for @playGoalStars.
  ///
  /// In en, this message translates to:
  /// **'Collect all the stars, then go to the flag!'**
  String get playGoalStars;

  /// No description provided for @playGoalLoops.
  ///
  /// In en, this message translates to:
  /// **'Use the repeat block to reach the flag!'**
  String get playGoalLoops;

  /// No description provided for @playGoalFunctions.
  ///
  /// In en, this message translates to:
  /// **'Fill the star block, then use it again and again to reach the flag!'**
  String get playGoalFunctions;

  /// No description provided for @playHowTo.
  ///
  /// In en, this message translates to:
  /// **'Drag a block into the white box, then press Go!'**
  String get playHowTo;

  /// No description provided for @backToIsland.
  ///
  /// In en, this message translates to:
  /// **'Back to the island'**
  String get backToIsland;

  /// No description provided for @continueAdventure.
  ///
  /// In en, this message translates to:
  /// **'Continue the adventure'**
  String get continueAdventure;

  /// No description provided for @levelNumber.
  ///
  /// In en, this message translates to:
  /// **'Level {number}'**
  String levelNumber(int number);

  /// No description provided for @levelLocked.
  ///
  /// In en, this message translates to:
  /// **'Not open yet'**
  String get levelLocked;

  /// No description provided for @answerWas.
  ///
  /// In en, this message translates to:
  /// **'The answer is this one!'**
  String get answerWas;

  /// No description provided for @conceptConditions.
  ///
  /// In en, this message translates to:
  /// **'Look ahead'**
  String get conceptConditions;

  /// No description provided for @blockUntilGoal.
  ///
  /// In en, this message translates to:
  /// **'Repeat until the flag'**
  String get blockUntilGoal;

  /// No description provided for @blockIfPathClear.
  ///
  /// In en, this message translates to:
  /// **'If clear'**
  String get blockIfPathClear;

  /// No description provided for @playGoalConditions.
  ///
  /// In en, this message translates to:
  /// **'Look ahead! Put a move inside the eye block. It moves only when the path is clear.'**
  String get playGoalConditions;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'An update is available'**
  String get updateAvailableTitle;

  /// No description provided for @updateAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'A newer version of Coba Lagi is ready. Ask a grown-up to help update the app.'**
  String get updateAvailableBody;

  /// No description provided for @updateWithParent.
  ///
  /// In en, this message translates to:
  /// **'Ask a grown-up to update'**
  String get updateWithParent;

  /// No description provided for @updateContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue playing'**
  String get updateContinue;

  /// No description provided for @updateOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'The update could not be opened. You can try again or keep playing.'**
  String get updateOpenFailed;

  /// No description provided for @codeTab.
  ///
  /// In en, this message translates to:
  /// **'Code tab'**
  String get codeTab;

  /// No description provided for @codeTabHint.
  ///
  /// In en, this message translates to:
  /// **'Lets this child type code as well as use picture blocks. The warm-up game turns it on for readers.'**
  String get codeTabHint;

  /// No description provided for @editorBlocks.
  ///
  /// In en, this message translates to:
  /// **'Blocks'**
  String get editorBlocks;

  /// No description provided for @editorCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get editorCode;

  /// No description provided for @codeDrafts.
  ///
  /// In en, this message translates to:
  /// **'Each editor keeps its own draft. Your first code draft comes from your blocks.'**
  String get codeDrafts;

  /// No description provided for @codeHelp.
  ///
  /// In en, this message translates to:
  /// **'Code guide'**
  String get codeHelp;

  /// No description provided for @codeSource.
  ///
  /// In en, this message translates to:
  /// **'Your code'**
  String get codeSource;

  /// No description provided for @codeGuide.
  ///
  /// In en, this message translates to:
  /// **'Tap a command to add it, or type it yourself. Keep the command names as shown in either language. End actions with (); and put the contents of repeats and checks between opening and closing braces. Repeat counts are 1–9. Define your Magic Block with define star, then use star(); to run it. // starts a comment. Each command counts as one block, including commands inside braces. Save a number with steps = 3; and use move(steps); to move that many cells. The number stays until you save a new one. Save it before using it. until_flag repeats what is inside its braces until your friend reaches the flag, with no count.'**
  String get codeGuide;

  /// No description provided for @codeSyntax.
  ///
  /// In en, this message translates to:
  /// **'Check the command name, parentheses, braces and semicolon.'**
  String get codeSyntax;

  /// No description provided for @codeNumber.
  ///
  /// In en, this message translates to:
  /// **'Choose a number from 1 to 9.'**
  String get codeNumber;

  /// No description provided for @codeDuplicateStar.
  ///
  /// In en, this message translates to:
  /// **'Keep just one define star section.'**
  String get codeDuplicateStar;

  /// No description provided for @codeNestedStar.
  ///
  /// In en, this message translates to:
  /// **'Put define star outside repeats and checks.'**
  String get codeNestedStar;

  /// No description provided for @codeTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Try a shorter program with fewer nested sections.'**
  String get codeTooLarge;

  /// No description provided for @codeDisallowed.
  ///
  /// In en, this message translates to:
  /// **'Use the commands shown for this puzzle.'**
  String get codeDisallowed;

  /// No description provided for @codeLimit.
  ///
  /// In en, this message translates to:
  /// **'Try fewer commands to fit the block limit.'**
  String get codeLimit;

  /// No description provided for @codeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add a command inside the braces.'**
  String get codeEmptyBody;

  /// No description provided for @codeEmptyStar.
  ///
  /// In en, this message translates to:
  /// **'Add commands to define star before using star();.'**
  String get codeEmptyStar;

  /// No description provided for @codeRecursiveStar.
  ///
  /// In en, this message translates to:
  /// **'Use moves, turns, repeats or checks inside define star.'**
  String get codeRecursiveStar;

  /// No description provided for @codeReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to run'**
  String get codeReady;

  /// No description provided for @codeStart.
  ///
  /// In en, this message translates to:
  /// **'Add a command to begin.'**
  String get codeStart;

  /// No description provided for @codeLine.
  ///
  /// In en, this message translates to:
  /// **'Line {line}: {message}'**
  String codeLine(int line, String message);

  /// No description provided for @codeRunningLine.
  ///
  /// In en, this message translates to:
  /// **'Running line {line}'**
  String codeRunningLine(int line);

  /// No description provided for @codeDefineStar.
  ///
  /// In en, this message translates to:
  /// **'Define my block'**
  String get codeDefineStar;

  /// No description provided for @conceptUntil.
  ///
  /// In en, this message translates to:
  /// **'Until the flag'**
  String get conceptUntil;

  /// No description provided for @playGoalUntil.
  ///
  /// In en, this message translates to:
  /// **'Use repeat until the flag: it keeps going by itself, so you don\'t need to count!'**
  String get playGoalUntil;

  /// No description provided for @conceptDebugging.
  ///
  /// In en, this message translates to:
  /// **'Fix it!'**
  String get conceptDebugging;

  /// No description provided for @playGoalDebugging.
  ///
  /// In en, this message translates to:
  /// **'Oops, these blocks aren\'t quite right yet! Press Go, watch what happens, then fix them.'**
  String get playGoalDebugging;

  /// No description provided for @conceptVariables.
  ///
  /// In en, this message translates to:
  /// **'Step Box'**
  String get conceptVariables;

  /// No description provided for @blockSetSteps.
  ///
  /// In en, this message translates to:
  /// **'Save steps'**
  String get blockSetSteps;

  /// No description provided for @blockMoveSteps.
  ///
  /// In en, this message translates to:
  /// **'Use steps'**
  String get blockMoveSteps;

  /// No description provided for @stepsFewer.
  ///
  /// In en, this message translates to:
  /// **'Save a smaller number'**
  String get stepsFewer;

  /// No description provided for @stepsMore.
  ///
  /// In en, this message translates to:
  /// **'Save a bigger number'**
  String get stepsMore;

  /// No description provided for @playGoalVariables.
  ///
  /// In en, this message translates to:
  /// **'Save a number in your Step Box, then use it to move that many steps! You can use the number again or change it. Reach the flag and collect every star.'**
  String get playGoalVariables;

  /// No description provided for @stepBoxValue.
  ///
  /// In en, this message translates to:
  /// **'Step Box: {value}'**
  String stepBoxValue(String value);

  /// No description provided for @codeUnsetSteps.
  ///
  /// In en, this message translates to:
  /// **'Save a number with steps = 2; before using move(steps);.'**
  String get codeUnsetSteps;

  /// No description provided for @variableHint.
  ///
  /// In en, this message translates to:
  /// **'Save a number first, then use the box to move. The number stays until you change it.'**
  String get variableHint;

  /// No description provided for @tutorialTitle.
  ///
  /// In en, this message translates to:
  /// **'Watch me!'**
  String get tutorialTitle;

  /// No description provided for @tutorialWatchAgain.
  ///
  /// In en, this message translates to:
  /// **'Watch again'**
  String get tutorialWatchAgain;

  /// No description provided for @tutorialLetsPlay.
  ///
  /// In en, this message translates to:
  /// **'Let\'s play!'**
  String get tutorialLetsPlay;

  /// No description provided for @tutorialSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get tutorialSkip;

  /// No description provided for @watchHow.
  ///
  /// In en, this message translates to:
  /// **'Watch how'**
  String get watchHow;

  /// No description provided for @tutorialDirections.
  ///
  /// In en, this message translates to:
  /// **'Tap the arrow blocks to tell your friend where to go: forward, turn left, turn right. Then press Go!'**
  String get tutorialDirections;

  /// No description provided for @tutorialSequencing.
  ///
  /// In en, this message translates to:
  /// **'Put the steps in order, one after another, all the way to the flag.'**
  String get tutorialSequencing;

  /// No description provided for @tutorialLoops.
  ///
  /// In en, this message translates to:
  /// **'The same steps again and again? Put them in the repeat block, and choose how many times!'**
  String get tutorialLoops;

  /// No description provided for @tutorialFunctions.
  ///
  /// In en, this message translates to:
  /// **'Build your own magic block in the star row. Then use the star again and again!'**
  String get tutorialFunctions;

  /// No description provided for @tutorialConditions.
  ///
  /// In en, this message translates to:
  /// **'The eye block looks ahead. If the path is clear, your friend steps forward. If not, it waits.'**
  String get tutorialConditions;

  /// No description provided for @tutorialVariables.
  ///
  /// In en, this message translates to:
  /// **'Save a number in the Step Box. Then use steps to walk that many cells!'**
  String get tutorialVariables;

  /// No description provided for @tutorialDebugging.
  ///
  /// In en, this message translates to:
  /// **'These blocks aren\'t quite right. Press Go and watch. Then tap the block to fix, and tap the right one!'**
  String get tutorialDebugging;

  /// No description provided for @tutorialUntil.
  ///
  /// In en, this message translates to:
  /// **'Repeat until the flag keeps going by itself, so you never have to count!'**
  String get tutorialUntil;

  /// No description provided for @hintPattern.
  ///
  /// In en, this message translates to:
  /// **'These blocks come back again and again. Try the loop block!'**
  String get hintPattern;

  /// No description provided for @breakTitle.
  ///
  /// In en, this message translates to:
  /// **'Time for a break!'**
  String get breakTitle;

  /// No description provided for @breakBody.
  ///
  /// In en, this message translates to:
  /// **'You played really well. Rest your eyes, have a stretch, and come back later.'**
  String get breakBody;

  /// No description provided for @breakHome.
  ///
  /// In en, this message translates to:
  /// **'Back to players'**
  String get breakHome;

  /// No description provided for @breakContinue.
  ///
  /// In en, this message translates to:
  /// **'A grown-up can continue'**
  String get breakContinue;

  /// No description provided for @breakVoice.
  ///
  /// In en, this message translates to:
  /// **'Time for a break! You played really well. Rest your eyes, have a stretch, and come back later.'**
  String get breakVoice;

  /// No description provided for @breakReminder.
  ///
  /// In en, this message translates to:
  /// **'Break reminder'**
  String get breakReminder;

  /// No description provided for @breakReminderHint.
  ///
  /// In en, this message translates to:
  /// **'After this much puzzle time, your child is invited to take a break. Only a grown-up can continue.'**
  String get breakReminderHint;

  /// No description provided for @breakOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get breakOff;

  /// No description provided for @breakMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String breakMinutes(int minutes);

  /// No description provided for @nextIslandSoon.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One more puzzle to {island}!} other{Up to {count} more puzzles to {island}!}}'**
  String nextIslandSoon(int count, String island);

  /// No description provided for @conceptWarmUp.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get conceptWarmUp;

  /// No description provided for @warmUpCounting.
  ///
  /// In en, this message translates to:
  /// **'Counting'**
  String get warmUpCounting;

  /// No description provided for @warmUpColors.
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get warmUpColors;

  /// No description provided for @warmUpShapes.
  ///
  /// In en, this message translates to:
  /// **'Shapes'**
  String get warmUpShapes;

  /// No description provided for @warmUpPatterns.
  ///
  /// In en, this message translates to:
  /// **'Patterns'**
  String get warmUpPatterns;

  /// No description provided for @warmUpSides.
  ///
  /// In en, this message translates to:
  /// **'Left and right'**
  String get warmUpSides;

  /// No description provided for @warmUpSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get warmUpSteps;

  /// No description provided for @warmUpPick.
  ///
  /// In en, this message translates to:
  /// **'Pick a game!'**
  String get warmUpPick;

  /// No description provided for @warmUpDone.
  ///
  /// In en, this message translates to:
  /// **'You played so well! Play again?'**
  String get warmUpDone;

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playAgain;

  /// No description provided for @promptColorRed.
  ///
  /// In en, this message translates to:
  /// **'Tap the red one!'**
  String get promptColorRed;

  /// No description provided for @promptColorBlue.
  ///
  /// In en, this message translates to:
  /// **'Tap the blue one!'**
  String get promptColorBlue;

  /// No description provided for @promptColorGreen.
  ///
  /// In en, this message translates to:
  /// **'Tap the green one!'**
  String get promptColorGreen;

  /// No description provided for @promptColorYellow.
  ///
  /// In en, this message translates to:
  /// **'Tap the yellow one!'**
  String get promptColorYellow;

  /// No description provided for @promptShapeCircle.
  ///
  /// In en, this message translates to:
  /// **'Tap the circle!'**
  String get promptShapeCircle;

  /// No description provided for @promptShapeSquare.
  ///
  /// In en, this message translates to:
  /// **'Tap the square!'**
  String get promptShapeSquare;

  /// No description provided for @promptShapeTriangle.
  ///
  /// In en, this message translates to:
  /// **'Tap the triangle!'**
  String get promptShapeTriangle;

  /// No description provided for @promptShapeHeart.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart!'**
  String get promptShapeHeart;

  /// No description provided for @playLevel.
  ///
  /// In en, this message translates to:
  /// **'Play level {number}'**
  String playLevel(int number);

  /// No description provided for @stickerBook.
  ///
  /// In en, this message translates to:
  /// **'Sticker book'**
  String get stickerBook;

  /// No description provided for @stickerBookHello.
  ///
  /// In en, this message translates to:
  /// **'Look at all your stickers!'**
  String get stickerBookHello;

  /// No description provided for @stickersIslands.
  ///
  /// In en, this message translates to:
  /// **'Islands'**
  String get stickersIslands;

  /// No description provided for @stickerNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not earned yet'**
  String get stickerNotYet;

  /// No description provided for @blockIfElse.
  ///
  /// In en, this message translates to:
  /// **'If clear, otherwise'**
  String get blockIfElse;

  /// No description provided for @otherwiseRowClear.
  ///
  /// In en, this message translates to:
  /// **'When the path is clear'**
  String get otherwiseRowClear;

  /// No description provided for @otherwiseRowBlocked.
  ///
  /// In en, this message translates to:
  /// **'Otherwise'**
  String get otherwiseRowBlocked;

  /// No description provided for @conceptOtherwise.
  ///
  /// In en, this message translates to:
  /// **'Otherwise'**
  String get conceptOtherwise;

  /// No description provided for @playGoalOtherwise.
  ///
  /// In en, this message translates to:
  /// **'Use the eye block with two rows: if the path is clear, step. Otherwise, turn!'**
  String get playGoalOtherwise;

  /// No description provided for @tutorialOtherwise.
  ///
  /// In en, this message translates to:
  /// **'The eye looks ahead. If the path is clear, step. Otherwise, turn. Then it all repeats until the flag!'**
  String get tutorialOtherwise;

  /// No description provided for @starsEarned.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star of 3} other{{count} stars of 3}}'**
  String starsEarned(int count);
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
