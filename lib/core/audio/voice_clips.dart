/// Who says a clip, which picks its voice in `tool/elevenlabs.json`.
enum Speaker {
  /// Koba itself: tours, goals, hints, cheers, demos and its introduction.
  koba,

  /// The storyteller: warm-up questions, story narration and announcements.
  narrator,
}

/// Every voice clip the app plays, mapped to the ARB key of the words to
/// record. A clip lives at `assets/audio/<languageCode>/<id>.mp3`.
///
/// Pure Dart, so `tool/voice_script.dart` can export the recording script.
abstract final class VoiceClips {
  static const pretestWelcome = 'pretest_welcome';
  static const pretestReading = 'pretest_reading';
  static const pretestCounting = 'pretest_counting';
  static const pretestSideLeft = 'pretest_side_left';
  static const pretestSideRight = 'pretest_side_right';
  static const pretestTurnLeft = 'pretest_turn_left';
  static const pretestTurnRight = 'pretest_turn_right';
  static const pretestPattern = 'pretest_pattern';
  static const pretestSequencing = 'pretest_sequencing';
  static const pretestDone = 'pretest_done';
  static const pretestAnswerWas = 'pretest_answer_was';

  static const stickerBook = 'sticker_book';
  static const warmUpPick = 'warm_up_pick';
  static const warmUpDone = 'warm_up_done';

  /// "Tap the red one!" for a colour id of the vocabulary.
  static String warmUpColor(String color) => 'warm_up_color_$color';

  /// "Tap the circle!" for a pattern shape id.
  static String warmUpShape(String shape) => 'warm_up_shape_$shape';

  /// Colours and shapes with a Warm-up prompt clip.
  static const warmUpColors = ['red', 'blue', 'green', 'yellow'];
  static const warmUpShapes = ['circle', 'square', 'triangle', 'heart'];

  static const playGoal = 'play_goal';
  static const playGoalStars = 'play_goal_stars';
  static const playGoalLoops = 'play_goal_loops';
  static const playGoalFunctions = 'play_goal_functions';
  static const playGoalConditions = 'play_goal_conditions';
  static const playGoalVariables = 'play_goal_variables';
  static const playGoalDebugging = 'play_goal_debugging';
  static const playGoalUntil = 'play_goal_until';
  static const playGoalOtherwise = 'play_goal_otherwise';
  static const playHowTo = 'play_how_to';
  static const hintPattern = 'hint_pattern';
  static const hintAgain = 'hint_again';
  static const hintLookHere = 'hint_look_here';
  static const hintLookHereMany = 'hint_look_here_many';
  static const breakTime = 'break_time';

  static const tourPalette = 'tour_palette';
  static const tourProgram = 'tour_program';
  static const tourGo = 'tour_go';
  static const tourStep = 'tour_step';
  static const tourReset = 'tour_reset';
  static const tourHint = 'tour_hint';
  static const tourFollow = 'tour_follow';
  static const tourListen = 'tour_listen';
  static const tourWarmUpListen = 'tour_warm_up_listen';
  static const tourWarmUpAnswer = 'tour_warm_up_answer';
  static const tourWarmUpSteps = 'tour_warm_up_steps';
  static const tourBlockForward = 'tour_block_forward';
  static const tourBlockTurnLeft = 'tour_block_turn_left';
  static const tourBlockTurnRight = 'tour_block_turn_right';
  static const tourBlockRepeat = 'tour_block_repeat';
  static const tourBlockSetSteps = 'tour_block_set_steps';
  static const tourBlockMoveSteps = 'tour_block_move_steps';
  static const tourBlockIfPathClear = 'tour_block_if_path_clear';
  static const tourBlockIfElse = 'tour_block_if_else';
  static const tourBlockUntilGoal = 'tour_block_until_goal';
  static const tourBlockStar = 'tour_block_star';

  static const feedbackBumped = 'feedback_bumped';
  static const feedbackStoppedShort = 'feedback_stopped_short';
  static const feedbackMissedStars = 'feedback_missed_stars';
  static const feedbackTooManySteps = 'feedback_too_many_steps';

  static const decisionAdvance = 'decision_advance';
  static const decisionPractice = 'decision_practice';
  static const decisionReview = 'decision_review';
  static const decisionReturn = 'decision_return';
  static const decisionMapComplete = 'decision_map_complete';

