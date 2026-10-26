// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Minangkabau (`min`).
class AppLocalizationsMin extends AppLocalizations {
  AppLocalizationsMin([String locale = 'min']) : super(locale);

  @override
  String get appTitle => 'Coba Lagi';

  @override
  String get whoIsPlaying => 'Sia nan main?';

  @override
  String get editPlayer => 'Ganti pamain';

  @override
  String get addPlayer => 'Pamain baru';

  @override
  String get nickname => 'Namo panggilan';

  @override
  String get chooseAvatar => 'Piliah gambar';

  @override
  String get save => 'Simpan';

  @override
  String get cancel => 'Batal';

  @override
  String get delete => 'Hapuih';

  @override
  String get ok => 'Oke';

  @override
  String greeting(String name) {
    return 'Hai, $name!';
  }

  @override
  String get play => 'Main';

  @override
  String get askAGrownUp => 'Mintak tolong ka urang gadang';

  @override
  String parentGateQuestion(int a, int b) {
    return 'Bara $a × $b?';
  }

  @override
  String get parentGateWrong => 'Alun pas. Cubo baliak.';

  @override
  String get parentArea => 'Tampek urang tuo';

  @override
  String get language => 'Baso';

  @override
  String get languageSystem => 'Ikuik parangkaik';

  @override
  String get plan => 'Versi';

  @override
  String get planFree => 'Biaso: 1 pamain';

  @override
  String planFull(int count) {
    return 'Sponsor: sampai $count pamain';
  }

  @override
  String appVersion(String version, String build) {
    return 'Versi aplikasi $version ($build)';
  }

  @override
  String progressTitle(String name) {
    return 'Kamajuan $name';
  }

  @override
  String get changeStartingIsland => 'Ganti planet partamo';

  @override
  String get progressThisWeek => '7 hari tarakhia';

  @override
  String get progressAllTime => 'Sajak awal';

  @override
  String progressPuzzles(int count) {
    return '$count teka-teki salasai';
  }

  @override
  String progressMinutes(int count) {
    return '$count minik bamain';
  }

  @override
  String progressLastPlayed(String date) {
    return 'Tarakhia main: $date';
  }

  @override
  String get progressNotPlayed => 'Alun manyalasaikan teka-teki';

  @override
  String get progressIslands => 'Planet';

  @override
  String get statusNotStarted => 'Alun mulai';

  @override
  String get statusPractising => 'Sadang balatiah';

  @override
  String get statusMastered => 'Alah dikuasai';

  @override
  String progressLevels(int solved, int total) {
    return '$solved dari $total level salasai';
  }

  @override
  String get progressSponsorOnly =>
      'Sponsor bisa mancaliak laporan kamajuan nan langkok: teka-teki nan salasai, wakatu bamain, jo kamajuan di tiok planet.';

  @override
  String get music => 'Musik latar';

  @override
  String get soundEffects => 'Efek suaro';

  @override
  String get hintArrowsFollowRoad => 'Panah patunjuak maikuik jalan';

  @override
  String get hintArrowsFollowRoadHint =>
      'Mati: panah maadok ka ateh, samo jo di blok.';

  @override
  String get soundEffectsHint => 'Suaro patunjuak tatap tadanga.';

  @override
  String get supportCobaLagi => 'Dukuang Coba Lagi';

  @override
  String get debugPlanOverride => 'Debug: pakai versi langkok';

  @override
  String get players => 'Pamain';

  @override
  String deletePlayerConfirm(String name) {
    return 'Hapuih $name jo sadonyo kamajuannyo?';
  }

  @override
  String get playerLimitReached =>
      'Versi ko untuak ciek pamain sajo. Mintak tolong ka urang gadang.';

  @override
  String get run => 'Jalan!';

  @override
  String get step => 'Ciek langkah';

  @override
  String get reset => 'Mulai baliak';

  @override
  String get undo => 'Indak jadi';

  @override
  String get redo => 'Baliakan';

  @override
  String get clearBlocks => 'Hapuih sadonyo blok';

