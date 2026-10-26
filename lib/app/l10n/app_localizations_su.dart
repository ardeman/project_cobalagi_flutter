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
  String get editPlayer => 'Robah pamaén';

  @override
  String get addPlayer => 'Pamaén anyar';

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
  String get ok => 'Oké';

  @override
  String greeting(String name) {
    return 'Hai, $name!';
  }

  @override
  String get play => 'Ulin';

  @override
  String get askAGrownUp => 'Ménta tulung ka kolot';

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
  String get plan => 'Vérsi';

  @override
  String get planFree => 'Biasa: 1 pamaén';

  @override
  String planFull(int count) {
    return 'Sponsor: nepi ka $count pamaén';
  }

  @override
  String appVersion(String version, String build) {
    return 'Vérsi aplikasi $version ($build)';
  }

  @override
  String progressTitle(String name) {
    return 'Kamajuan $name';
  }

  @override
  String get changeStartingIsland => 'Ganti planét awal';

  @override
  String get progressThisWeek => '7 poé panungtung';

  @override
  String get progressAllTime => 'Ti awal';

  @override
  String progressPuzzles(int count) {
    return '$count tatarucingan réngsé';
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
  String get progressNotPlayed => 'Can ngaréngsékeun tatarucingan';

  @override
  String get progressIslands => 'Planét';

  @override
  String get statusNotStarted => 'Can dimimitian';

  @override
  String get statusPractising => 'Keur latihan';

  @override
  String get statusMastered => 'Geus dikawasa';

  @override
  String progressLevels(int solved, int total) {
    return '$solved tina $total level réngsé';
  }

  @override
  String get progressSponsorOnly =>
      'Sponsor bisa nempo laporan kamajuan nu lengkep: tatarucingan nu réngsé, waktu ulin, jeung kamajuan di unggal planét.';

  @override
  String get music => 'Musik latar';

  @override
  String get soundEffects => 'Éfék sora';

  @override
  String get hintArrowsFollowRoad => 'Panah pituduh nuturkeun jalan';

  @override
  String get hintArrowsFollowRoadHint =>
      'Pareum: panah nyanghareup ka luhur, siga dina blok.';

  @override
  String get soundEffectsHint => 'Sora pituduh tetep kadéngé.';

  @override
  String get supportCobaLagi => 'Dukung Coba Lagi';

  @override
  String get debugPlanOverride => 'Debug: paké vérsi lengkep';

  @override
  String get players => 'Pamaén';

  @override
  String deletePlayerConfirm(String name) {
    return 'Pupus $name jeung sakabéh kamajuanana?';
  }

  @override
  String get playerLimitReached =>
      'Vérsi ieu ngan keur hiji pamaén. Ménta tulung ka kolot.';

  @override
  String get run => 'Jalan!';

  @override
  String get step => 'Hiji léngkah';

  @override
  String get reset => 'Mimitian deui';

  @override
  String get undo => 'Bolaykeun';

  @override
  String get redo => 'Balikan deui';

  @override
  String get clearBlocks => 'Pupus sakabéh blok';

  @override
  String get removeBlock => 'Pupus blok ieu';

  @override
  String get blockForward => 'Maju';

  @override
  String get blockTurnLeft => 'Méngkol ka kénca';

  @override
  String get blockTurnRight => 'Méngkol ka katuhu';

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
      'Saeutik deui! Terus leumpang nepi ka bandéra.';

  @override
  String get feedbackOtherBoard =>
      'Peta éta geus hasil! Peta ieu béda, jadi tempo ka hareup saméméh unggal léngkah.';

  @override
  String get feedbackMissedStars => 'Kumpulkeun heula sakabéh béntang.';

  @override
  String get feedbackTooManySteps =>
      'Léngkahna loba teuing! Coba leuwih saeutik.';

  @override
  String get home => 'Tepas';

  @override
  String get conceptDirections => 'Arah';

  @override
  String get conceptSequencing => 'Léngkah demi léngkah';

  @override
  String get conceptLoops => 'Ngulang';

  @override
  String get conceptFunctions => 'Blok Ajaib';

  @override
  String get decisionAdvance => 'Planét anyar kabuka!';

  @override
  String get decisionPractice => 'Hayu coba nu séjén!';

  @override
  String get bonusAdventure => 'Petualangan bonus!';

  @override
  String get decisionReview => 'Hayu néangan harta karun di planét saméméhna.';

  @override
  String get decisionReturn => 'Balik deui ka petualangan anjeun!';

  @override
  String get decisionMapComplete => 'Anjeun geus ngajajah sakabéh planét!';

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
  String get promptSideLeft => 'Toél nu di beulah kénca.';

  @override
  String get promptSideRight => 'Toél nu di beulah katuhu.';

  @override
  String get promptTurnLeft =>
      'Panahna méngkol ka kénca. Ayeuna nunjuk ka mana?';

  @override
  String get promptTurnRight =>
      'Panahna méngkol ka katuhu. Ayeuna nunjuk ka mana?';

  @override
  String get promptPattern => 'Naon saterusna?';

  @override
  String get promptSequencing => 'Léngkah mana nu nepi ka bandéra?';

  @override
  String get pretestDone => 'Réngsé! Petualangan anjeun dimimitian ayeuna.';

  @override
  String get startAdventure => 'Hayu!';

  @override
  String get wordSun => 'panonpoé';

  @override
  String get wordStar => 'béntang';

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
  String get wordCake => 'kuéh';

  @override
  String get colorRed => 'beureum';

  @override
  String get colorBlue => 'biru';

  @override
  String get colorGreen => 'héjo';

  @override
  String get colorYellow => 'konéng';

  @override
  String wordsWithColor(String color, String object) {
    return '$object $color';
  }

  @override
  String get startingIsland => 'Planét awal';

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
  String get cheerCelebrate1 => 'Hébat!';

  @override
  String get cheerCelebrate2 => 'Kerén!';

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
  String get cheerEncourage5 => 'Anjeun hébat!';

  @override
  String get donateExplainer =>
      'Coba Lagi gratis. Donasi sabaraha waé muka fitur sponsor keur kulawarga anjeun jeung ngabantu kami nyieun leuwih loba petualangan.';

  @override
  String get donateUnavailable => 'Donasi teu aya dina alat ieu.';

  @override
  String get restoreDonation => 'Pulihkeun donasi saméméhna';

  @override
  String get tipExplainer =>
      'Coba Lagi gratis. Tip sabaraha waé muka fitur sponsor keur kulawarga anjeun jeung ngabantu kami nyieun leuwih loba petualangan.';

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
  String get useUnlockCode => 'Paké kode';

  @override
  String get unlockCodeRejected =>
      'Kode éta teu laku. Pariksa deui, terus coba sakali deui.';

  @override
  String get thanksForSupport => 'Nuhun geus ngadukung Coba Lagi!';

  @override
  String get playGoal => 'Bantuan kuring nepi ka bandéra!';

  @override
  String get playGoalStars => 'Kumpulkeun sakabéh béntang, terus ka bandéra!';

  @override
  String get playGoalLoops => 'Paké blok ulang sangkan nepi ka bandéra!';

  @override
  String get playGoalFunctions =>
      'Eusian blok béntang, terus paké sababaraha kali sangkan nepi ka bandéra!';

  @override
  String get playHowTo => 'Séréd blok ka kotak bodas, terus pencét Jalan!';

  @override
  String get backToIsland => 'Balik deui ka planét';

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
  String get blockUntilGoal => 'Ulang nepi ka bandéra';

  @override
  String get blockIfPathClear => 'Lamun kosong';

  @override
  String get playGoalConditions =>
      'Tempo ka hareup! Teundeun blok maju di jero blok panon. Éta ngan maju lamun jalan di hareup kosong. Blok anjeun kudu hasil di unggal peta!';

  @override
  String get updateAvailableTitle => 'Aya pembaruan';

  @override
  String get updateAvailableBody =>
      'Vérsi panganyarna Coba Lagi geus aya. Ménta tulung ka kolot pikeun ngapdét aplikasi.';

  @override
  String get updateWithParent => 'Ménta tulung ngapdét';

  @override
  String get updateContinue => 'Terus ulin';

  @override
  String get updateOpenFailed =>
      'Pembaruan can bisa dibuka. Coba deui atawa terus ulin.';

  @override
  String get codeTab => 'Tab Kode';

  @override
  String get codeTabHint =>
      'Barudak bisa ngetik kode salian ti maké blok gambar. Ulin pemanasan ngahurungkeunana keur barudak nu geus bisa maca.';

  @override
  String get editorBlocks => 'Blok';

  @override
  String get editorCode => 'Kode';

  @override
  String get codeDrafts =>
      'Unggal éditor nyimpen draf sorangan. Draf kode kahiji asalna tina blok anjeun.';

  @override
  String get codeHelp => 'Pituduh kode';

  @override
  String get codeSource => 'Kode anjeun';

  @override
  String get codeGuide =>
      'Toél paréntah pikeun nambahkeunana, atawa ketik sorangan. Ngaran paréntah tetep sarua dina sakabéh basa. Tungtungan aksi ku (); jeung teundeun eusi ulangan jeung pamariksaan di antara kurung kurawal muka jeung nutup. Jumlah ulangan 1–9. Jieun Blok Ajaib ku define star, terus jalankeun ku star();. // ngamimitian koméntar. Unggal paréntah diitung hiji blok, kaasup paréntah di jero kurung kurawal. Simpen angka ku steps = 3; jeung paké move(steps); pikeun maju sakitu. Angkana tetep sarua nepi ka anjeun nyimpen nu anyar. Simpen saméméh makéna. until_flag ngulang eusi kurung kurawalna nepi ka robot nepi ka bandéra, tanpa itungan.';

  @override
  String get codeSyntax =>
      'Pariksa ngaran paréntah, tanda kurung, kurung kurawal, jeung titik koma.';

  @override
  String get codeNumber => 'Pilih angka ti 1 nepi ka 9.';

  @override
  String get codeDuplicateStar => 'Paké hiji bagian define star waé.';

  @override
  String get codeNestedStar =>
      'Teundeun define star di luar ulangan jeung pamariksaan.';

  @override
  String get codeTooLarge =>
      'Coba program nu leuwih pondok kalawan leuwih saeutik bagian nu ngarundak.';

  @override
  String get codeDisallowed => 'Paké paréntah nu aya keur tatarucingan ieu.';

  @override
  String get codeLimit =>
      'Coba kurangan paréntah sangkan pas jeung wates blok.';

  @override
  String get codeEmptyBody => 'Tambahkeun paréntah di jero kurung kurawal.';

  @override
  String get codeEmptyStar =>
      'Tambahkeun paréntah ka define star saméméh maké star();.';

  @override
  String get codeRecursiveStar =>
      'Paké léngkah, méngkol, ulangan, atawa pamariksaan di jero define star.';

  @override
  String get codeReady => 'Siap dijalankeun';

  @override
  String get codeStart => 'Tambahkeun paréntah pikeun ngamimitian.';

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
  String get conceptUntil => 'Nepi ka bandéra';

  @override
  String get playGoalUntil =>
      'Paké blok ulang nepi ka bandéra: blok éta terus jalan sorangan, jadi anjeun teu kudu ngitung!';

  @override
  String get conceptDebugging => 'Oméan!';

  @override
  String get playGoalDebugging =>
      'Ups, blok ieu can pas! Pencét Jalan, tempo naon nu kajadian, terus oméan.';

  @override
  String get conceptVariables => 'Kotak Léngkah';

  @override
  String get blockSetSteps => 'Simpen léngkah';

  @override
  String get blockMoveSteps => 'Paké léngkah';

  @override
  String get stepsFewer => 'Simpen angka nu leuwih leutik';

  @override
  String get stepsMore => 'Simpen angka nu leuwih gedé';

  @override
  String get playGoalVariables =>
      'Simpen angka dina Kotak Léngkah anjeun, terus paké pikeun maju sakitu! Angkana bisa dipaké deui atawa diganti. Nepi ka bandéra jeung kumpulkeun sakabéh béntang.';

  @override
  String stepBoxValue(String value) {
    return 'Kotak Léngkah: $value';
  }

  @override
  String get codeUnsetSteps =>
      'Simpen angka ku steps = 2; saméméh maké move(steps);.';

  @override
  String get variableHint =>
      'Simpen heula angka, terus paké kotak pikeun maju. Angkana tetep sarua nepi ka anjeun ngaganti.';

  @override
  String get tutorialTitle => 'Tempo kuring!';

  @override
  String get tutorialWatchAgain => 'Tempo deui';

  @override
  String get tutorialLetsPlay => 'Hayu ulin!';

  @override
  String get tutorialSkip => 'Liwatan';

  @override
  String get storyTitle => 'Kapal béntang Koba';

  @override
  String get storyShelfIntro => 'Awal carita';

  @override
  String get storyShelfNewPlanet => 'Planét anyar';

  @override
  String get storyShelfEnding => 'Tangkina pinuh!';

  @override
  String get storyShelfFullAgain => 'Tangkina pinuh deui';

  @override
  String get storyIntroFly =>
      'Ieu kapal béntang Koba. Kapal ieu ngapung ku béntang!';

  @override
  String get storyIntroWind =>
      'Wuusss! Angin angkasa niup béntang tina tangkina, ka sakabéh planét.';

  @override
  String get storyIntroLand => 'Béntangna béak, jadi kapalna kudu badarat.';

  @override
  String get storyIntroBump => 'Ups, aya batu! Teu nanaon. Kuring coba deui!';

  @override
  String get storyIntroHelp =>
      'Hayu néangan béntangna babarengan. Daék ngabantu kuring, Komandan?';

  @override
  String get storyFly =>
      'Tangki kuring nambahan béntang! Hayu ka planét saterusna!';

  @override
  String get storyArrivalDirections =>
      'Kapalna badarat di planét nu pinuh ku papan pituduh. Arahna ka mana-mana!';

  @override
  String get storyArrivalDirectionsKoba =>
      'Kuring kudu ka mana? Tuduhkeun ku panah: maju, kénca, atawa katuhu!';

  @override
  String get storyArrivalSequencing =>
      'Di dieu, béntangna aya sapanjang jalan nu méngkol-méngkol.';

  @override
  String get storyArrivalSequencingKoba =>
      'Kuring butuh sakabéh léngkahna runtut, hiji-hiji!';

  @override
  String get storyArrivalLoops =>
      'Di planét ieu, jalanna maju, méngkol, maju, méngkol, terus diulang-ulang.';

  @override
  String get storyArrivalLoopsKoba =>
      'Loba pisan léngkahna! Aya jalan potong, teu?';

  @override
  String get storyArrivalFunctions =>
      'Koba manggihan blok ajaib nu hérang dina taneuh.';

  @override
  String get storyArrivalFunctionsKoba =>
      'Blok ieu bisa nginget gerakan kuring! Ajarkeun sakali, terus paké sababaraha kali.';

  @override
  String get storyArrivalConditions =>
      'Halimun kandel nutupan planét ieu. Koba teu bisa nempo jalanna!';

  @override
  String get storyArrivalConditionsKoba =>
      'Kuring ngahurungkeun lampu kuring jeung nempo ka hareup saméméh ngaléngkah.';

  @override
  String get storyArrivalVariables =>
      'Di planét ieu, Koba manggihan kotak leutik nu aya angkana.';

  @override
  String get storyArrivalVariablesKoba =>
      'Kotak ieu nginget angka! Angkana nyebutkeun sabaraha léngkah kuring leumpang.';

  @override
  String get storyArrivalDebugging =>
      'Aya nu ninggalkeun blok di jalan, sakabéhna pagalo.';

  @override
  String get storyArrivalDebuggingKoba =>
      'Blok ieu can pas. Hayu néangan nu kudu dioméan!';

  @override
  String get storyArrivalUntil =>
      'Jauh, jauh pisan, aya bandéra di tungtung jalan nu panjang.';

  @override
  String get storyArrivalUntilKoba =>
      'Léngkahna loba teuing keur diitung! Kuring leumpang waé terus nepi ka bandéra.';

  @override
  String get storyArrivalOtherwise =>
      'Jalanna nyagak dua. Di hiji jalan aya rungkun!';

  @override
  String get storyArrivalOtherwiseKoba =>
      'Lamun jalanna kosong, kuring maju. Lamun henteu, kuring méngkol!';

  @override
  String get storyEnding =>
      'Béntang panungtung ngapung balik. Tangki Koba pinuh!';

  @override
  String get storyEndingKoba =>
      'Nuhun, Komandan! Anjeun ngabantu kuring manggihan sakabéh béntang.';

  @override
  String get storyEndingMore =>
      'Ayeuna urang bisa ngapung ka mana waé. Hayu terus ulin babarengan!';

  @override
  String get storyFullAgain => 'Béntang-béntang ngapung balik ka tangki.';

  @override
  String get storyNewPlanet =>
      'Wuusss! Angin angkasa niup sababaraha béntang tina tangki, ka planét nu can kungsi kapanggih.';

  @override
  String get storyNewPlanetKoba =>
      'Planét anyar! Daék ngabantu kuring néangan béntang deui, Komandan?';

  @override
  String get storyThanksDirections =>
      'Pinuh deui! Nuhun geus ngajarkeun kuring kénca jeung katuhu, Komandan!';

  @override
  String get storyThanksSequencing =>
      'Pinuh deui! Nuhun geus ngajarkeun kuring léngkah nu runtut, Komandan!';

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
      'Pinuh deui! Nuhun geus ngajarkeun kuring Kotak Léngkah, Komandan!';

  @override
  String get storyThanksDebugging =>
      'Pinuh deui! Nuhun geus ngajarkeun kuring ngoméan blok, Komandan!';

  @override
  String get storyThanksUntil =>
      'Pinuh deui! Nuhun geus ngajarkeun kuring leumpang nepi ka bandéra, Komandan!';

  @override
  String get storyThanksOtherwise =>
      'Pinuh deui! Nuhun geus ngajarkeun kuring naon nu dipigawé lamun henteu, Komandan!';

  @override
  String get watchHow => 'Tempo carana';

  @override
  String get tutorialDirections =>
      'Toél blok panah pikeun ngabéjaan kuring kudu ka mana: maju, méngkol ka kénca, méngkol ka katuhu. Terus pencét Jalan!';

  @override
  String get tutorialSequencing =>
      'Susun léngkahna runtut, hiji-hiji, nepi ka bandéra.';

  @override
  String get tutorialLoops =>
      'Léngkahna sarua waé? Asupkeun kana blok ulang, terus pilih sabaraha kali!';

  @override
  String get tutorialFunctions =>
      'Jieun blok ajaib anjeun sorangan dina baris béntang. Terus paké béntangna sababaraha kali!';

  @override
  String get tutorialConditions =>
      'Blok panon nempo ka hareup. Lamun jalanna kosong, kuring maju. Lamun henteu, kuring nungguan. Jadi blok nu sarua hasil di unggal peta!';

  @override
  String get tutorialVariables =>
      'Simpen angka dina Kotak Léngkah. Terus paké léngkah pikeun leumpang sakitu!';

  @override
  String get tutorialDebugging =>
      'Blok ieu can pas. Pencét Jalan jeung perhatikeun. Terus toél blok nu kudu dioméan, jeung toél blok nu bener!';

  @override
  String get tutorialUntil =>
      'Ulang nepi ka bandéra terus jalan sorangan, jadi anjeun teu kudu ngitung!';

  @override
  String get hintPattern =>
      'Blok-blok ieu muncul deui jeung deui. Coba paké blok ulang!';

  @override
  String get hintAgain => 'Toél lampu deui pikeun nempo blok nu diulang-ulang!';

  @override
  String get hintLookHere => 'Tempo blok nu aya lampuna. Coba ganti blok éta!';

  @override
  String get hintLookHereMany =>
      'Tempo blok-blok nu aya lampuna. Coba ganti blok-blok éta!';

  @override
  String get turnMap => 'Puterkeun peta';

  @override
  String boardNumber(int number) {
    return 'Peta $number';
  }

  @override
  String get tourPalette =>
      'Ieu blok-blok anjeun. Toél hiji, atawa séréd ka program anjeun.';

  @override
  String get tourProgram =>
      'Program anjeun aya di dieu. Kuring ngajalankeun blokna runtut, ti nu kahiji. Toél blok pikeun ngagantina.';

  @override
  String get tourGo => 'Pencét Jalan, jeung kuring nuturkeun blok-blok anjeun!';

  @override
  String get tourStep =>
      'Tombol ieu ngajalankeun hiji blok unggal kali, jadi anjeun bisa nempo kalawan taliti.';

  @override
  String get tourReset => 'Nu ieu mawa kuring balik deui ka awal.';

  @override
  String get tourHint =>
      'Bingung? Sanggeus nyoba sababaraha kali, lampuna hurung. Unggal toél nuduhkeun saeutik deui: kahiji jalanna, terus blok mana nu kudu diganti. Tanda leutik dina lampu nuduhkeun naon saterusna.';

  @override
  String get tourFollow =>
      'Ieu muterkeun peta saparapat puteran unggal kali, jadi anjeun bisa nempo tina sisi kuring.';

  @override
  String get tourBoards =>
      'Di dieu aya sababaraha peta. Toél titik pikeun nempo unggal peta. Blok anjeun kudu mawa kuring nepi ka bandéra di unggal peta!';

  @override
  String get tourListen =>
      'Toél spiker pikeun ngadéngékeun deui naon nu kudu dipigawé.';

  @override
  String get tourWarmUpListen =>
      'Dengekeun pananyana. Toél spiker pikeun ngadéngékeun deui.';

  @override
  String get tourWarmUpAnswer => 'Terus toél gambar nu ceuk anjeun bener!';

  @override
  String get tourWarmUpSteps =>
      'Tapak suku nuduhkeun geus nepi ka mana anjeun ulin.';

  @override
  String get tourBlockForward => 'Panah héjo nyieun kuring maju hiji léngkah.';

  @override
  String get tourBlockTurnLeft =>
      'Panah biru nyieun kuring méngkol ka kénca, tanpa pindah.';

  @override
  String get tourBlockTurnRight =>
      'Panah oranyeu nyieun kuring méngkol ka katuhu, tanpa pindah.';

  @override
  String get tourBlockRepeat =>
      'Blok ulang ngajalankeun blok di jerona sababaraha kali. Toél minus atawa plus pikeun milih sabaraha kali.';

  @override
  String get tourBlockSetSteps =>
      'Kotak Léngkah nyimpen jumlah léngkah. Toél minus atawa plus pikeun ngarobahna.';

  @override
  String get tourBlockMoveSteps =>
      'Panah ieu nyieun kuring maju saloba angka dina Kotak Léngkah.';

  @override
  String get tourBlockIfPathClear =>
      'Blok panon nempo ka hareup. Blok di jerona ngan jalan lamun jalanna kosong.';

  @override
  String get tourBlockIfElse =>
      'Blok panon ieu boga dua baris: baris luhur jalan lamun jalanna kosong, baris handap lamun henteu.';

  @override
  String get tourBlockUntilGoal =>
      'Ulang nepi ka bandéra ngajalankeun blok di jerona terus-terusan, nepi ka kuring nepi ka bandéra.';

  @override
  String get tourBlockStar =>
      'Blok béntang ngajalankeun blok dina baris béntang anjeun: blok ajaib jieunan anjeun sorangan.';

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
      'Anjeun geus ulin kalawan hébat. Reureuhkeun panon anjeun, coba ngolét, terus ulin deui engké.';

  @override
  String get breakHome => 'Balik deui ka pamaén';

  @override
  String get breakContinue => 'Kolot bisa neruskeun';

  @override
  String get breakVoice =>
      'Waktuna reureuh! Anjeun geus ulin kalawan hébat. Reureuhkeun panon anjeun, coba ngolét, terus ulin deui engké.';

  @override
  String get breakReminder => 'Pangéling reureuh';

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
  String get warmUpSides => 'Kénca jeung katuhu';

  @override
  String get warmUpSteps => 'Léngkah';

  @override
  String get warmUpReading => 'Maca';

  @override
  String get warmUpPick => 'Pilih kaulinan!';

  @override
  String get warmUpDone => 'Alus pisan ulinna! Ulin deui?';

  @override
  String get playAgain => 'Ulin deui';

  @override
  String get promptColorRed => 'Toél nu beureum!';

  @override
  String get promptColorBlue => 'Toél nu biru!';

  @override
  String get promptColorGreen => 'Toél nu héjo!';

  @override
  String get promptColorYellow => 'Toél nu konéng!';

  @override
  String get promptShapeCircle => 'Toél buleudan!';

  @override
  String get promptShapeSquare => 'Toél pasagi!';

  @override
  String get promptShapeTriangle => 'Toél segitilu!';

  @override
  String get promptShapeHeart => 'Toél haté!';

  @override
  String playLevel(int number) {
    return 'Ulin level $number';
  }

  @override
  String get stickerBook => 'Buku stiker';

  @override
  String get stickerBookHello => 'Tempo sakabéh stiker anjeun!';

  @override
  String get stickersIslands => 'Planét';

  @override
  String get stickerNotYet => 'Can meunang';

  @override
  String get stickerGold => 'Sakabéh béntang geus kakumpulkeun!';

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
      'Paké blok panon nu dua baris: lamun jalanna kosong, ngaléngkah. Lamun henteu, méngkol!';

  @override
  String get tutorialOtherwise =>
      'Panon nempo ka hareup. Lamun jalanna kosong, ngaléngkah. Lamun henteu, méngkol. Terus sakabéhna diulang nepi ka bandéra!';

  @override
  String starsEarned(int count) {
    return '$count tina 3 béntang';
  }
}
