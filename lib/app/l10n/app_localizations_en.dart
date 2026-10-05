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
    return 'Full version: up to $count players';
  }

  @override
  String get unlockFullVersion => 'Unlock full version';

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
}