  @override
  String get removeBlock => 'Hapuih blok ko';

  @override
  String get blockForward => 'Maju';

  @override
  String get blockTurnLeft => 'Baluak kida';

  @override
  String get blockTurnRight => 'Baluak suok';

  @override
  String get blockRepeat => 'Ulangi';

  @override
  String get blockStar => 'Blok buatan awak';

  @override
  String get toMap => 'Ka peta';

  @override
  String get tryAgain => 'Cubo baliak!';

  @override
  String get feedbackBumped => 'Ups, ado nan maalangi.';

  @override
  String get feedbackStoppedShort => 'Ampia! Taruih bajalan sampai ka bandera.';

  @override
  String get feedbackOtherBoard =>
      'Peta tu alah bisa! Peta ko babeda, jadi caliak ka muko sabalun tiok langkah.';

  @override
  String get feedbackMissedStars => 'Kumpuan sadonyo bintang dulu.';

  @override
  String get feedbackTooManySteps =>
      'Langkahnyo talalu banyak! Cubo labiah saketek.';

  @override
  String get home => 'Baranda';

  @override
  String get conceptDirections => 'Arah';

  @override
  String get conceptSequencing => 'Langkah demi langkah';

  @override
  String get conceptLoops => 'Paulangan';

  @override
  String get conceptFunctions => 'Blok Ajaib';

  @override
  String get decisionAdvance => 'Planet baru tabukak!';

  @override
  String get decisionPractice => 'Ayo cubo nan lain!';

  @override
  String get bonusAdventure => 'Patualangan bonus!';

  @override
  String get decisionReview => 'Ayo cari harato karun di planet sabalunnyo.';

  @override
  String get decisionReturn => 'Baliak ka patualanganmu!';

  @override
  String get decisionMapComplete => 'Kau alah manjalajahi sadonyo planet!';

  @override
  String get hint => 'Tunjuakan jalannyo';

  @override
  String get hintNextPattern => 'Tunjuakan blok nan baulang';

  @override
  String get hintNextRing => 'Tunjuakan blok nan paralu diganti';

  @override
  String get repeatMore => 'Tambah ciek kali';

  @override
  String get repeatFewer => 'Kurangi ciek kali';

  @override
  String get dropBlocksHere => 'Latakan blok di siko';

  @override
  String get pretestWelcome => 'Hai, awak Koba! Ayo main pamanasan dulu!';

  @override
  String get pretestStart => 'Mulai';

  @override
  String get listenAgain => 'Danga baliak';

  @override
  String get promptReading => 'Gambar nan ma nan cocok jo tulisan ko?';

  @override
  String get promptCounting => 'Ado bara?';

  @override
  String get promptSideLeft => 'Sentuah nan di sabalah kida.';

  @override
  String get promptSideRight => 'Sentuah nan di sabalah suok.';

  @override
  String get promptTurnLeft => 'Panah baluak kida. Kini manunjuak ka ma?';

  @override
  String get promptTurnRight => 'Panah baluak suok. Kini manunjuak ka ma?';

  @override
  String get promptPattern => 'Apo nan salanjuiknyo?';

  @override
  String get promptSequencing => 'Langkah nan ma nan sampai ka bandera?';

  @override
  String get pretestDone => 'Salasai! Patualanganmu dimulai kini.';

  @override
  String get startAdventure => 'Ayo!';

  @override
  String get wordSun => 'matoari';

  @override
  String get wordStar => 'bintang';

  @override
  String get wordHouse => 'rumah';

  @override
  String get wordCar => 'oto';

  @override
  String get wordTree => 'batang kayu';

  @override
  String get wordBall => 'bola';

  @override
  String get wordFlower => 'bungo';

  @override
  String get wordBoat => 'parahu';

  @override
  String get wordBird => 'buruang';

  @override
  String get wordCake => 'kue';

  @override
  String get colorRed => 'sirah';

  @override
  String get colorBlue => 'biru';

  @override
  String get colorGreen => 'ijau';

  @override
  String get colorYellow => 'kuniang';

