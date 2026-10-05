// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Coba Lagi';

  @override
  String get whoIsPlaying => 'Who\'s playing?';

  @override
  String get addPlayer => 'New player';

  @override
  String get nickname => 'Nickname';

  @override
  String get chooseAvatar => 'Choose a friend';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get ok => 'OK';

  @override
  String greeting(String name) {
    return 'Hi, $name!';
  }

  @override
  String get play => 'Play';

  @override
  String get comingSoon => 'Coming soon!';

  @override
  String get askAGrownUp => 'Ask a grown-up';

  @override
  String parentGateQuestion(int a, int b) {
    return 'What is $a × $b?';
  }

  @override
  String get parentGateWrong => 'Not quite. Try again.';

  @override
  String get parentArea => 'Parent area';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Same as device';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get languageEnglish => 'English';

  @override
  String get plan => 'Version';

  @override
  String get planFree => 'Free: 1 player';

  @override
  String planFull(int count) {
    return 'Supporter: up to $count players';
  }

  @override
  String get supportCobaLagi => 'Support Coba Lagi';

  @override
  String get debugPlanOverride => 'Debug: use full version';

  @override
  String get players => 'Players';

  @override
  String deletePlayerConfirm(String name) {
    return 'Delete $name and all their progress?';
  }

  @override
  String get playerLimitReached =>
      'This version has room for one player. Ask a grown-up.';

  @override
  String get run => 'Go!';

  @override
  String get step => 'One step';

  @override
  String get reset => 'Start over';

  @override
  String get undo => 'Remove last block';

  @override
  String get clearBlocks => 'Remove all blocks';

  @override
  String get blockForward => 'Forward';

  @override
  String get blockTurnLeft => 'Turn left';

  @override
  String get blockTurnRight => 'Turn right';

  @override
  String get blockRepeat => 'Repeat';

  @override
  String get successTitle => 'Hooray!';

  @override
  String get nextLevel => 'Next';

  @override
  String get tryAgain => 'Try again!';

  @override
  String get feedbackBumped => 'Oops, something is in the way.';

  @override
  String get feedbackStoppedShort => 'Almost! Keep going to the flag.';

  @override
  String get feedbackMissedStars => 'Collect all the stars first.';

  @override
  String get feedbackTooManySteps => 'That\'s a lot of steps! Try fewer.';

  @override
  String get home => 'Home';

  @override
  String get conceptDirections => 'Directions';

  @override
  String get conceptSequencing => 'Step by step';

  @override
  String get conceptLoops => 'Loops';

  @override
  String get decisionAdvance => 'New island unlocked!';

  @override
  String get decisionPractice => 'Let\'s try another one!';

  @override
  String get bonusAdventure => 'Bonus adventure!';

  @override
  String get decisionReview => 'Let\'s hunt for treasure on an earlier island.';

  @override
  String get decisionReturn => 'Back to your adventure!';

  @override
  String get decisionMapComplete => 'You explored every island!';

  @override
  String get goodTry => 'Good try!';

  @override
  String get skipPuzzle => 'Try a different one';

  @override
  String get hint => 'Show me the way';

  @override
  String get repeatMore => 'One more time';

  @override
  String get repeatFewer => 'One time fewer';

  @override
  String get dropBlocksHere => 'Put blocks here';
}
