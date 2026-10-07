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

  static const playGoal = 'play_goal';
  static const playGoalStars = 'play_goal_stars';
  static const playGoalLoops = 'play_goal_loops';
  static const playGoalFunctions = 'play_goal_functions';
  static const playGoalConditions = 'play_goal_conditions';
  static const playGoalVariables = 'play_goal_variables';
  static const playGoalDebugging = 'play_goal_debugging';
  static const playGoalUntil = 'play_goal_until';
  static const playHowTo = 'play_how_to';
  static const hintPattern = 'hint_pattern';
  static const breakTime = 'break_time';

  static const feedbackBumped = 'feedback_bumped';
  static const feedbackStoppedShort = 'feedback_stopped_short';
  static const feedbackMissedStars = 'feedback_missed_stars';
  static const feedbackTooManySteps = 'feedback_too_many_steps';

  static const decisionAdvance = 'decision_advance';
  static const decisionPractice = 'decision_practice';
  static const decisionReview = 'decision_review';
  static const decisionReturn = 'decision_return';
  static const decisionMapComplete = 'decision_map_complete';

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
    playGoal: 'playGoal',
    playGoalStars: 'playGoalStars',
    playGoalLoops: 'playGoalLoops',
    playGoalFunctions: 'playGoalFunctions',
    playGoalConditions: 'playGoalConditions',
    playGoalVariables: 'playGoalVariables',
    playGoalDebugging: 'playGoalDebugging',
    playGoalUntil: 'playGoalUntil',
    playHowTo: 'playHowTo',
    hintPattern: 'hintPattern',
    breakTime: 'breakVoice',
    feedbackBumped: 'feedbackBumped',
    feedbackStoppedShort: 'feedbackStoppedShort',
    feedbackMissedStars: 'feedbackMissedStars',
    feedbackTooManySteps: 'feedbackTooManySteps',
    decisionAdvance: 'decisionAdvance',
    decisionPractice: 'decisionPractice',
    decisionReview: 'decisionReview',
    decisionReturn: 'decisionReturn',
    decisionMapComplete: 'decisionMapComplete',
    for (var i = 1; i <= celebrateCount; i++)
      cheer('celebrate', i): 'cheerCelebrate$i',
    for (var i = 1; i <= encourageCount; i++)
      cheer('encourage', i): 'cheerEncourage$i',
  };
}