  @override
  String wordsWithColor(String color, String object) {
    return '$object $color';
  }

  @override
  String get startingIsland => 'Planet partamo';

  @override
  String get retakePretest => 'Main pamanasan baliak';

  @override
  String placementNowAt(String island) {
    return 'Kini di: $island';
  }

  @override
  String get placementNotYet => 'Alun main pamanasan';

  @override
  String get setByParent => 'diatur urang gadang';

  @override
  String get cheerCelebrate1 => 'Hebat!';

  @override
  String get cheerCelebrate2 => 'Mantap!';

  @override
  String get cheerCelebrate3 => 'Kau barasil!';

  @override
  String get cheerCelebrate4 => 'Super!';

  @override
  String get cheerCelebrate5 => 'Wah, rancak bana!';

  @override
  String get cheerCelebrate6 => 'Luar biaso!';

  @override
  String get cheerEncourage1 => 'Pikiran nan rancak!';

  @override
  String get cheerEncourage2 => 'Usaho nan rancak!';

  @override
  String get cheerEncourage3 => 'Ayo lanjuik!';

  @override
  String get cheerEncourage4 => 'Tarimo kasih alah mancubo!';

  @override
  String get cheerEncourage5 => 'Kau hebat!';

  @override
  String get donateExplainer =>
      'Coba Lagi gratis. Donasi bara pun mambukak fitur sponsor untuak kaluargamu dan mambantu kami mambuek labiah banyak patualangan.';

  @override
  String get donateUnavailable => 'Donasi indak tasadio di parangkaik ko.';

  @override
  String get restoreDonation => 'Pulihkan donasi sabalunnyo';

  @override
  String get tipExplainer =>
      'Coba Lagi gratis. Tip bara pun mambukak fitur sponsor untuak kaluargamu dan mambantu kami mambuek labiah banyak patualangan.';

  @override
  String get tipsUnavailable => 'Tip indak tasadio di parangkaik ko.';

  @override
  String get restorePurchases => 'Pulihkan pambalian';

  @override
  String get haveUnlockCode => 'Punyo kode?';

  @override
  String get buyUnlockCode => 'Bali kode';

  @override
  String get buyUnlockCodeExplainer =>
      'Bali kode di situs kami. Kodenyo dikirim lewat email; sudah tu masuakan lewat \"Punyo kode?\".';

  @override
  String get unlockCode => 'Kode';

  @override
  String get useUnlockCode => 'Pakai kode';

  @override
  String get unlockCodeRejected =>
      'Kode tu indak balaku. Pareso baliak, lalu cubo sakali lai.';

  @override
  String get thanksForSupport => 'Tarimo kasih alah mandukuang Coba Lagi!';

  @override
  String get playGoal => 'Bantu awak sampai ka bandera!';

  @override
  String get playGoalStars => 'Kumpuan sadonyo bintang, lalu ka bandera!';

  @override
  String get playGoalLoops => 'Pakai blok ulangi untuak sampai ka bandera!';

  @override
  String get playGoalFunctions =>
      'Isi blok bintang, lalu pakai bakali-kali untuak sampai ka bandera!';

  @override
  String get playHowTo => 'Seret blok ka kotak putiah, lalu tekan Jalan!';

  @override
  String get backToIsland => 'Baliak ka planet';

  @override
  String get continueAdventure => 'Lanjuikan patualangan';

  @override
  String levelNumber(int number) {
    return 'Level $number';
  }

  @override
  String get levelLocked => 'Alun tabukak';

  @override
  String get answerWas => 'Jawabannyo nan iko!';

  @override
  String get conceptConditions => 'Caliak ka muko';

  @override
  String get blockUntilGoal => 'Ulangi sampai bandera';

  @override
  String get blockIfPathClear => 'Kalau kosong';

  @override
  String get playGoalConditions =>
      'Caliak ka muko! Latakan blok maju di dalam blok mato. Inyo maju kalau jalan di muko kosong sajo. Blokmu harus barasil di tiok peta!';

  @override
  String get updateAvailableTitle => 'Ado pambaruan';

