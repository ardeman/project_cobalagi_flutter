// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Coba Lagi';

  @override
  String get whoIsPlaying => 'Siapa yang main?';

  @override
  String get addPlayer => 'Pemain baru';

  @override
  String get nickname => 'Nama panggilan';

  @override
  String get chooseAvatar => 'Pilih teman';

  @override
  String get save => 'Simpan';

  @override
  String get cancel => 'Batal';

  @override
  String get delete => 'Hapus';

  @override
  String get ok => 'Oke';

  @override
  String greeting(String name) {
    return 'Hai, $name!';
  }

  @override
  String get play => 'Main';

  @override
  String get comingSoon => 'Segera hadir!';

  @override
  String get askAGrownUp => 'Minta bantuan orang dewasa';

  @override
  String parentGateQuestion(int a, int b) {
    return 'Berapa $a × $b?';
  }

  @override
  String get parentGateWrong => 'Belum tepat. Coba lagi.';

  @override
  String get parentArea => 'Area orang tua';

  @override
  String get language => 'Bahasa';

  @override
  String get languageSystem => 'Ikuti perangkat';

  @override
  String get languageIndonesian => 'Bahasa Indonesia';

  @override
  String get languageEnglish => 'English';

  @override
  String get plan => 'Versi';

  @override
  String get planFree => 'Gratis: 1 pemain';

  @override
  String planFull(int count) {
    return 'Versi lengkap: hingga $count pemain';
  }

  @override
  String get unlockFullVersion => 'Buka versi lengkap';

  @override
  String get debugPlanOverride => 'Debug: pakai versi lengkap';

  @override
  String get players => 'Pemain';

  @override
  String deletePlayerConfirm(String name) {
    return 'Hapus $name beserta semua progresnya?';
  }

  @override
  String get playerLimitReached =>
      'Versi ini hanya untuk satu pemain. Minta bantuan orang dewasa.';

  @override
  String get levels => 'Level';

  @override
  String levelNumber(int number) {
    return 'Level $number';
  }

  @override
  String get run => 'Jalan!';

  @override
  String get step => 'Satu langkah';

  @override
  String get reset => 'Mulai lagi';

  @override
  String get undo => 'Hapus blok terakhir';

  @override
  String get clearBlocks => 'Hapus semua blok';

  @override
  String get blockForward => 'Maju';

  @override
  String get blockTurnLeft => 'Belok kiri';

  @override
  String get blockTurnRight => 'Belok kanan';

  @override
  String get blockRepeat => 'Ulangi';

  @override
  String get successTitle => 'Hore!';

  @override
  String get nextLevel => 'Lanjut';

  @override
  String get playAgain => 'Main lagi';

  @override
  String get tryAgain => 'Coba lagi!';

  @override
  String get feedbackBumped => 'Ups, ada yang menghalangi.';

  @override
  String get feedbackStoppedShort => 'Hampir! Terus jalan sampai bendera.';

  @override
  String get feedbackMissedStars => 'Kumpulkan semua bintang dulu.';

  @override
  String get feedbackTooManySteps =>
      'Langkahnya terlalu banyak! Coba lebih sedikit.';

  @override
  String get allLevelsDone => 'Kamu sudah menyelesaikan semua level!';

  @override
  String get home => 'Beranda';
}
