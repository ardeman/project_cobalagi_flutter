// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Sundanese (`su`).
class AppLocalizationsSu extends AppLocalizations {
  AppLocalizationsSu([String locale = 'su']) : super(locale);

  @override
  String get appTitle => 'Coba Lagi';

  @override
  String get whoIsPlaying => 'Saha nu ulin?';

  @override
  String get editPlayer => 'Robah pamaen';

  @override
  String get addPlayer => 'Pamaen anyar';

  @override
  String get nickname => 'Ngaran landihan';

  @override
  String get chooseAvatar => 'Pilih gambar';

  @override
  String get save => 'Simpen';

  @override
  String get cancel => 'Bolay';

  @override
  String get delete => 'Pupus';

  @override
  String get ok => 'Oke';

  @override
  String greeting(String name) {
    return 'Hai, $name!';
  }

  @override
  String get play => 'Ulin';

  @override
  String get askAGrownUp => 'Menta tulung ka kolot';

  @override
  String parentGateQuestion(int a, int b) {
    return 'Sabaraha $a × $b?';
  }

  @override
  String get parentGateWrong => 'Can pas. Coba deui.';

  @override
  String get parentArea => 'Tempat kolot';

  @override
  String get language => 'Basa';

  @override
  String get languageSystem => 'Nuturkeun alat';

  @override
  String get plan => 'Versi';

  @override
  String get planFree => 'Biasa: 1 pamaen';