  @override
  String get updateAvailableBody =>
      'Versi tabaru Coba Lagi alah tasadio. Mintak tolong ka urang gadang untuak mampabarui aplikasi.';

  @override
  String get updateWithParent => 'Mintak tolong untuak mampabarui';

  @override
  String get updateContinue => 'Lanjuik bamain';

  @override
  String get updateOpenFailed =>
      'Pambaruan alun bisa dibukak. Cubo baliak atau lanjuik bamain.';

  @override
  String get codeTab => 'Tab Kode';

  @override
  String get codeTabHint =>
      'Anak bisa maetik kode salain mamakai blok bagambar. Main pamanasan manyalakannyo untuak anak nan alah pandai mambaco.';

  @override
  String get editorBlocks => 'Blok';

  @override
  String get editorCode => 'Kode';

  @override
  String get codeDrafts =>
      'Tiok editor manyimpan draf surang. Draf kode partamo barasal dari blokmu.';

  @override
  String get codeHelp => 'Panduan kode';

  @override
  String get codeSource => 'Kodemu';

  @override
  String get codeGuide =>
      'Sentuah parintah untuak manambahannyo, atau etik surang. Namo parintah tatap samo di sadonyo baso. Akhiri aksi jo (); dan latakan isi paulangan jo pamariksoan di antaro kurung kurawal bukak jo tutuik. Jumlah paulangan 1–9. Buek Blok Ajaib jo define star, lalu jalankan jo star();. // mamulai komentar. Tiok parintah dihituang sabagai ciek blok, tamasuak parintah di dalam kurung kurawal. Simpan angko jo steps = 3; dan pakai move(steps); untuak maju sabanyak itu. Angkonyo tatap samo sampai kau manyimpan nan baru. Simpan sabalun mamakainyo. until_flag maulang isi kurung kurawalnyo sampai robot tibo di bandera, tanpa hituangan.';

  @override
  String get codeSyntax =>
      'Pareso namo parintah, tando kurung, kurung kurawal, jo titiak koma.';

  @override
  String get codeNumber => 'Piliah angko dari 1 sampai 9.';

  @override
  String get codeDuplicateStar => 'Pakai ciek bagian define star sajo.';

  @override
  String get codeNestedStar =>
      'Latakan define star di lua paulangan jo pamariksoan.';

  @override
  String get codeTooLarge =>
      'Cubo program nan labiah pendek jo labiah saketek bagian batingkek.';

  @override
  String get codeDisallowed => 'Pakai parintah nan ado untuak teka-teki ko.';

  @override
  String get codeLimit => 'Cubo kurangi parintah supayo pas jo bateh blok.';

  @override
  String get codeEmptyBody => 'Tambahan parintah di dalam kurung kurawal.';

  @override
  String get codeEmptyStar =>
      'Tambahan parintah ka define star sabalun mamakai star();.';

  @override
  String get codeRecursiveStar =>
      'Pakai langkah, baluak, paulangan, atau pamariksoan di dalam define star.';

  @override
  String get codeReady => 'Siap dijalankan';

  @override
  String get codeStart => 'Tambahan parintah untuak mulai.';

  @override
  String codeLine(int line, String message) {
    return 'Baris $line: $message';
  }

  @override
  String codeRunningLine(int line) {
    return 'Manjalankan baris $line';
  }

  @override
  String get codeDefineStar => 'Buek blok awak';

  @override
  String get conceptUntil => 'Sampai bandera';

  @override
  String get playGoalUntil =>
      'Pakai blok ulangi sampai bandera: blok tu taruih bajalan surang, jadi kau indak paralu mahituang!';

  @override
  String get conceptDebugging => 'Pelokan!';

  @override
  String get playGoalDebugging =>
      'Ups, blok ko alun pas! Tekan Jalan, caliak apo nan tajadi, lalu pelokan.';

  @override
  String get conceptVariables => 'Kotak Langkah';

  @override
  String get blockSetSteps => 'Simpan langkah';

  @override
  String get blockMoveSteps => 'Pakai langkah';

