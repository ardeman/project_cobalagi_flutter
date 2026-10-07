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
  String get music => 'Musik latar';

  @override
  String get soundEffects => 'Efek suara';

  @override
  String get soundEffectsHint => 'Suara petunjuk tetap terdengar.';

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
  String get undo => 'Urungkan';

  @override
  String get redo => 'Kembalikan';

  @override
  String get clearBlocks => 'Hapus semua blok';

  @override
  String get removeBlock => 'Hapus blok ini';

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
  String get playHowTo => 'Seret blok ke kotak putih, lalu tekan Jalan!';

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

  @override
  String get conceptConditions => 'Lihat depan';

  @override
  String get blockUntilGoal => 'Ulangi sampai bendera';

  @override
  String get blockIfPathClear => 'Jika kosong';

  @override
  String get playGoalConditions =>
      'Lihat ke depan! Taruh balok maju di dalam balok mata. Ia maju hanya jika jalan di depan kosong.';

  @override
  String get updateAvailableTitle => 'Pembaruan tersedia';

  @override
  String get updateAvailableBody =>
      'Versi terbaru Coba Lagi sudah tersedia. Minta bantuan orang dewasa untuk memperbarui aplikasi.';

  @override
  String get updateWithParent => 'Minta bantuan untuk memperbarui';

  @override
  String get updateContinue => 'Lanjut bermain';

  @override
  String get updateOpenFailed =>
      'Pembaruan belum bisa dibuka. Coba lagi atau lanjut bermain.';

  @override
  String get codeTab => 'Tab Kode';

  @override
  String get codeTabHint =>
      'Anak bisa mengetik kode selain memakai blok bergambar. Permainan pemanasan menyalakannya untuk anak yang sudah bisa membaca.';

  @override
  String get editorBlocks => 'Blok';

  @override
  String get editorCode => 'Kode';

  @override
  String get codeDrafts =>
      'Setiap editor menyimpan draf sendiri. Draf kode pertama berasal dari blokmu.';

  @override
  String get codeHelp => 'Panduan kode';

  @override
  String get codeSource => 'Kodemu';

  @override
  String get codeGuide =>
      'Ketuk perintah untuk menambahkannya, atau ketik sendiri. Nama perintah tetap sama dalam kedua bahasa. Akhiri aksi dengan (); dan letakkan isi pengulangan serta pemeriksaan di antara kurung kurawal buka dan tutup. Jumlah pengulangan adalah 1–9. Buat Blok Ajaib dengan define star, lalu jalankan dengan star();. // memulai komentar. Setiap perintah dihitung sebagai satu blok, termasuk perintah di dalam kurung kurawal. Simpan angka dengan steps = 3; dan pakai move(steps); untuk maju sebanyak itu. Angka tetap sama sampai kamu menyimpan yang baru. Simpan sebelum memakainya. until_flag mengulang isi kurung kurawalnya sampai temanmu tiba di bendera, tanpa hitungan.';

  @override
  String get codeSyntax =>
      'Periksa nama perintah, tanda kurung, kurung kurawal, dan titik koma.';

  @override
  String get codeNumber => 'Pilih angka dari 1 sampai 9.';

  @override
  String get codeDuplicateStar => 'Gunakan satu bagian define star saja.';

  @override
  String get codeNestedStar =>
      'Letakkan define star di luar pengulangan dan pemeriksaan.';

  @override
  String get codeTooLarge =>
      'Coba program yang lebih pendek dengan lebih sedikit bagian bertingkat.';

  @override
  String get codeDisallowed =>
      'Gunakan perintah yang tersedia untuk teka-teki ini.';

  @override
  String get codeLimit => 'Coba kurangi perintah agar sesuai batas blok.';

  @override
  String get codeEmptyBody => 'Tambahkan perintah di dalam kurung kurawal.';

  @override
  String get codeEmptyStar =>
      'Tambahkan perintah ke define star sebelum memakai star();.';

  @override
  String get codeRecursiveStar =>
      'Gunakan langkah, belokan, pengulangan, atau pemeriksaan di dalam define star.';

  @override
  String get codeReady => 'Siap dijalankan';

  @override
  String get codeStart => 'Tambahkan perintah untuk mulai.';

  @override
  String codeLine(int line, String message) {
    return 'Baris $line: $message';
  }

  @override
  String codeRunningLine(int line) {
    return 'Menjalankan baris $line';
  }

  @override
  String get codeDefineStar => 'Buat blokku';

  @override
  String get conceptUntil => 'Sampai bendera';

  @override
  String get playGoalUntil =>
      'Pakai blok ulangi sampai bendera: blok itu terus jalan sendiri, jadi kamu tidak perlu menghitung!';

  @override
  String get conceptDebugging => 'Perbaiki!';

  @override
  String get playGoalDebugging =>
      'Ups, blok ini belum pas! Tekan Jalan, lihat apa yang terjadi, lalu betulkan.';

  @override
  String get conceptVariables => 'Kotak Langkah';

  @override
  String get blockSetSteps => 'Simpan langkah';

  @override
  String get blockMoveSteps => 'Pakai langkah';

  @override
  String get stepsFewer => 'Simpan angka lebih kecil';

  @override
  String get stepsMore => 'Simpan angka lebih besar';

  @override
  String get playGoalVariables =>
      'Simpan angka di Kotak Langkahmu, lalu pakai untuk maju sebanyak itu! Angkanya bisa dipakai lagi atau diganti. Sampai ke bendera dan kumpulkan semua bintang.';

  @override
  String stepBoxValue(String value) {
    return 'Kotak Langkah: $value';
  }

  @override
  String get codeUnsetSteps =>
      'Simpan angka dengan steps = 2; sebelum memakai move(steps);.';

  @override
  String get variableHint =>
      'Simpan angka dulu, lalu pakai kotak untuk maju. Angka tetap sama sampai kamu menggantinya.';

  @override
  String get tutorialTitle => 'Lihat aku!';

  @override
  String get tutorialWatchAgain => 'Lihat lagi';

  @override
  String get tutorialLetsPlay => 'Ayo main!';

  @override
  String get tutorialSkip => 'Lewati';

  @override
  String get watchHow => 'Lihat caranya';

  @override
  String get tutorialDirections =>
      'Ketuk blok panah untuk memberi tahu temanmu ke mana harus pergi: maju, belok kiri, belok kanan. Lalu tekan Jalan!';

  @override
  String get tutorialSequencing =>
      'Susun langkahnya berurutan, satu per satu, sampai ke bendera.';

  @override
  String get tutorialLoops =>
      'Langkahnya sama terus? Masukkan ke blok ulangi, lalu pilih berapa kali!';

  @override
  String get tutorialFunctions =>
      'Buat blok ajaibmu sendiri di baris bintang. Lalu pakai bintangnya berkali-kali!';

  @override
  String get tutorialConditions =>
      'Blok mata melihat ke depan. Kalau jalannya kosong, temanmu maju. Kalau tidak, ia menunggu.';

  @override
  String get tutorialVariables =>
      'Simpan angka di Kotak Langkah. Lalu pakai langkah untuk berjalan sebanyak itu!';

  @override
  String get tutorialDebugging =>
      'Blok ini belum pas. Tekan Jalan dan perhatikan. Lalu ketuk blok yang perlu dibetulkan, dan ketuk blok yang tepat!';

  @override
  String get tutorialUntil =>
      'Ulangi sampai bendera terus jalan sendiri, jadi kamu tidak perlu menghitung!';

  @override
  String get hintPattern =>
      'Blok-blok ini muncul lagi dan lagi. Coba pakai blok pengulang!';

  @override
  String get breakTitle => 'Waktunya istirahat!';

  @override
  String get breakBody =>
      'Kamu sudah bermain dengan hebat. Istirahatkan matamu, coba peregangan, lalu main lagi nanti.';

  @override
  String get breakHome => 'Kembali ke pemain';

  @override
  String get breakContinue => 'Orang dewasa bisa melanjutkan';

  @override
  String get breakVoice =>
      'Waktunya istirahat! Kamu sudah bermain dengan hebat. Istirahatkan matamu, coba peregangan, lalu main lagi nanti.';

  @override
  String get breakReminder => 'Pengingat istirahat';

  @override
  String get breakReminderHint =>
      'Setelah bermain teka-teki selama ini, anak diajak istirahat. Hanya orang dewasa yang bisa melanjutkan.';

  @override
  String get breakOff => 'Mati';

  @override
  String breakMinutes(int minutes) {
    return '$minutes mnt';
  }

  @override
  String nextIslandSoon(int count, String island) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Paling banyak $count teka-teki lagi menuju $island!',
      one: 'Satu teka-teki lagi menuju $island!',
    );
    return '$_temp0';
  }

  @override
  String get conceptWarmUp => 'Pemanasan';

  @override
  String get warmUpCounting => 'Berhitung';

  @override
  String get warmUpColors => 'Warna';

  @override
  String get warmUpShapes => 'Bentuk';

  @override
  String get warmUpPatterns => 'Pola';

  @override
  String get warmUpSides => 'Kiri dan kanan';

  @override
  String get warmUpSteps => 'Langkah';

  @override
  String get warmUpPick => 'Pilih permainan!';

  @override
  String get warmUpDone => 'Hebat sekali mainnya! Main lagi?';

  @override
  String get playAgain => 'Main lagi';

  @override
  String get promptColorRed => 'Ketuk yang merah!';

  @override
  String get promptColorBlue => 'Ketuk yang biru!';

  @override
  String get promptColorGreen => 'Ketuk yang hijau!';

  @override
  String get promptColorYellow => 'Ketuk yang kuning!';

  @override
  String get promptShapeCircle => 'Ketuk lingkaran!';

  @override
  String get promptShapeSquare => 'Ketuk persegi!';

  @override
  String get promptShapeTriangle => 'Ketuk segitiga!';

  @override
  String get promptShapeHeart => 'Ketuk hati!';

  @override
  String playLevel(int number) {
    return 'Main level $number';
  }
}