  @override
  String planFull(int count) {
    return 'Sponsor: nepi ka $count pamaen';
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
  String get changeStartingIsland => 'Ganti planet awal';

  @override
  String get progressThisWeek => '7 poe panungtung';

  @override
  String get progressAllTime => 'Ti awal';

  @override
  String progressPuzzles(int count) {
    return '$count tatarucingan rengse';
  }

  @override
  String progressMinutes(int count) {
    return '$count menit ulin';
  }

  @override
  String progressLastPlayed(String date) {
    return 'Panungtung ulin: $date';
  }

  @override
  String get progressNotPlayed => 'Can ngarengsekeun tatarucingan';

  @override
  String get progressIslands => 'Planet';

  @override
  String get statusNotStarted => 'Can dimimitian';

  @override
  String get statusPractising => 'Keur latihan';

  @override
  String get statusMastered => 'Geus dikawasa';

  @override
  String progressLevels(int solved, int total) {
    return '$solved tina $total level rengse';
  }

  @override
  String get progressSponsorOnly =>
      'Sponsor bisa nempo laporan kamajuan nu lengkep: tatarucingan nu rengse, waktu ulin, jeung kamajuan di unggal planet.';

  @override
  String get music => 'Musik latar';

  @override
  String get soundEffects => 'Efek sora';

  @override
  String get hintArrowsFollowRoad => 'Panah pituduh nuturkeun jalan';

  @override
  String get hintArrowsFollowRoadHint =>
      'Pareum: panah nyanghareup ka luhur, siga dina blok.';

  @override
  String get soundEffectsHint => 'Sora pituduh tetep kadenge.';

  @override
  String get supportCobaLagi => 'Dukung Coba Lagi';

  @override
  String get debugPlanOverride => 'Debug: pake versi lengkep';

  @override
  String get players => 'Pamaen';

  @override
  String deletePlayerConfirm(String name) {
    return 'Pupus $name jeung sakabeh kamajuanana?';
  }

  @override
  String get playerLimitReached =>
      'Versi ieu ngan keur hiji pamaen. Menta tulung ka kolot.';

  @override
  String get run => 'Jalan!';

  @override
  String get step => 'Hiji lengkah';

  @override
  String get reset => 'Mimitian deui';

  @override
  String get undo => 'Bolaykeun';

  @override
  String get redo => 'Balikan deui';

  @override
  String get clearBlocks => 'Pupus sakabeh blok';

  @override
  String get removeBlock => 'Pupus blok ieu';

  @override
  String get blockForward => 'Maju';

  @override
  String get blockTurnLeft => 'Mengkol ka kenca';

  @override
  String get blockTurnRight => 'Mengkol ka katuhu';

  @override
  String get blockRepeat => 'Ulang';

  @override
  String get blockStar => 'Blok jieunan kuring';

  @override
  String get toMap => 'Ka peta';

  @override
  String get tryAgain => 'Coba deui!';

  @override
  String get feedbackBumped => 'Ups, aya nu ngahalangan.';

  @override
  String get feedbackStoppedShort =>
      'Saeutik deui! Terus leumpang nepi ka bandera.';

  @override
  String get feedbackOtherBoard =>
      'Peta eta geus hasil! Peta ieu beda, jadi tempo ka hareup samemeh unggal lengkah.';

  @override
  String get feedbackMissedStars => 'Kumpulkeun heula sakabeh bentang.';

  @override
  String get feedbackTooManySteps =>
      'Lengkahna loba teuing! Coba leuwih saeutik.';

  @override
  String get home => 'Tepas';

  @override
  String get conceptDirections => 'Arah';

  @override
  String get conceptSequencing => 'Lengkah demi lengkah';

  @override
  String get conceptLoops => 'Ngulang';

  @override
  String get conceptFunctions => 'Blok Ajaib';

  @override
  String get decisionAdvance => 'Planet anyar kabuka!';

  @override
  String get decisionPractice => 'Hayu coba nu sejen!';

  @override
  String get bonusAdventure => 'Petualangan bonus!';

  @override
  String get decisionReview => 'Hayu neangan harta karun di planet samemehna.';

  @override
  String get decisionReturn => 'Balik deui ka petualangan anjeun!';

  @override
  String get decisionMapComplete => 'Anjeun geus ngajajah sakabeh planet!';

  @override
  String get hint => 'Tuduhkeun jalanna';

  @override
  String get hintNextPattern => 'Tuduhkeun blok nu diulang-ulang';

  @override
  String get hintNextRing => 'Tuduhkeun blok nu kudu diganti';

  @override
  String get repeatMore => 'Tambah sakali';

  @override
  String get repeatFewer => 'Kurangan sakali';

  @override
  String get dropBlocksHere => 'Teundeun blok di dieu';

  @override
  String get pretestWelcome => 'Hai, kuring Koba! Hayu ulin pemanasan heula!';

  @override
  String get pretestStart => 'Mimitian';

  @override
  String get listenAgain => 'Dengekeun deui';

  @override
  String get promptReading => 'Gambar mana nu cocog jeung tulisan ieu?';

  @override
  String get promptCounting => 'Aya sabaraha?';

  @override
  String get promptSideLeft => 'Toel nu di beulah kenca.';

  @override
  String get promptSideRight => 'Toel nu di beulah katuhu.';

  @override
  String get promptTurnLeft =>
      'Panahna mengkol ka kenca. Ayeuna nunjuk ka mana?';

  @override
  String get promptTurnRight =>
      'Panahna mengkol ka katuhu. Ayeuna nunjuk ka mana?';

  @override
  String get promptPattern => 'Naon saterusna?';

  @override
  String get promptSequencing => 'Lengkah mana nu nepi ka bandera?';

  @override
  String get pretestDone => 'Rengse! Petualangan anjeun dimimitian ayeuna.';

  @override
  String get startAdventure => 'Hayu!';

  @override
  String get wordSun => 'panonpoe';

  @override
  String get wordStar => 'bentang';

  @override
  String get wordHouse => 'imah';

  @override
  String get wordCar => 'mobil';

  @override
  String get wordTree => 'tangkal';

  @override
  String get wordBall => 'bal';

  @override
  String get wordFlower => 'kembang';

  @override
  String get wordBoat => 'parahu';

  @override
  String get wordBird => 'manuk';

  @override
  String get wordCake => 'kueh';

  @override
  String get colorRed => 'beureum';

  @override
  String get colorBlue => 'biru';

  @override
  String get colorGreen => 'hejo';

  @override
  String get colorYellow => 'koneng';

  @override
  String wordsWithColor(String color, String object) {
    return '$object $color';
  }

  @override
  String get startingIsland => 'Planet awal';

  @override
  String get retakePretest => 'Ulin pemanasan deui';

  @override
  String placementNowAt(String island) {
    return 'Ayeuna di: $island';
  }

  @override
  String get placementNotYet => 'Can ulin pemanasan';

  @override
  String get setByParent => 'diatur ku kolot';

  @override
  String get cheerCelebrate1 => 'Hebat!';

  @override
  String get cheerCelebrate2 => 'Keren!';

  @override
  String get cheerCelebrate3 => 'Anjeun hasil!';

  @override
  String get cheerCelebrate4 => 'Super!';

  @override
  String get cheerCelebrate5 => 'Wah, alus pisan!';

  @override
  String get cheerCelebrate6 => 'Luar biasa!';

  @override
  String get cheerEncourage1 => 'Pamikiran nu alus!';

  @override
  String get cheerEncourage2 => 'Usaha nu alus!';

  @override
  String get cheerEncourage3 => 'Hayu terus!';

  @override
  String get cheerEncourage4 => 'Nuhun geus nyoba!';

  @override
  String get cheerEncourage5 => 'Anjeun hebat!';

  @override
  String get donateExplainer =>
      'Coba Lagi gratis. Donasi sabaraha wae muka fitur sponsor keur kulawarga anjeun jeung ngabantu kami nyieun leuwih loba petualangan.';

  @override
  String get donateUnavailable => 'Donasi teu aya dina alat ieu.';

  @override
  String get restoreDonation => 'Pulihkeun donasi samemehna';

  @override
  String get tipExplainer =>
      'Coba Lagi gratis. Tip sabaraha wae muka fitur sponsor keur kulawarga anjeun jeung ngabantu kami nyieun leuwih loba petualangan.';

  @override
  String get tipsUnavailable => 'Tip teu aya dina alat ieu.';

  @override
  String get restorePurchases => 'Pulihkeun pameulian';

  @override
  String get haveUnlockCode => 'Boga kode?';

  @override
  String get buyUnlockCode => 'Meuli kode';

  @override
  String get buyUnlockCodeExplainer =>
      'Meuli kode di situs kami. Kodena dikirim ku email; tuluy asupkeun ngaliwatan \"Boga kode?\".';

  @override
  String get unlockCode => 'Kode';

  @override
  String get useUnlockCode => 'Pake kode';

  @override
  String get unlockCodeRejected =>
      'Kode eta teu laku. Pariksa deui, terus coba sakali deui.';

  @override
  String get unlockCodeGithubOnly =>
      'Kode ieu kanggo aplikasi ti GitHub. Dina aplikasi ieu, dukungan ngaliwatan toko aplikasina.';

  @override
  String get thanksForSupport => 'Nuhun geus ngadukung Coba Lagi!';

  @override
  String get playGoal => 'Bantuan kuring nepi ka bandera!';

  @override
  String get playGoalStars => 'Kumpulkeun sakabeh bentang, terus ka bandera!';

  @override
  String get playGoalLoops => 'Pake blok ulang sangkan nepi ka bandera!';

  @override
  String get playGoalFunctions =>
      'Eusian blok bentang, terus pake sababaraha kali sangkan nepi ka bandera!';

  @override
  String get playHowTo => 'Sered blok ka kotak bodas, terus pencet Jalan!';

  @override
  String get backToIsland => 'Balik deui ka planet';

  @override
  String get continueAdventure => 'Teruskeun petualangan';

  @override
  String levelNumber(int number) {
    return 'Level $number';
  }

  @override
  String get levelLocked => 'Can kabuka';

  @override
  String get answerWas => 'Jawabanana nu ieu!';

  @override
  String get conceptConditions => 'Tempo ka hareup';

  @override
  String get blockUntilGoal => 'Ulang nepi ka bandera';

  @override
  String get blockIfPathClear => 'Lamun kosong';

  @override
  String get playGoalConditions =>
      'Tempo ka hareup! Teundeun blok maju di jero blok panon. Eta ngan maju lamun jalan di hareup kosong. Blok anjeun kudu hasil di unggal peta!';

  @override
  String get updateAvailableTitle => 'Aya pembaruan';

  @override
  String get updateAvailableBody =>
      'Versi panganyarna Coba Lagi geus aya. Menta tulung ka kolot pikeun ngapdet aplikasi.';

  @override
  String get updateWithParent => 'Menta tulung ngapdet';

  @override
  String get updateContinue => 'Terus ulin';

  @override
  String get updateOpenFailed =>
      'Pembaruan can bisa dibuka. Coba deui atawa terus ulin.';

  @override
  String get codeTab => 'Tab Kode';

  @override
  String get codeTabHint =>
      'Barudak bisa ngetik kode salian ti make blok gambar. Ulin pemanasan ngahurungkeunana keur barudak nu geus bisa maca.';

  @override
  String get editorBlocks => 'Blok';

  @override
  String get editorCode => 'Kode';

  @override
  String get codeDrafts =>
      'Unggal editor nyimpen draf sorangan. Draf kode kahiji asalna tina blok anjeun.';

  @override
  String get codeHelp => 'Pituduh kode';

  @override
  String get codeSource => 'Kode anjeun';

  @override
  String get codeGuide =>
      'Toel parentah pikeun nambahkeunana, atawa ketik sorangan. Ngaran parentah tetep sarua dina sakabeh basa. Tungtungan aksi ku (); jeung teundeun eusi ulangan jeung pamariksaan di antara kurung kurawal muka jeung nutup. Jumlah ulangan 1–9. Jieun Blok Ajaib ku define star, terus jalankeun ku star();. // ngamimitian komentar. Unggal parentah diitung hiji blok, kaasup parentah di jero kurung kurawal. Simpen angka ku steps = 3; jeung pake move(steps); pikeun maju sakitu. Angkana tetep sarua nepi ka anjeun nyimpen nu anyar. Simpen samemeh makena. until_flag ngulang eusi kurung kurawalna nepi ka robot nepi ka bandera, tanpa itungan.';

  @override
  String get codeSyntax =>
      'Pariksa ngaran parentah, tanda kurung, kurung kurawal, jeung titik koma.';

  @override
  String get codeNumber => 'Pilih angka ti 1 nepi ka 9.';

  @override
  String get codeDuplicateStar => 'Pake hiji bagian define star wae.';

  @override
  String get codeNestedStar =>
      'Teundeun define star di luar ulangan jeung pamariksaan.';

  @override
  String get codeTooLarge =>
      'Coba program nu leuwih pondok kalawan leuwih saeutik bagian nu ngarundak.';

  @override
  String get codeDisallowed => 'Pake parentah nu aya keur tatarucingan ieu.';

  @override
  String get codeLimit =>
      'Coba kurangan parentah sangkan pas jeung wates blok.';

  @override
  String get codeEmptyBody => 'Tambahkeun parentah di jero kurung kurawal.';

  @override
  String get codeEmptyStar =>
      'Tambahkeun parentah ka define star samemeh make star();.';

  @override
  String get codeRecursiveStar =>
      'Pake lengkah, mengkol, ulangan, atawa pamariksaan di jero define star.';

  @override
  String get codeReady => 'Siap dijalankeun';

  @override
  String get codeStart => 'Tambahkeun parentah pikeun ngamimitian.';

  @override
  String codeLine(int line, String message) {
    return 'Baris $line: $message';
  }

  @override
  String codeRunningLine(int line) {
    return 'Ngajalankeun baris $line';
  }

  @override
  String get codeDefineStar => 'Jieun blok kuring';

  @override
  String get conceptUntil => 'Nepi ka bandera';

  @override
  String get playGoalUntil =>
      'Pake blok ulang nepi ka bandera: blok eta terus jalan sorangan, jadi anjeun teu kudu ngitung!';

  @override
  String get conceptDebugging => 'Omean!';

  @override
  String get playGoalDebugging =>
      'Ups, blok ieu can pas! Pencet Jalan, tempo naon nu kajadian, terus omean.';

  @override
  String get conceptVariables => 'Kotak Lengkah';

  @override
  String get blockSetSteps => 'Simpen lengkah';

  @override
  String get blockMoveSteps => 'Pake lengkah';

  @override
  String get stepsFewer => 'Simpen angka nu leuwih leutik';

  @override
  String get stepsMore => 'Simpen angka nu leuwih gede';

  @override
  String get playGoalVariables =>
      'Simpen angka dina Kotak Lengkah anjeun, terus pake pikeun maju sakitu! Angkana bisa dipake deui atawa diganti. Nepi ka bandera jeung kumpulkeun sakabeh bentang.';

  @override
  String stepBoxValue(String value) {
    return 'Kotak Lengkah: $value';
  }

  @override
  String get codeUnsetSteps =>
      'Simpen angka ku steps = 2; samemeh make move(steps);.';

  @override
  String get variableHint =>
      'Simpen heula angka, terus pake kotak pikeun maju. Angkana tetep sarua nepi ka anjeun ngaganti.';

  @override
  String get tutorialTitle => 'Tempo kuring!';

  @override
  String get tutorialWatchAgain => 'Tempo deui';

  @override
  String get tutorialLetsPlay => 'Hayu ulin!';

  @override
  String get tutorialSkip => 'Liwatan';

  @override
  String get storyTitle => 'Kapal bentang Koba';

  @override
  String get storyShelfIntro => 'Awal carita';

  @override
  String get storyShelfNewPlanet => 'Planet anyar';

  @override
  String get storyShelfEnding => 'Tangkina pinuh!';

  @override
  String get storyShelfFullAgain => 'Tangkina pinuh deui';

  @override
  String get storyIntroFly =>
      'Ieu kapal bentang Koba. Kapal ieu ngapung ku bentang!';

  @override
  String get storyIntroWind =>
      'Wuusss! Angin angkasa niup bentang tina tangkina, ka sakabeh planet.';

  @override
  String get storyIntroLand => 'Bentangna beak, jadi kapalna kudu badarat.';

  @override
  String get storyIntroBump => 'Ups, aya batu! Teu nanaon. Kuring coba deui!';

  @override
  String get storyIntroHelp =>
      'Hayu neangan bentangna babarengan. Daek ngabantu kuring, Komandan?';

  @override
  String get storyFly =>
      'Tangki kuring nambahan bentang! Hayu ka planet saterusna!';

  @override
  String get storyArrivalDirections =>
      'Kapalna badarat di planet nu pinuh ku papan pituduh. Arahna ka mana-mana!';

  @override
  String get storyArrivalDirectionsKoba =>
      'Kuring kudu ka mana? Tuduhkeun ku panah: maju, kenca, atawa katuhu!';

  @override
  String get storyArrivalSequencing =>
      'Di dieu, bentangna aya sapanjang jalan nu mengkol-mengkol.';

  @override
  String get storyArrivalSequencingKoba =>
      'Kuring butuh sakabeh lengkahna runtut, hiji-hiji!';

  @override
  String get storyArrivalLoops =>
      'Di planet ieu, jalanna maju, mengkol, maju, mengkol, terus diulang-ulang.';

  @override
  String get storyArrivalLoopsKoba =>
      'Loba pisan lengkahna! Aya jalan potong, teu?';

  @override
  String get storyArrivalFunctions =>
      'Koba manggihan blok ajaib nu herang dina taneuh.';

  @override
  String get storyArrivalFunctionsKoba =>
      'Blok ieu bisa nginget gerakan kuring! Ajarkeun sakali, terus pake sababaraha kali.';

  @override
  String get storyArrivalConditions =>
      'Halimun kandel nutupan planet ieu. Koba teu bisa nempo jalanna!';

  @override
  String get storyArrivalConditionsKoba =>
      'Kuring ngahurungkeun lampu kuring jeung nempo ka hareup samemeh ngalengkah.';

  @override
  String get storyArrivalVariables =>
      'Di planet ieu, Koba manggihan kotak leutik nu aya angkana.';

  @override
  String get storyArrivalVariablesKoba =>
      'Kotak ieu nginget angka! Angkana nyebutkeun sabaraha lengkah kuring leumpang.';

  @override
  String get storyArrivalDebugging =>
      'Aya nu ninggalkeun blok di jalan, sakabehna pagalo.';

  @override
  String get storyArrivalDebuggingKoba =>
      'Blok ieu can pas. Hayu neangan nu kudu diomean!';

  @override
  String get storyArrivalUntil =>
      'Jauh, jauh pisan, aya bandera di tungtung jalan nu panjang.';

  @override
  String get storyArrivalUntilKoba =>
      'Lengkahna loba teuing keur diitung! Kuring leumpang wae terus nepi ka bandera.';

  @override
  String get storyArrivalOtherwise =>
      'Jalanna nyagak dua. Di hiji jalan aya rungkun!';

  @override
  String get storyArrivalOtherwiseKoba =>
      'Lamun jalanna kosong, kuring maju. Lamun henteu, kuring mengkol!';

  @override
  String get storyEnding =>
      'Bentang panungtung ngapung balik. Tangki Koba pinuh!';

  @override
  String get storyEndingKoba =>
      'Nuhun, Komandan! Anjeun ngabantu kuring manggihan sakabeh bentang.';

  @override
  String get storyEndingMore =>
      'Ayeuna urang bisa ngapung ka mana wae. Hayu terus ulin babarengan!';

  @override
  String get storyFullAgain => 'Bentang-bentang ngapung balik ka tangki.';

  @override
  String get storyNewPlanet =>
      'Wuusss! Angin angkasa niup sababaraha bentang tina tangki, ka planet nu can kungsi kapanggih.';

  @override
  String get storyNewPlanetKoba =>
      'Planet anyar! Daek ngabantu kuring neangan bentang deui, Komandan?';

  @override
  String get storyThanksDirections =>
      'Pinuh deui! Nuhun geus ngajarkeun kuring kenca jeung katuhu, Komandan!';

  @override
  String get storyThanksSequencing =>
      'Pinuh deui! Nuhun geus ngajarkeun kuring lengkah nu runtut, Komandan!';

  @override
  String get storyThanksLoops =>
      'Pinuh deui! Nuhun geus ngajarkeun kuring ngulang, Komandan!';

  @override
  String get storyThanksFunctions =>
      'Pinuh deui! Nuhun geus ngajarkeun kuring Blok Ajaib, Komandan!';

  @override
  String get storyThanksConditions =>
      'Pinuh deui! Nuhun geus ngajarkeun kuring nempo ka hareup, Komandan!';

  @override
  String get storyThanksVariables =>
      'Pinuh deui! Nuhun geus ngajarkeun kuring Kotak Lengkah, Komandan!';

  @override
  String get storyThanksDebugging =>
      'Pinuh deui! Nuhun geus ngajarkeun kuring ngomean blok, Komandan!';

  @override
  String get storyThanksUntil =>
      'Pinuh deui! Nuhun geus ngajarkeun kuring leumpang nepi ka bandera, Komandan!';

  @override
  String get storyThanksOtherwise =>
      'Pinuh deui! Nuhun geus ngajarkeun kuring naon nu dipigawe lamun henteu, Komandan!';

  @override
  String get watchHow => 'Tempo carana';

  @override
  String get tutorialDirections =>
      'Toel blok panah pikeun ngabejaan kuring kudu ka mana: maju, mengkol ka kenca, mengkol ka katuhu. Terus pencet Jalan!';

  @override
  String get tutorialSequencing =>
      'Susun lengkahna runtut, hiji-hiji, nepi ka bandera.';

  @override
  String get tutorialLoops =>
      'Lengkahna sarua wae? Asupkeun kana blok ulang, terus pilih sabaraha kali!';

  @override
  String get tutorialFunctions =>
      'Jieun blok ajaib anjeun sorangan dina baris bentang. Terus pake bentangna sababaraha kali!';

  @override
  String get tutorialConditions =>
      'Blok panon nempo ka hareup. Lamun jalanna kosong, kuring maju. Lamun henteu, kuring nungguan. Jadi blok nu sarua hasil di unggal peta!';

  @override
  String get tutorialVariables =>
      'Simpen angka dina Kotak Lengkah. Terus pake lengkah pikeun leumpang sakitu!';

  @override
  String get tutorialDebugging =>
      'Blok ieu can pas. Pencet Jalan jeung perhatikeun. Terus toel blok nu kudu diomean, jeung toel blok nu bener!';

  @override
  String get tutorialUntil =>
      'Ulang nepi ka bandera terus jalan sorangan, jadi anjeun teu kudu ngitung!';

  @override
  String get hintPattern =>
      'Blok-blok ieu muncul deui jeung deui. Coba pake blok ulang!';

  @override
  String get hintAgain => 'Toel lampu deui pikeun nempo blok nu diulang-ulang!';

  @override
  String get hintLookHere => 'Tempo blok nu aya lampuna. Coba ganti blok eta!';

  @override
  String get hintLookHereMany =>
      'Tempo blok-blok nu aya lampuna. Coba ganti blok-blok eta!';

  @override
  String get turnMap => 'Puterkeun peta';

  @override
  String boardNumber(int number) {
    return 'Peta $number';
  }

  @override
  String get tourPalette =>
      'Ieu blok-blok anjeun. Toel hiji, atawa sered ka program anjeun.';

  @override
  String get tourProgram =>
      'Program anjeun aya di dieu. Kuring ngajalankeun blokna runtut, ti nu kahiji. Toel blok pikeun ngagantina.';

  @override
  String get tourGo => 'Pencet Jalan, jeung kuring nuturkeun blok-blok anjeun!';

  @override
  String get tourStep =>
      'Tombol ieu ngajalankeun hiji blok unggal kali, jadi anjeun bisa nempo kalawan taliti.';

  @override
  String get tourReset => 'Nu ieu mawa kuring balik deui ka awal.';

  @override
  String get tourHint =>
      'Bingung? Sanggeus nyoba sababaraha kali, lampuna hurung. Unggal toel nuduhkeun saeutik deui: kahiji jalanna, terus blok mana nu kudu diganti. Tanda leutik dina lampu nuduhkeun naon saterusna.';

  @override
  String get tourFollow =>
      'Ieu muterkeun peta saparapat puteran unggal kali, jadi anjeun bisa nempo tina sisi kuring.';

  @override
  String get tourBoards =>
      'Di dieu aya sababaraha peta. Toel titik pikeun nempo unggal peta. Blok anjeun kudu mawa kuring nepi ka bandera di unggal peta!';

  @override
  String get tourListen =>
      'Toel spiker pikeun ngadengekeun deui naon nu kudu dipigawe.';

  @override
  String get tourWarmUpListen =>
      'Dengekeun pananyana. Toel spiker pikeun ngadengekeun deui.';

  @override
  String get tourWarmUpAnswer => 'Terus toel gambar nu ceuk anjeun bener!';

  @override
  String get tourWarmUpSteps =>
      'Tapak suku nuduhkeun geus nepi ka mana anjeun ulin.';

  @override
  String get tourBlockForward => 'Panah hejo nyieun kuring maju hiji lengkah.';

  @override
  String get tourBlockTurnLeft =>
      'Panah biru nyieun kuring mengkol ka kenca, tanpa pindah.';

  @override
  String get tourBlockTurnRight =>
      'Panah oranyeu nyieun kuring mengkol ka katuhu, tanpa pindah.';

  @override
  String get tourBlockRepeat =>
      'Blok ulang ngajalankeun blok di jerona sababaraha kali. Toel minus atawa plus pikeun milih sabaraha kali.';

  @override
  String get tourBlockSetSteps =>
      'Kotak Lengkah nyimpen jumlah lengkah. Toel minus atawa plus pikeun ngarobahna.';

  @override
  String get tourBlockMoveSteps =>
      'Panah ieu nyieun kuring maju saloba angka dina Kotak Lengkah.';

  @override
  String get tourBlockIfPathClear =>
      'Blok panon nempo ka hareup. Blok di jerona ngan jalan lamun jalanna kosong.';

  @override
  String get tourBlockIfElse =>
      'Blok panon ieu boga dua baris: baris luhur jalan lamun jalanna kosong, baris handap lamun henteu.';

  @override
  String get tourBlockUntilGoal =>
      'Ulang nepi ka bandera ngajalankeun blok di jerona terus-terusan, nepi ka kuring nepi ka bandera.';

  @override
  String get tourBlockStar =>
      'Blok bentang ngajalankeun blok dina baris bentang anjeun: blok ajaib jieunan anjeun sorangan.';

  @override
  String get tourNext => 'Teruskeun';

  @override
  String get tourDone => 'Ngarti!';

  @override
  String get tourHelp => 'Kumaha carana?';

  @override
  String get breakTitle => 'Waktuna reureuh!';

  @override
  String get breakBody =>
      'Anjeun geus ulin kalawan hebat. Reureuhkeun panon anjeun, coba ngolet, terus ulin deui engke.';

  @override
  String get breakHome => 'Balik deui ka pamaen';

  @override
  String get breakContinue => 'Kolot bisa neruskeun';

  @override
  String get breakVoice =>
      'Waktuna reureuh! Anjeun geus ulin kalawan hebat. Reureuhkeun panon anjeun, coba ngolet, terus ulin deui engke.';

  @override
  String get breakReminder => 'Pangeling reureuh';

  @override
  String get breakReminderHint =>
      'Sanggeus ulin tatarucingan salila ieu, barudak diajak reureuh. Ngan kolot nu bisa neruskeun.';

  @override
  String get breakOff => 'Pareum';

  @override
  String breakMinutes(int minutes) {
    return '$minutes mnt';
  }

  @override
  String nextIslandSoon(int count, String island) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ngan $count tatarucingan deui bisa mawa anjeun ka $island!',
      one: 'Tatarucingan saterusna bisa mawa anjeun ka $island!',
    );
    return '$_temp0';
  }

  @override
  String get conceptWarmUp => 'Pemanasan';

  @override
  String get warmUpCounting => 'Ngitung';

  @override
  String get warmUpColors => 'Warna';

  @override
  String get warmUpShapes => 'Wangun';

  @override
  String get warmUpPatterns => 'Pola';

  @override
  String get warmUpSides => 'Kenca jeung katuhu';

  @override
  String get warmUpSteps => 'Lengkah';

  @override
  String get warmUpReading => 'Maca';

  @override
  String get warmUpPick => 'Pilih kaulinan!';

  @override
  String get warmUpDone => 'Alus pisan ulinna! Ulin deui?';

  @override
  String get playAgain => 'Ulin deui';

  @override
  String get promptColorRed => 'Toel nu beureum!';

  @override
  String get promptColorBlue => 'Toel nu biru!';

  @override
  String get promptColorGreen => 'Toel nu hejo!';

  @override
  String get promptColorYellow => 'Toel nu koneng!';

  @override
  String get promptShapeCircle => 'Toel buleudan!';

  @override
  String get promptShapeSquare => 'Toel pasagi!';

  @override
  String get promptShapeTriangle => 'Toel segitilu!';

  @override
  String get promptShapeHeart => 'Toel hate!';

  @override
  String playLevel(int number) {
    return 'Ulin level $number';
  }

  @override
  String get stickerBook => 'Buku stiker';

  @override
  String get stickerBookHello => 'Tempo sakabeh stiker anjeun!';

  @override
  String get stickersIslands => 'Planet';

  @override
  String get stickerNotYet => 'Can meunang';

  @override
  String get stickerGold => 'Sakabeh bentang geus kakumpulkeun!';

  @override
  String get blockIfElse => 'Lamun kosong, lamun henteu';

  @override
  String get otherwiseRowClear => 'Lamun jalanna kosong';

  @override
  String get otherwiseRowBlocked => 'Lamun henteu';

  @override
  String get conceptOtherwise => 'Lamun henteu';

  @override
  String get playGoalOtherwise =>
      'Pake blok panon nu dua baris: lamun jalanna kosong, ngalengkah. Lamun henteu, mengkol!';

  @override
  String get tutorialOtherwise =>
      'Panon nempo ka hareup. Lamun jalanna kosong, ngalengkah. Lamun henteu, mengkol. Terus sakabehna diulang nepi ka bandera!';

  @override
  String starsEarned(int count) {
    return '$count tina 3 bentang';
  }

  @override
  String get progressFileTitle => 'Pindah ka alat sejen';

  @override
  String progressFileHint(String name) {
    return 'Simpen kamajuan $name kana file, terus buka dina Coba Lagi di alat sejen. Muka ngan ukur nambahan nu geus aya; euweuh nu leungit.';
  }

  @override
  String get saveProgress => 'Simpen kamajuan';

  @override
  String get loadProgress => 'Buka kamajuan';

  @override
  String loadProgressConfirm(String fileName, String name) {
    return 'Tambahkeun kamajuan tina file $fileName ka $name? Bentang jeung palajaran nu geus rengse ti duanana tetep disimpen.';
  }

  @override
  String get load => 'Buka';

  @override
  String get progressSaved => 'Kamajuan geus disimpen';

  @override
  String get progressLoaded => 'Kamajuan geus dibuka';

  @override
  String get progressFileNotProgress => 'File ieu lain kamajuan Coba Lagi.';

  @override
  String get progressFileTooNew =>
      'File ieu ti Coba Lagi nu leuwih anyar. Anyarkeun heula aplikasina.';

  @override
  String get loadPlayer => 'Buka pamaen tina file';

  @override
  String playerLoaded(String name) {
    return '$name geus ngagabung';
  }
}