  @override
  String get stepsFewer => 'Simpan angko nan labiah ketek';

  @override
  String get stepsMore => 'Simpan angko nan labiah gadang';

  @override
  String get playGoalVariables =>
      'Simpan angko di Kotak Langkahmu, lalu pakai untuak maju sabanyak itu! Angkonyo bisa dipakai baliak atau diganti. Sampai ka bandera dan kumpuan sadonyo bintang.';

  @override
  String stepBoxValue(String value) {
    return 'Kotak Langkah: $value';
  }

  @override
  String get codeUnsetSteps =>
      'Simpan angko jo steps = 2; sabalun mamakai move(steps);.';

  @override
  String get variableHint =>
      'Simpan angko dulu, lalu pakai kotak untuak maju. Angkonyo tatap samo sampai kau manggantinyo.';

  @override
  String get tutorialTitle => 'Caliak awak!';

  @override
  String get tutorialWatchAgain => 'Caliak baliak';

  @override
  String get tutorialLetsPlay => 'Ayo main!';

  @override
  String get tutorialSkip => 'Lewati';

  @override
  String get storyTitle => 'Kapa bintang Koba';

  @override
  String get storyShelfIntro => 'Awal carito';

  @override
  String get storyShelfNewPlanet => 'Planet baru';

  @override
  String get storyShelfEnding => 'Tangkinyo panuah!';

  @override
  String get storyShelfFullAgain => 'Tangkinyo panuah baliak';

  @override
  String get storyIntroFly =>
      'Iko kapa bintang Koba. Kapa ko tabang jo bintang!';

  @override
  String get storyIntroWind =>
      'Wuusss! Angin angkaso maambuih bintang dari tangkinyo, ka sadonyo planet.';

  @override
  String get storyIntroLand => 'Bintangnyo abih, jadi kapanyo harus mandarat.';

  @override
  String get storyIntroBump => 'Ups, ado batu! Indak baa do. Awak cubo baliak!';

  @override
  String get storyIntroHelp =>
      'Ayo cari bintangnyo basamo. Namuah kau mambantu awak, Komandan?';

  @override
  String get storyFly =>
      'Tangki awak batambah bintang! Ayo ka planet barikuiknyo!';

  @override
  String get storyArrivalDirections =>
      'Kapanyo mandarat di planet nan panuah papan patunjuak. Arahnyo ka ma-ma!';

  @override
  String get storyArrivalDirectionsKoba =>
      'Awak harus ka ma? Tunjuakan jo panah: maju, kida, atau suok!';

  @override
  String get storyArrivalSequencing =>
      'Di siko, bintangnyo ado di sapanjang jalan nan bakelok-kelok.';

  @override
  String get storyArrivalSequencingKoba =>
      'Awak paralu sadonyo langkahnyo baurutan, ciek-ciek!';

  @override
  String get storyArrivalLoops =>
      'Di planet ko, jalannyo maju, baluak, maju, baluak, taruih baulang-ulang.';

  @override
  String get storyArrivalLoopsKoba =>
      'Banyak bana langkahnyo! Ado jalan pintasnyo, indak?';

  @override
  String get storyArrivalFunctions =>
      'Koba manamukan blok ajaib nan bakilau di tanah.';

  @override
  String get storyArrivalFunctionsKoba =>
      'Blok ko bisa maingek garak awak! Ajari sakali, lalu pakai bakali-kali.';

  @override
  String get storyArrivalConditions =>
      'Kabuik taba manutuik planet ko. Koba indak bisa mancaliak jalannyo!';

  @override
  String get storyArrivalConditionsKoba =>
      'Awak iduikan lampu awak dan mancaliak ka muko sabalun malangkah.';

  @override
  String get storyArrivalVariables =>
      'Di planet ko, Koba manamukan kotak ketek nan baangko.';

  @override
  String get storyArrivalVariablesKoba =>
      'Kotak ko maingek angko! Angkonyo mangatoan bara langkah awak bajalan.';

