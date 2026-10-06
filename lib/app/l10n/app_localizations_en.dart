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
  String get planFree => 'Regular: 1 player';

  @override
  String planFull(int count) {
    return 'Sponsor: up to $count players';
  }

  @override
  String appVersion(String version, String build) {
    return 'App version $version ($build)';
  }

  @override
  String progressTitle(String name) {
    return '$name\'s progress';
  }

  @override
  String get changeStartingIsland => 'Change starting island';

  @override
  String get progressThisWeek => 'Last 7 days';

  @override
  String get progressAllTime => 'Since the start';

  @override
  String progressPuzzles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count puzzles solved',
      one: '1 puzzle solved',
    );
    return '$_temp0';
  }

  @override
  String progressMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes of play',
      one: '1 minute of play',
    );
    return '$_temp0';
  }

  @override
  String progressLastPlayed(String date) {
    return 'Last played: $date';
  }

  @override
  String get progressNotPlayed => 'Hasn\'t finished a puzzle yet';

  @override
  String get progressIslands => 'Islands';

  @override
  String get statusNotStarted => 'Not started';

  @override
  String get statusPractising => 'Practising';

  @override
  String get statusMastered => 'Mastered';

  @override
  String progressLevels(int solved, int total) {
    return '$solved of $total levels solved';
  }

  @override
  String get progressSponsorOnly =>
      'Sponsors see the full progress report: puzzles solved, time played and progress on each island.';

  @override
  String get music => 'Background music';

  @override
  String get soundEffects => 'Sound effects';

  @override
  String get soundEffectsHint => 'Voices always play.';

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
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';

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
  String get blockStar => 'My block';

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
  String get conceptFunctions => 'Magic Block';

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
  String get skipPuzzle => 'Try a different one';

  @override
  String get hint => 'Show me the way';

  @override
  String get repeatMore => 'One more time';

  @override
  String get repeatFewer => 'One time fewer';

  @override
  String get dropBlocksHere => 'Put blocks here';

  @override
  String get pretestWelcome => 'Let\'s play a warm-up game!';

  @override
  String get pretestStart => 'Start';

  @override
  String get listenAgain => 'Listen again';

  @override
  String get promptReading => 'Which picture matches the words?';

  @override
  String get promptCounting => 'How many are there?';

  @override
  String get promptSideLeft => 'Tap the one on the left.';

  @override
  String get promptSideRight => 'Tap the one on the right.';

  @override
  String get promptTurnLeft =>
      'The arrow turns left. Which way does it point now?';

  @override
  String get promptTurnRight =>
      'The arrow turns right. Which way does it point now?';

  @override
  String get promptPattern => 'What comes next?';

  @override
  String get promptSequencing => 'Which steps reach the flag?';

  @override
  String get pretestDone => 'All done! Your adventure starts now.';

  @override
  String get startAdventure => 'Let\'s go!';

  @override
  String get wordSun => 'sun';

  @override
  String get wordStar => 'star';

  @override
  String get wordHouse => 'house';

  @override
  String get wordCar => 'car';

  @override
  String get wordTree => 'tree';

  @override
  String get wordBall => 'ball';

  @override
  String get wordFlower => 'flower';

  @override
  String get wordBoat => 'boat';

  @override
  String get wordBird => 'bird';

  @override
  String get wordCake => 'cake';

  @override
  String get colorRed => 'red';

  @override
  String get colorBlue => 'blue';

  @override
  String get colorGreen => 'green';

  @override
  String get colorYellow => 'yellow';

  @override
  String wordsWithColor(String color, String object) {
    return '$color $object';
  }

  @override
  String get startingIsland => 'Starting island';

  @override
  String get retakePretest => 'Play the warm-up game again';

  @override
  String placementNowAt(String island) {
    return 'Now at: $island';
  }

  @override
  String get placementNotYet => 'Warm-up game not played yet';

  @override
  String get setByParent => 'set by a grown-up';

  @override
  String get cheerCelebrate1 => 'Great!';

  @override
  String get cheerCelebrate2 => 'Awesome!';

  @override
  String get cheerCelebrate3 => 'You got it!';

  @override
  String get cheerCelebrate4 => 'Super!';

  @override
  String get cheerCelebrate5 => 'Wow, well done!';

  @override
  String get cheerCelebrate6 => 'Fantastic!';

  @override
  String get cheerEncourage1 => 'Good thinking!';

  @override
  String get cheerEncourage2 => 'Nice try!';

  @override
  String get cheerEncourage3 => 'Let\'s keep going!';

  @override
  String get cheerEncourage4 => 'Thanks for trying!';

  @override
  String get cheerEncourage5 => 'You\'re doing great!';

  @override
  String get donateExplainer =>
      'Coba Lagi is free. A donation of any size unlocks sponsor features for your family and helps us build more adventures.';

  @override
  String get donateUnavailable => 'Donations aren\'t available on this device.';

  @override
  String get restoreDonation => 'Restore an earlier donation';

  @override
  String get haveUnlockCode => 'Have a code?';

  @override
  String get unlockCode => 'Code';

  @override
  String get useUnlockCode => 'Use code';

  @override
  String get unlockCodeRejected =>
      'That code doesn\'t work. Check it and try again.';

  @override
  String get thanksForSupport => 'Thank you for supporting Coba Lagi!';

  @override
  String get playGoal => 'Help me reach the flag!';

  @override
  String get playGoalStars => 'Collect all the stars, then go to the flag!';

  @override
  String get playGoalLoops => 'Use the repeat block to reach the flag!';

  @override
  String get playGoalFunctions =>
      'Fill the star block, then use it again and again to reach the flag!';

  @override
  String get playHowTo => 'Drag a block into the white box, then press Go!';

  @override
  String get backToIsland => 'Back to the island';

  @override
  String get continueAdventure => 'Continue the adventure';

  @override
  String levelNumber(int number) {
    return 'Level $number';
  }

  @override
  String get levelLocked => 'Not open yet';

  @override
  String get answerWas => 'The answer is this one!';

  @override
  String get conceptConditions => 'Look ahead';

  @override
  String get blockIfPathClear => 'If clear';

  @override
  String get playGoalConditions =>
      'Look ahead! Put a move inside the eye block. It moves only when the path is clear.';

  @override
  String get updateAvailableTitle => 'An update is available';

  @override
  String get updateAvailableBody =>
      'A newer version of Coba Lagi is ready. Ask a grown-up to help update the app.';

  @override
  String get updateWithParent => 'Ask a grown-up to update';

  @override
  String get updateContinue => 'Continue playing';

  @override
  String get updateOpenFailed =>
      'The update could not be opened. You can try again or keep playing.';

  @override
  String get editorBlocks => 'Blocks';

  @override
  String get editorCode => 'Code';

  @override
  String get codeDrafts =>
      'Each editor keeps its own draft. Your first code draft comes from your blocks.';

  @override
  String get codeHelp => 'Code guide';

  @override
  String get codeSource => 'Your code';

  @override
  String get codeGuide =>
      'Tap a command to add it, or type it yourself. Keep the command names as shown in either language. End actions with (); and put the contents of repeats and checks between opening and closing braces. Repeat counts are 1–9. Define your Magic Block with define star, then use star(); to run it. // starts a comment. Each command counts as one block, including commands inside braces. Save a number with steps = 3; and use move(steps); to move that many cells. The number stays until you save a new one. Save it before using it.';

  @override
  String get codeSyntax =>
      'Check the command name, parentheses, braces and semicolon.';

  @override
  String get codeNumber => 'Choose a number from 1 to 9.';

  @override
  String get codeDuplicateStar => 'Keep just one define star section.';

  @override
  String get codeNestedStar => 'Put define star outside repeats and checks.';

  @override
  String get codeTooLarge =>
      'Try a shorter program with fewer nested sections.';

  @override
  String get codeDisallowed => 'Use the commands shown for this puzzle.';

  @override
  String get codeLimit => 'Try fewer commands to fit the block limit.';

  @override
  String get codeEmptyBody => 'Add a command inside the braces.';

  @override
  String get codeEmptyStar =>
      'Add commands to define star before using star();.';

  @override
  String get codeRecursiveStar =>
      'Use moves, turns, repeats or checks inside define star.';

  @override
  String get codeReady => 'Ready to run';

  @override
  String get codeStart => 'Add a command to begin.';

  @override
  String codeLine(int line, String message) {
    return 'Line $line: $message';
  }

  @override
  String codeRunningLine(int line) {
    return 'Running line $line';
  }

  @override
  String get codeDefineStar => 'Define my block';

  @override
  String get conceptVariables => 'Step Box';

  @override
  String get blockSetSteps => 'Save steps';

  @override
  String get blockMoveSteps => 'Use steps';

  @override
  String get stepsFewer => 'Save a smaller number';

  @override
  String get stepsMore => 'Save a bigger number';

  @override
  String get playGoalVariables =>
      'Save a number in your Step Box, then use it to move that many steps! You can use the number again or change it. Reach the flag and collect every star.';

  @override
  String stepBoxValue(String value) {
    return 'Step Box: $value';
  }

  @override
  String get codeUnsetSteps =>
      'Save a number with steps = 2; before using move(steps);.';

  @override
  String get variableHint =>
      'Save a number first, then use the box to move. The number stays until you change it.';
}