  /// The Star fuel story's intro, line by line.
  static const storyIntroFly = 'story_intro_fly';
  static const storyIntroWind = 'story_intro_wind';
  static const storyIntroLand = 'story_intro_land';
  static const storyIntroBump = 'story_intro_bump';
  static const storyIntroHelp = 'story_intro_help';

  /// Koba as its ship takes off from a finished planet.
  static const storyFly = 'story_fly';

  /// The Star fuel story's arrival scenes, for the planets that have one:
  /// the narrator sets the scene, then Koba says why it needs the skill.
  static const arrivalConcepts = [
    'directions',
    'sequencing',
    'loops',
    'functions',
    'conditions',
  ];
  static String storyArrival(String concept) => 'story_arrival_$concept';
  static String storyArrivalKoba(String concept) =>
      'story_arrival_${concept}_koba';

  /// Number of phrases per cheer mood; must match the ARB keys
  /// `cheerCelebrate1..N` and `cheerEncourage1..N`.
  static const celebrateCount = 6;
  static const encourageCount = 5;

  static String cheer(String mood, int number) => 'cheer_${mood}_$number';

  /// The "Watch me!" demo's explanation for an island.
  static String tutorial(String conceptId) => 'tutorial_$conceptId';

  /// Islands with a demo explanation, in map order.
  static const tutorialConcepts = [
    'directions',
    'sequencing',
    'loops',
    'functions',
    'conditions',
    'variables',
    'debugging',
    'until',
    'otherwise',
  ];

  /// Clip id → ARB key.
  static final Map<String, String> all = {
    for (final c in tutorialConcepts)
      tutorial(c): 'tutorial${c[0].toUpperCase()}${c.substring(1)}',
    pretestWelcome: 'pretestWelcome',
    pretestReading: 'promptReading',
    pretestCounting: 'promptCounting',
    pretestSideLeft: 'promptSideLeft',
    pretestSideRight: 'promptSideRight',
    pretestTurnLeft: 'promptTurnLeft',
    pretestTurnRight: 'promptTurnRight',
    pretestPattern: 'promptPattern',
    pretestSequencing: 'promptSequencing',
    pretestDone: 'pretestDone',
    pretestAnswerWas: 'answerWas',
    stickerBook: 'stickerBookHello',
    warmUpPick: 'warmUpPick',
    warmUpDone: 'warmUpDone',
    for (final c in warmUpColors) warmUpColor(c): 'promptColor${_capital(c)}',
    for (final s in warmUpShapes) warmUpShape(s): 'promptShape${_capital(s)}',
    playGoal: 'playGoal',
    playGoalStars: 'playGoalStars',
    playGoalLoops: 'playGoalLoops',
    playGoalFunctions: 'playGoalFunctions',
    playGoalConditions: 'playGoalConditions',
    playGoalVariables: 'playGoalVariables',
    playGoalDebugging: 'playGoalDebugging',
    playGoalUntil: 'playGoalUntil',
    playGoalOtherwise: 'playGoalOtherwise',
    playHowTo: 'playHowTo',
    hintPattern: 'hintPattern',
    hintAgain: 'hintAgain',
    hintLookHere: 'hintLookHere',
    hintLookHereMany: 'hintLookHereMany',
    breakTime: 'breakVoice',
    tourPalette: 'tourPalette',
    tourProgram: 'tourProgram',
    tourGo: 'tourGo',
    tourStep: 'tourStep',
    tourReset: 'tourReset',
    tourHint: 'tourHint',
    tourFollow: 'tourFollow',
    tourListen: 'tourListen',
    tourWarmUpListen: 'tourWarmUpListen',
    tourWarmUpAnswer: 'tourWarmUpAnswer',
    tourWarmUpSteps: 'tourWarmUpSteps',
    tourBlockForward: 'tourBlockForward',
    tourBlockTurnLeft: 'tourBlockTurnLeft',
    tourBlockTurnRight: 'tourBlockTurnRight',
    tourBlockRepeat: 'tourBlockRepeat',
    tourBlockSetSteps: 'tourBlockSetSteps',
    tourBlockMoveSteps: 'tourBlockMoveSteps',
    tourBlockIfPathClear: 'tourBlockIfPathClear',
    tourBlockIfElse: 'tourBlockIfElse',
    tourBlockUntilGoal: 'tourBlockUntilGoal',
    tourBlockStar: 'tourBlockStar',
    feedbackBumped: 'feedbackBumped',
    feedbackStoppedShort: 'feedbackStoppedShort',
    feedbackMissedStars: 'feedbackMissedStars',
    feedbackTooManySteps: 'feedbackTooManySteps',
    decisionAdvance: 'decisionAdvance',
    decisionPractice: 'decisionPractice',
    decisionReview: 'decisionReview',
    decisionReturn: 'decisionReturn',
    decisionMapComplete: 'decisionMapComplete',
    storyIntroFly: 'storyIntroFly',
    storyIntroWind: 'storyIntroWind',
    storyIntroLand: 'storyIntroLand',
    storyIntroBump: 'storyIntroBump',
    storyIntroHelp: 'storyIntroHelp',
    storyFly: 'storyFly',
    for (final c in arrivalConcepts) ...{
      storyArrival(c): 'storyArrival${_capital(c)}',
      storyArrivalKoba(c): 'storyArrival${_capital(c)}Koba',
    },
    for (var i = 1; i <= celebrateCount; i++)
      cheer('celebrate', i): 'cheerCelebrate$i',
    for (var i = 1; i <= encourageCount; i++)
      cheer('encourage', i): 'cheerEncourage$i',
  };