  @override
  String get storyArrivalDebugging =>
      'Ado nan maninggaan blok di jalan, sadonyo batuka-tuka.';

  @override
  String get storyArrivalDebuggingKoba =>
      'Blok ko alun pas. Ayo cari nan paralu dipelokan!';

  @override
  String get storyArrivalUntil =>
      'Jauah, jauah bana, ado bandera di ujuang jalan nan panjang.';

  @override
  String get storyArrivalUntilKoba =>
      'Langkahnyo talalu banyak untuak dihituang! Awak bajalan taruih sajo sampai ka bandera.';

  @override
  String get storyArrivalOtherwise =>
      'Jalannyo bacabang duo. Di ciek jalan ado samak!';

  @override
  String get storyArrivalOtherwiseKoba =>
      'Kalau jalannyo kosong, awak maju. Kalau indak, awak baluak!';

  @override
  String get storyEnding =>
      'Bintang tarakhia tabang pulang. Tangki Koba panuah!';

  @override
  String get storyEndingKoba =>
      'Tarimo kasih, Komandan! Kau mambantu awak manamukan sadonyo bintang.';

  @override
  String get storyEndingMore =>
      'Kini kito bisa tabang ka ma sajo. Ayo taruih bamain basamo!';

  @override
  String get storyFullAgain => 'Bintang-bintang tabang pulang ka tangki.';

  @override
  String get storyNewPlanet =>
      'Wuusss! Angin angkaso maambuih babarapo bintang dari tangki, ka planet nan alun pernah ditamukan.';

  @override
  String get storyNewPlanetKoba =>
      'Planet baru! Namuah kau mambantu awak mancari bintang baliak, Komandan?';

  @override
  String get storyThanksDirections =>
      'Panuah baliak! Tarimo kasih alah maajari awak kida jo suok, Komandan!';

  @override
  String get storyThanksSequencing =>
      'Panuah baliak! Tarimo kasih alah maajari awak langkah baurutan, Komandan!';

  @override
  String get storyThanksLoops =>
      'Panuah baliak! Tarimo kasih alah maajari awak maulang, Komandan!';

  @override
  String get storyThanksFunctions =>
      'Panuah baliak! Tarimo kasih alah maajari awak Blok Ajaib, Komandan!';

  @override
  String get storyThanksConditions =>
      'Panuah baliak! Tarimo kasih alah maajari awak mancaliak ka muko, Komandan!';

  @override
  String get storyThanksVariables =>
      'Panuah baliak! Tarimo kasih alah maajari awak Kotak Langkah, Komandan!';

  @override
  String get storyThanksDebugging =>
      'Panuah baliak! Tarimo kasih alah maajari awak mamelokan blok, Komandan!';

  @override
  String get storyThanksUntil =>
      'Panuah baliak! Tarimo kasih alah maajari awak bajalan sampai ka bandera, Komandan!';

  @override
  String get storyThanksOtherwise =>
      'Panuah baliak! Tarimo kasih alah maajari awak apo nan dikarajoan kalau indak, Komandan!';

  @override
  String get watchHow => 'Caliak caronyo';

  @override
  String get tutorialDirections =>
      'Sentuah blok panah untuak mambari tahu awak ka ma harus pai: maju, baluak kida, baluak suok. Lalu tekan Jalan!';

  @override
  String get tutorialSequencing =>
      'Susun langkahnyo baurutan, ciek-ciek, sampai ka bandera.';

  @override
  String get tutorialLoops =>
      'Langkahnyo samo taruih? Masuakan ka blok ulangi, lalu piliah bara kali!';

  @override
  String get tutorialFunctions =>
      'Buek blok ajaibmu surang di baris bintang. Lalu pakai bintangnyo bakali-kali!';

  @override
  String get tutorialConditions =>
      'Blok mato mancaliak ka muko. Kalau jalannyo kosong, awak maju. Kalau indak, awak manunggu. Jadi blok nan samo barasil di tiok peta!';

  @override
  String get tutorialVariables =>
      'Simpan angko di Kotak Langkah. Lalu pakai langkah untuak bajalan sabanyak itu!';

