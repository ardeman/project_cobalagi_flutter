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
  String get planFree => 'Reguler: 1 pemain';

  @override
  String planFull(int count) {
    return 'Sponsor: hingga $count pemain';
  }

  @override
  String appVersion(String version, String build) {
    return 'Versi aplikasi $version ($build)';
  }

  @override
  String progressTitle(String name) {
    return 'Perkembangan $name';
  }

  @override
  String get changeStartingIsland => 'Ubah pulau awal';

  @override
  String get progressThisWeek => '7 hari terakhir';

  @override
  String get progressAllTime => 'Sejak awal';

  @override
  String progressPuzzles(int count) {
    return '$count teka-teki selesai';
  }

  @override
  String progressMinutes(int count) {
    return '$count menit bermain';
  }

  @override
  String progressLastPlayed(String date) {
    return 'Terakhir main: $date';
  }

  @override
  String get progressNotPlayed => 'Belum menyelesaikan teka-teki';

  @override
  String get progressIslands => 'Pulau';

  @override
  String get statusNotStarted => 'Belum mulai';

  @override
  String get statusPractising => 'Sedang berlatih';

  @override
  String get statusMastered => 'Sudah dikuasai';

  @override
  String progressLevels(int solved, int total) {
    return '$solved dari $total level selesai';
  }

  @override
  String get progressSponsorOnly =>
      'Sponsor bisa melihat laporan perkembangan lengkap: teka-teki yang selesai, waktu bermain, dan kemajuan di setiap pulau.';

  @override
  String get supportCobaLagi => 'Dukung Coba Lagi';

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
  String get blockStar => 'Blok buatanku';

  @override
  String get nextLevel => 'Lanjut';

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
  String get home => 'Beranda';

  @override
  String get conceptDirections => 'Arah';

  @override
  String get conceptSequencing => 'Langkah demi langkah';

  @override
  String get conceptLoops => 'Perulangan';

  @override
  String get conceptFunctions => 'Blok Ajaib';

  @override
  String get decisionAdvance => 'Pulau baru terbuka!';

  @override
  String get decisionPractice => 'Ayo coba yang lain!';

  @override
  String get bonusAdventure => 'Petualangan bonus!';

  @override
  String get decisionReview => 'Ayo cari harta karun di pulau sebelumnya.';

  @override
  String get decisionReturn => 'Kembali ke petualanganmu!';

  @override
  String get decisionMapComplete => 'Kamu sudah menjelajahi semua pulau!';

  @override
  String get skipPuzzle => 'Coba yang lain';

  @override
  String get hint => 'Tunjukkan jalannya';

  @override
  String get repeatMore => 'Tambah satu kali';

  @override
  String get repeatFewer => 'Kurangi satu kali';

  @override
  String get dropBlocksHere => 'Taruh blok di sini';

  @override
  String get pretestWelcome => 'Ayo main pemanasan dulu!';

  @override
  String get pretestStart => 'Mulai';

  @override
  String get listenAgain => 'Dengar lagi';

  @override
  String get promptReading => 'Gambar mana yang cocok dengan tulisan ini?';

  @override
  String get promptCounting => 'Ada berapa?';

  @override
  String get promptSideLeft => 'Sentuh yang di sebelah kiri.';

  @override
  String get promptSideRight => 'Sentuh yang di sebelah kanan.';

  @override
  String get promptTurnLeft => 'Panah belok kiri. Sekarang menunjuk ke mana?';

  @override
  String get promptTurnRight => 'Panah belok kanan. Sekarang menunjuk ke mana?';

  @override
  String get promptPattern => 'Apa yang selanjutnya?';

  @override
  String get promptSequencing => 'Langkah mana yang sampai ke bendera?';

  @override
  String get pretestDone => 'Selesai! Petualanganmu dimulai sekarang.';

  @override
  String get startAdventure => 'Ayo!';

  @override
  String get wordSun => 'matahari';

  @override
  String get wordStar => 'bintang';

  @override
  String get wordHouse => 'rumah';

  @override
  String get wordCar => 'mobil';

  @override
  String get wordTree => 'pohon';

  @override
  String get wordBall => 'bola';

  @override
  String get wordFlower => 'bunga';

  @override
  String get wordBoat => 'perahu';

  @override
  String get wordBird => 'burung';

  @override
  String get wordCake => 'kue';

  @override
  String get colorRed => 'merah';

  @override
  String get colorBlue => 'biru';

  @override
  String get colorGreen => 'hijau';

  @override
  String get colorYellow => 'kuning';

  @override
  String wordsWithColor(String color, String object) {
    return '$object $color';
  }

  @override
  String get startingIsland => 'Pulau awal';

  @override
  String get retakePretest => 'Main pemanasan lagi';

  @override
  String placementNowAt(String island) {
    return 'Sekarang di: $island';
  }

  @override
  String get placementNotYet => 'Belum main pemanasan';

  @override
  String get setByParent => 'diatur orang dewasa';

  @override
  String get cheerCelebrate1 => 'Hebat!';

  @override
  String get cheerCelebrate2 => 'Keren!';

  @override
  String get cheerCelebrate3 => 'Kamu berhasil!';

  @override
  String get cheerCelebrate4 => 'Super!';

  @override
  String get cheerCelebrate5 => 'Wah, bagus sekali!';

  @override
  String get cheerCelebrate6 => 'Luar biasa!';

  @override
  String get cheerEncourage1 => 'Pemikiran yang bagus!';

  @override
  String get cheerEncourage2 => 'Usaha yang bagus!';

  @override
  String get cheerEncourage3 => 'Ayo lanjut!';

  @override
  String get cheerEncourage4 => 'Terima kasih sudah mencoba!';

  @override
  String get cheerEncourage5 => 'Kamu hebat!';

  @override
  String get donateExplainer =>
      'Coba Lagi gratis. Donasi berapa pun membuka fitur sponsor untuk keluargamu dan membantu kami membuat lebih banyak petualangan.';

  @override
  String get donateUnavailable => 'Donasi tidak tersedia di perangkat ini.';

  @override
  String get restoreDonation => 'Pulihkan donasi sebelumnya';

  @override
  String get haveUnlockCode => 'Punya kode?';

  @override
  String get unlockCode => 'Kode';

  @override
  String get useUnlockCode => 'Pakai kode';

  @override
  String get unlockCodeRejected =>
      'Kode itu tidak berlaku. Periksa lagi, lalu coba sekali lagi.';

  @override
  String get thanksForSupport => 'Terima kasih sudah mendukung Coba Lagi!';

  @override
  String get playGoal => 'Bantu aku sampai ke bendera!';

  @override
  String get playGoalStars => 'Kumpulkan semua bintang, lalu ke bendera!';

  @override
  String get playGoalLoops => 'Pakai blok ulangi untuk sampai ke bendera!';

  @override
  String get playGoalFunctions =>
      'Isi blok bintang, lalu pakai berkali-kali untuk sampai ke bendera!';

  @override
  String get backToIsland => 'Kembali ke pulau';

  @override
  String get continueAdventure => 'Lanjutkan petualangan';

  @override
  String levelNumber(int number) {
    return 'Level $number';
  }

  @override
  String get levelLocked => 'Belum terbuka';

  @override
  String get answerWas => 'Jawabannya yang ini!';
}