  /// Clips the narrator says; every other clip in [all] is in [kobaSays].
  static final Set<String> narratorSays = {
    pretestReading,
    pretestCounting,
    pretestSideLeft,
    pretestSideRight,
    pretestTurnLeft,
    pretestTurnRight,
    pretestPattern,
    pretestSequencing,
    pretestDone,
    pretestAnswerWas,
    stickerBook,
    warmUpPick,
    warmUpDone,
    for (final c in warmUpColors) warmUpColor(c),
    for (final s in warmUpShapes) warmUpShape(s),
    breakTime,
    decisionAdvance,
    decisionPractice,
    decisionReview,
    decisionReturn,
    decisionMapComplete,
    storyIntroFly,
    storyIntroWind,
    storyIntroLand,
    for (final c in arrivalConcepts) storyArrival(c),
  };

  /// Clips Koba says.
  static final Set<String> kobaSays = {
    for (final c in tutorialConcepts) tutorial(c),
    pretestWelcome,
    playGoal,
    playGoalStars,
    playGoalLoops,
    playGoalFunctions,
    playGoalConditions,
    playGoalVariables,
    playGoalDebugging,
    playGoalUntil,
    playGoalOtherwise,
    playHowTo,
    hintPattern,
    hintAgain,
    hintLookHere,
    hintLookHereMany,
    tourPalette,
    tourProgram,
    tourGo,
    tourStep,
    tourReset,
    tourHint,
    tourFollow,
    tourListen,
    tourWarmUpListen,
    tourWarmUpAnswer,
    tourWarmUpSteps,
    tourBlockForward,
    tourBlockTurnLeft,
    tourBlockTurnRight,
    tourBlockRepeat,
    tourBlockSetSteps,
    tourBlockMoveSteps,
    tourBlockIfPathClear,
    tourBlockIfElse,
    tourBlockUntilGoal,
    tourBlockStar,
    feedbackBumped,
    feedbackStoppedShort,
    feedbackMissedStars,
    feedbackTooManySteps,
    storyIntroBump,
    storyIntroHelp,
    storyFly,
    for (final c in arrivalConcepts) storyArrivalKoba(c),
    for (var i = 1; i <= celebrateCount; i++) cheer('celebrate', i),
    for (var i = 1; i <= encourageCount; i++) cheer('encourage', i),
  };

  /// Who says clip [id]; every clip names its speaker in one of the sets.
  static Speaker speakerOf(String id) => kobaSays.contains(id)
      ? Speaker.koba
      : narratorSays.contains(id)
      ? Speaker.narrator
      : throw ArgumentError.value(id, 'id', 'no speaker');

  static String _capital(String id) =>
      '${id[0].toUpperCase()}${id.substring(1)}';
}