  @override
  String get tutorialDebugging =>
      'Blok ko alun pas. Tekan Jalan dan pasatikan. Lalu sentuah blok nan paralu dipelokan, dan sentuah blok nan tapek!';

  @override
  String get tutorialUntil =>
      'Ulangi sampai bandera taruih bajalan surang, jadi kau indak paralu mahituang!';

  @override
  String get hintPattern =>
      'Blok-blok ko muncul baliak dan baliak. Cubo pakai blok ulangi!';

  @override
  String get hintAgain =>
      'Sentuah lampu baliak untuak mancaliak blok nan baulang!';

  @override
  String get hintLookHere =>
      'Caliak blok nan ado lampunyo. Cubo ganti blok tu!';

  @override
  String get hintLookHereMany =>
      'Caliak blok-blok nan ado lampunyo. Cubo ganti blok-blok tu!';

  @override
  String get turnMap => 'Putar peta';

  @override
  String boardNumber(int number) {
    return 'Peta $number';
  }

  @override
  String get tourPalette =>
      'Iko blok-blokmu. Sentuah ciek, atau seret ka programmu.';

  @override
  String get tourProgram =>
      'Programmu ado di siko. Awak manjalankan bloknyo baurutan, dari nan partamo. Sentuah blok untuak manggantinyo.';

  @override
  String get tourGo => 'Tekan Jalan, dan awak maikuik blok-blokmu!';

  @override
  String get tourStep =>
      'Tombol ko manjalankan ciek blok tiok kali, jadi kau bisa mancaliak jo taliti.';

  @override
  String get tourReset => 'Nan iko mambaok awak baliak ka awal.';

  @override
  String get tourHint =>
      'Binguang? Sasudah babarapo kali mancubo, lampu iduik. Tiok sentuhan manunjuakan saketek lai: partamo jalannyo, lalu blok nan ma nan paralu diganti. Tando ketek di lampu manunjuakan apo nan barikuiknyo.';

  @override
  String get tourFollow =>
      'Iko mamuta peta saparampek putaran tiok kali, jadi kau bisa mancaliaknyo dari sisi awak.';

  @override
  String get tourBoards =>
      'Di siko ado babarapo peta. Sentuah titiak untuak mancaliak tiok peta. Blokmu harus mambaok awak ka bandera di tiok peta!';

  @override
  String get tourListen =>
      'Sentuah speaker untuak mandanga baliak apo nan harus dikarajoan.';

  @override
  String get tourWarmUpListen =>
      'Dangakan patanyoannyo. Sentuah speaker untuak mandanganyo baliak.';

  @override
  String get tourWarmUpAnswer => 'Lalu sentuah gambar nan manuruik kau bana!';

  @override
  String get tourWarmUpSteps =>
      'Jajak kaki manunjuakan alah sajauah ma kau bamain.';

  @override
  String get tourBlockForward => 'Panah ijau mambuek awak maju ciek langkah.';

  @override
  String get tourBlockTurnLeft =>
      'Panah biru mambuek awak baluak ka kida, tanpa bapindah.';

  @override
  String get tourBlockTurnRight =>
      'Panah oranye mambuek awak baluak ka suok, tanpa bapindah.';

  @override
  String get tourBlockRepeat =>
      'Blok ulangi manjalankan blok di dalamnyo baulang kali. Sentuah minus atau plus untuak mamiliah bara kali.';

  @override
  String get tourBlockSetSteps =>
      'Kotak Langkah manyimpan jumlah langkah. Sentuah minus atau plus untuak manggantinyo.';

  @override
  String get tourBlockMoveSteps =>
      'Panah ko mambuek awak maju sabanyak angko di Kotak Langkah.';

  @override
  String get tourBlockIfPathClear =>
      'Blok mato mancaliak ka muko. Blok di dalamnyo bajalan kalau jalannyo kosong sajo.';

  @override
  String get tourBlockIfElse =>
      'Blok mato ko punyo duo baris: baris ateh bajalan kalau jalannyo kosong, baris bawah kalau indak.';

  @override
  String get tourBlockUntilGoal =>
      'Ulangi sampai bandera manjalankan blok di dalamnyo taruih-manaruih, sampai awak tibo di bandera.';

  @override
  String get tourBlockStar =>
      'Blok bintang manjalankan blok di baris bintangmu: blok ajaib buatanmu surang.';

  @override
  String get tourNext => 'Lanjuik';

  @override
  String get tourDone => 'Paham!';

  @override
  String get tourHelp => 'Baa caronyo?';

  @override
  String get breakTitle => 'Wakatunyo istirahat!';

  @override
  String get breakBody =>
      'Kau alah bamain jo hebat. Istirahatkan matomu, cubo paregangan, lalu main baliak beko.';

  @override
  String get breakHome => 'Baliak ka pamain';

  @override
  String get breakContinue => 'Urang gadang bisa malanjuikan';

  @override
  String get breakVoice =>
      'Wakatunyo istirahat! Kau alah bamain jo hebat. Istirahatkan matomu, cubo paregangan, lalu main baliak beko.';

  @override
  String get breakReminder => 'Pangingek istirahat';

  @override
  String get breakReminderHint =>
      'Sasudah bamain teka-teki salamo iko, anak diajak istirahat. Urang gadang sajo nan bisa malanjuikan.';

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
      other: 'Cukuik $count teka-teki lai bisa mambaok kau ka $island!',
      one: 'Teka-teki barikuiknyo bisa mambaok kau ka $island!',
    );
    return '$_temp0';
  }

  @override
  String get conceptWarmUp => 'Pamanasan';

  @override
  String get warmUpCounting => 'Bahituang';

  @override
  String get warmUpColors => 'Warna';

  @override
  String get warmUpShapes => 'Bantuak';

  @override
  String get warmUpPatterns => 'Pola';

  @override
  String get warmUpSides => 'Kida jo suok';

  @override
  String get warmUpSteps => 'Langkah';

  @override
  String get warmUpReading => 'Mambaco';

  @override
  String get warmUpPick => 'Piliah pamainan!';

  @override
  String get warmUpDone => 'Hebat bana mainnyo! Main baliak?';

  @override
  String get playAgain => 'Main baliak';

  @override
  String get promptColorRed => 'Sentuah nan sirah!';

  @override
  String get promptColorBlue => 'Sentuah nan biru!';

  @override
  String get promptColorGreen => 'Sentuah nan ijau!';

  @override
  String get promptColorYellow => 'Sentuah nan kuniang!';

  @override
  String get promptShapeCircle => 'Sentuah lingkaran!';

  @override
  String get promptShapeSquare => 'Sentuah pasagi!';

  @override
  String get promptShapeTriangle => 'Sentuah sagitigo!';

  @override
  String get promptShapeHeart => 'Sentuah ati!';

  @override
  String playLevel(int number) {
    return 'Main level $number';
  }

  @override
  String get stickerBook => 'Buku stiker';

  @override
  String get stickerBookHello => 'Caliak sadonyo stikermu!';

  @override
  String get stickersIslands => 'Planet';

  @override
  String get stickerNotYet => 'Alun dapek';

  @override
  String get stickerGold => 'Sadonyo bintang takumpua!';

  @override
  String get blockIfElse => 'Kalau kosong, kalau indak';

  @override
  String get otherwiseRowClear => 'Kalau jalannyo kosong';

  @override
  String get otherwiseRowBlocked => 'Kalau indak';

  @override
  String get conceptOtherwise => 'Kalau indak';

  @override
  String get playGoalOtherwise =>
      'Pakai blok mato jo duo baris: kalau jalannyo kosong, malangkah. Kalau indak, baluak!';

  @override
  String get tutorialOtherwise =>
      'Mato mancaliak ka muko. Kalau jalannyo kosong, malangkah. Kalau indak, baluak. Lalu sadonyo diulang sampai ka bandera!';

  @override
  String starsEarned(int count) {
    return '$count dari 3 bintang';
  }
}
