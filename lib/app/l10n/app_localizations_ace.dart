// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Achinese (`ace`).
class AppLocalizationsAce extends AppLocalizations {
  AppLocalizationsAce([String locale = 'ace']) : super(locale);

  @override
  String get appTitle => 'Coba Lagi';

  @override
  String get whoIsPlaying => 'Soe nyang meu\'en?';

  @override
  String get editPlayer => 'Gantoe ureueng meu\'en';

  @override
  String get addPlayer => 'Ureueng meu\'en barô';

  @override
  String get nickname => 'Nan panggilan';

  @override
  String get chooseAvatar => 'Piléh gamba';

  @override
  String get save => 'Keubah';

  @override
  String get cancel => 'Batai';

  @override
  String get delete => 'Hapôh';

  @override
  String get ok => 'Nyo';

  @override
  String greeting(String name) {
    return 'Hai, $name!';
  }

  @override
  String get play => 'Meu\'en';

  @override
  String get askAGrownUp => 'Lakèe bantu bak ureueng tuha';

  @override
  String parentGateQuestion(int a, int b) {
    return 'Padum $a × $b?';
  }

  @override
  String get parentGateWrong => 'Goh lom beutôi. Cuba lom.';

  @override
  String get parentArea => 'Teumpat ureueng tuha';

  @override
  String get language => 'Bahsa';

  @override
  String get languageSystem => 'Ikôt perangkat';

  @override
  String get plan => 'Versi';

  @override
  String get planFree => 'Biasa: 1 ureueng meu\'en';

  @override
  String planFull(int count) {
    return 'Sponsor: trôk $count ureueng meu\'en';
  }

  @override
  String appVersion(String version, String build) {
    return 'Versi aplikasi $version ($build)';
  }

  @override
  String progressTitle(String name) {
    return 'Kemajuan $name';
  }

  @override
  String get changeStartingIsland => 'Gantoe planet phôn';

  @override
  String get progressThisWeek => '7 uroe nyang ka lheueh';

  @override
  String get progressAllTime => 'Yoh phôn';

  @override
  String progressPuzzles(int count) {
    return '$count teka-teki ka lheueh';
  }

  @override
  String progressMinutes(int count) {
    return '$count meunét meu\'en';
  }

  @override
  String progressLastPlayed(String date) {
    return 'Akhé meu\'en: $date';
  }

  @override
  String get progressNotPlayed => 'Goh lom lheueh teka-teki';

  @override
  String get progressIslands => 'Planet';

  @override
  String get statusNotStarted => 'Goh lom phôn';

  @override
  String get statusPractising => 'Teungoh meulatéh';

  @override
  String get statusMastered => 'Ka meuphôm';

  @override
  String progressLevels(int solved, int total) {
    return '$solved nibak $total level ka lheueh';
  }

  @override
  String get progressSponsorOnly =>
      'Sponsor jeuet geukalon laporan kemajuan nyang leungkap: teka-teki nyang ka lheueh, watèe meu\'en, ngon kemajuan bak tiep-tiep planet.';

  @override
  String get music => 'Musik';

  @override
  String get soundEffects => 'Su efek';

  @override
  String get hintArrowsFollowRoad => 'Panah peutunjôk ikôt jalan';

  @override
  String get hintArrowsFollowRoadHint =>
      'Mate: panah ngadap u ateuh, lagée bak blok.';

  @override
  String get soundEffectsHint => 'Su peutunjôk teutap meudeungo.';

  @override
  String get supportCobaLagi => 'Dukông Coba Lagi';

  @override
  String get debugPlanOverride => 'Debug: pakè versi leungkap';

  @override
  String get players => 'Ureueng meu\'en';

  @override
  String deletePlayerConfirm(String name) {
    return 'Hapôh $name ngon mandum kemajuan jih?';
  }

  @override
  String get playerLimitReached =>
      'Versi nyoe keu sidroe ureueng meu\'en mantong. Lakèe bantu bak ureueng tuha.';

  @override
  String get run => 'Jak!';

  @override
  String get step => 'Sa langkah';

  @override
  String get reset => 'Phôn lom';

  @override
  String get undo => 'Peuriwang';

  @override
  String get redo => 'Peubalék';

  @override
  String get clearBlocks => 'Hapôh mandum blok';

  @override
  String get removeBlock => 'Hapôh blok nyoe';

  @override
  String get blockForward => 'U keue';

  @override
  String get blockTurnLeft => 'Beulôk u wie';

  @override
  String get blockTurnRight => 'Beulôk u uneun';

  @override
  String get blockRepeat => 'Ulang';

  @override
  String get blockStar => 'Blok peugöt lôn';

  @override
  String get toMap => 'U peta';

  @override
  String get tryAgain => 'Cuba lom!';

  @override
  String get feedbackBumped => 'Ups, na nyang theun.';

  @override
  String get feedbackStoppedShort => 'Ka toe! Jak laju trôk u bandéra.';

  @override
  String get feedbackOtherBoard =>
      'Peta nyan ka jadéh! Peta nyoe laén, jadi kalon u keue sigohlom tiep langkah.';

  @override
  String get feedbackMissedStars => 'Kumpôi mandum bintang dilèe.';

  @override
  String get feedbackTooManySteps =>
      'Langkah jih le that! Cuba nyang leubèh bacut.';

  @override
  String get home => 'Beranda';

  @override
  String get conceptDirections => 'Arah';

  @override
  String get conceptSequencing => 'Langkah keu langkah';

  @override
  String get conceptLoops => 'Ulang-ulang';

  @override
  String get conceptFunctions => 'Blok Ajaib';

  @override
  String get decisionAdvance => 'Planet barô ka teuhah!';

  @override
  String get decisionPractice => 'Jak tacuba nyang laén!';

  @override
  String get bonusAdventure => 'Petualangan bonus!';

  @override
  String get decisionReview => 'Jak tamita harta karôn bak planet nyang ilèe.';

  @override
  String get decisionReturn => 'Woe u petualangan kah!';

  @override
  String get decisionMapComplete => 'Kah ka kajeulajah mandum planet!';

  @override
  String get hint => 'Peuleumah jalan jih';

  @override
  String get hintNextPattern => 'Peuleumah blok nyang meu-ulang';

  @override
  String get hintNextRing => 'Peuleumah blok nyang peureulèe gantoe';

  @override
  String get repeatMore => 'Tamah sigo';

  @override
  String get repeatFewer => 'Kurang sigo';

  @override
  String get dropBlocksHere => 'Boh blok keunoe';

  @override
  String get pretestWelcome => 'Hai, lôn Koba! Jak tameu\'en peumanaih dilèe!';

  @override
  String get pretestStart => 'Phôn';

  @override
  String get listenAgain => 'Deungo lom';

  @override
  String get promptReading => 'Gamba pat nyang pah ngon tuléh nyoe?';

  @override
  String get promptCounting => 'Padum boh?';

  @override
  String get promptSideLeft => 'Teukan nyang di wie.';

  @override
  String get promptSideRight => 'Teukan nyang di uneun.';

  @override
  String get promptTurnLeft => 'Panah beulôk u wie. Jinoe jih tunjôk u pat?';

  @override
  String get promptTurnRight => 'Panah beulôk u uneun. Jinoe jih tunjôk u pat?';

  @override
  String get promptPattern => 'Peue nyang lheuh nyoe?';

  @override
  String get promptSequencing => 'Langkah pat nyang trôk u bandéra?';

  @override
  String get pretestDone => 'Ka lheueh! Petualangan kah phôn jinoe.';

  @override
  String get startAdventure => 'Jak!';

  @override
  String get wordSun => 'mata uroe';

  @override
  String get wordStar => 'bintang';

  @override
  String get wordHouse => 'rumoh';

  @override
  String get wordCar => 'moto';

  @override
  String get wordTree => 'bak kayèe';

  @override
  String get wordBall => 'bola';

  @override
  String get wordFlower => 'bungong';

  @override
  String get wordBoat => 'peurahô';

  @override
  String get wordBird => 'cicém';

  @override
  String get wordCake => 'kuéh';

  @override
  String get colorRed => 'mirah';

  @override
  String get colorBlue => 'biru';

  @override
  String get colorGreen => 'ijô';

  @override
  String get colorYellow => 'kunèng';

  @override
  String wordsWithColor(String color, String object) {
    return '$object $color';
  }

  @override
  String get startingIsland => 'Planet phôn';

  @override
  String get retakePretest => 'Meu\'en peumanaih lom';

  @override
  String placementNowAt(String island) {
    return 'Jinoe di: $island';
  }

  @override
  String get placementNotYet => 'Goh lom meu\'en peumanaih';

  @override
  String get setByParent => 'geuatô lé ureueng tuha';

  @override
  String get cheerCelebrate1 => 'Hebat!';

  @override
  String get cheerCelebrate2 => 'Get that!';

  @override
  String get cheerCelebrate3 => 'Kah ka jeuet!';

  @override
  String get cheerCelebrate4 => 'Super!';

  @override
  String get cheerCelebrate5 => 'Wah, get that!';

  @override
  String get cheerCelebrate6 => 'Luar biasa!';

  @override
  String get cheerEncourage1 => 'Pikiran nyang get!';

  @override
  String get cheerEncourage2 => 'Usaha nyang get!';

  @override
  String get cheerEncourage3 => 'Jak tajak laju!';

  @override
  String get cheerEncourage4 => 'Teurimong gaséh ka kacuba!';

  @override
  String get cheerEncourage5 => 'Kah hebat!';

  @override
  String get donateExplainer =>
      'Coba Lagi gratis. Donasi padum mantong jeuet geupeuhah fitur sponsor keu keluarga droeneuh ngon geubantu kamoe peugöt leubèh le petualangan.';

  @override
  String get donateUnavailable => 'Donasi hana bak perangkat nyoe.';

  @override
  String get restoreDonation => 'Peuriwang donasi nyang ilèe';

  @override
  String get tipExplainer =>
      'Coba Lagi gratis. Tip padum mantong jeuet geupeuhah fitur sponsor keu keluarga droeneuh ngon geubantu kamoe peugöt leubèh le petualangan.';

  @override
  String get tipsUnavailable => 'Tip hana bak perangkat nyoe.';

  @override
  String get restorePurchases => 'Peuriwang peublòe';

  @override
  String get haveUnlockCode => 'Na kode?';

  @override
  String get buyUnlockCode => 'Bloe kode';

  @override
  String get buyUnlockCodeExplainer =>
      'Bloe kode bak situs kamoe. Kode geukirém lewat email; laju peutamong lewat \"Na kode?\".';

  @override
  String get unlockCode => 'Kode';

  @override
  String get useUnlockCode => 'Pakè kode';

  @override
  String get unlockCodeRejected =>
      'Kode nyan hana beulaku. Neuparéksa lom, lheuh nyan neucuba sigo treuk.';

  @override
  String get unlockCodeGithubOnly =>
      'Kode nyoe keu aplikasi nibak GitHub. Bak aplikasi nyoe, bantuan meulalui toko aplikasi.';

  @override
  String get thanksForSupport => 'Teurimong gaséh ka neudukông Coba Lagi!';

  @override
  String get playGoal => 'Bantu lôn trôk u bandéra!';

  @override
  String get playGoalStars => 'Kumpôi mandum bintang, lheuh nyan u bandéra!';

  @override
  String get playGoalLoops => 'Pakè blok ulang keu trôk u bandéra!';

  @override
  String get playGoalFunctions =>
      'Pasoe blok bintang, lheuh nyan pakè beule go keu trôk u bandéra!';

  @override
  String get playHowTo => 'Tarék blok u kotak putéh, lheuh nyan teukan Jak!';

  @override
  String get backToIsland => 'Woe u planet';

  @override
  String get continueAdventure => 'Lanjut petualangan';

  @override
  String levelNumber(int number) {
    return 'Level $number';
  }

  @override
  String get levelLocked => 'Goh lom teuhah';

  @override
  String get answerWas => 'Jaweuban jih nyang nyoe!';

  @override
  String get conceptConditions => 'Kalon u keue';

  @override
  String get blockUntilGoal => 'Ulang trôk u bandéra';

  @override
  String get blockIfPathClear => 'Meunyo soh';

  @override
  String get playGoalConditions =>
      'Kalon u keue! Boh blok u keue lam blok mata. Jih jak u keue meunyo jalan di keue soh mantong. Blok kah beu jeuet bak tiep-tiep peta!';

  @override
  String get updateAvailableTitle => 'Na versi barô';

  @override
  String get updateAvailableBody =>
      'Versi barô Coba Lagi ka na. Lakèe bantu bak ureueng tuha keu peubarô aplikasi.';

  @override
  String get updateWithParent => 'Lakèe bantu keu peubarô';

  @override
  String get updateContinue => 'Lanjut meu\'en';

  @override
  String get updateOpenFailed =>
      'Peubarô goh lom jeuet teuhah. Cuba lom atawa lanjut meu\'en.';

  @override
  String get codeTab => 'Tab Kode';

  @override
  String get codeTabHint =>
      'Aneuk jeuet jiketik kode seulaén pakè blok gamba. Meu\'en peumanaih geupeuudép keu aneuk nyang ka jeuet jibeuet.';

  @override
  String get editorBlocks => 'Blok';

  @override
  String get editorCode => 'Kode';

  @override
  String get codeDrafts =>
      'Tiep-tiep editor jikeubah draf droe. Draf kode phôn teuka nibak blok kah.';

  @override
  String get codeHelp => 'Panduan kode';

  @override
  String get codeSource => 'Kode kah';

  @override
  String get codeGuide =>
      'Teukan peurintah keu tamah, atawa ketik keudroe. Nan peurintah teutap sama bak bahsa pat mantong. Akhé aksi ngon (); ngon boh isi ulang ngon pareksa antara kurông kurawai buka ngon tutôp. Jumlah ulang 1–9. Peugöt Blok Ajaib ngon define star, lheuh nyan jalankan ngon star();. // phôn komentar. Tiep peurintah teuhitông sa blok, meuhat peurintah lam kurông kurawai. Keubah angka ngon steps = 3; ngon pakè move(steps); keu jak u keue sabe le nyan. Angka teutap sama trôk kah keubah nyang barô. Keubah dilèe sigohlom pakè. until_flag jiulang isi kurông kurawai jih trôk robot trôk u bandéra, hana peureulèe bileung.';

  @override
  String get codeSyntax =>
      'Pareksa nan peurintah, kurông, kurông kurawai, ngon titék koma.';

  @override
  String get codeNumber => 'Piléh angka nibak 1 trôk 9.';

  @override
  String get codeDuplicateStar => 'Pakè saboh bagian define star mantong.';

  @override
  String get codeNestedStar => 'Boh define star di luwa ulang ngon pareksa.';

  @override
  String get codeTooLarge =>
      'Cuba program nyang leubèh paneuk ngon leubèh bacut bagian meutingkat.';

  @override
  String get codeDisallowed => 'Pakè peurintah nyang na keu teka-teki nyoe.';

  @override
  String get codeLimit => 'Cuba kurang peurintah mangat pah ngon bateue blok.';

  @override
  String get codeEmptyBody => 'Tamah peurintah lam kurông kurawai.';

  @override
  String get codeEmptyStar =>
      'Tamah peurintah u define star sigohlom pakè star();.';

  @override
  String get codeRecursiveStar =>
      'Pakè langkah, beulôk, ulang, atawa pareksa lam define star.';

  @override
  String get codeReady => 'Ka siap keu jalan';

  @override
  String get codeStart => 'Tamah peurintah keu phôn.';

  @override
  String codeLine(int line, String message) {
    return 'Baréh $line: $message';
  }

  @override
  String codeRunningLine(int line) {
    return 'Teungoh jalan baréh $line';
  }

  @override
  String get codeDefineStar => 'Peugöt blok lôn';

  @override
  String get conceptUntil => 'Trôk u bandéra';

  @override
  String get playGoalUntil =>
      'Pakè blok ulang trôk u bandéra: blok nyan jak laju keudroe, jadi kah hana peureulèe bileung!';

  @override
  String get conceptDebugging => 'Peugöt!';

  @override
  String get playGoalDebugging =>
      'Ups, blok nyoe goh lom pah! Teukan Jak, kalon peue nyang teujadi, lheuh nyan peugöt.';

  @override
  String get conceptVariables => 'Kotak Langkah';

  @override
  String get blockSetSteps => 'Keubah langkah';

  @override
  String get blockMoveSteps => 'Pakè langkah';

  @override
  String get stepsFewer => 'Keubah angka nyang leubèh ubit';

  @override
  String get stepsMore => 'Keubah angka nyang leubèh rayek';

  @override
  String get playGoalVariables =>
      'Keubah angka lam Kotak Langkah kah, lheuh nyan pakè keu jak u keue sabe le nyan! Angka jih jeuet pakè lom atawa gantoe. Trôk u bandéra ngon kumpôi mandum bintang.';

  @override
  String stepBoxValue(String value) {
    return 'Kotak Langkah: $value';
  }

  @override
  String get codeUnsetSteps =>
      'Keubah angka ngon steps = 2; sigohlom pakè move(steps);.';

  @override
  String get variableHint =>
      'Keubah angka dilèe, lheuh nyan pakè kotak keu jak u keue. Angka teutap sama trôk kah gantoe.';

  @override
  String get tutorialTitle => 'Kalon lôn!';

  @override
  String get tutorialWatchAgain => 'Kalon lom';

  @override
  String get tutorialLetsPlay => 'Jak tameu\'en!';

  @override
  String get tutorialSkip => 'Liwat';

  @override
  String get storyTitle => 'Kapai bintang Koba';

  @override
  String get storyShelfIntro => 'Phôn hikayat';

  @override
  String get storyShelfNewPlanet => 'Planet barô';

  @override
  String get storyShelfEnding => 'Tangki jih ka peunoh!';

  @override
  String get storyShelfFullAgain => 'Tangki jih peunoh lom';

  @override
  String get storyIntroFly =>
      'Nyoe kapai bintang Koba. Kapai nyoe theureubang ngon bintang!';

  @override
  String get storyIntroWind =>
      'Wuusss! Angèn angkasa jipeu-ayôn bintang nibak tangki jih, u mandum planet.';

  @override
  String get storyIntroLand => 'Bintang jih ka habéh, jadi kapai jih beutrôn.';

  @override
  String get storyIntroBump => 'Ups, na batèe! Hana peue. Lôn cuba lom!';

  @override
  String get storyIntroHelp =>
      'Jak tamita bintang jih sajan-sajan. Keuneuk kah bantu lôn, Komandan?';

  @override
  String get storyFly =>
      'Tangki lôn ka meutamah bintang! Jak u planet nyang lheuh nyoe!';

  @override
  String get storyArrivalDirections =>
      'Kapai jih trôn bak planet nyang peunoh papan peutunjôk. Arah jih u pat-pat mantong!';

  @override
  String get storyArrivalDirectionsKoba =>
      'Lôn beujak u pat? Peuleumah ngon panah: u keue, u wie, atawa u uneun!';

  @override
  String get storyArrivalSequencing =>
      'Di sinoe, bintang jih na sapanjang jalan nyang meubeulôk-beulôk.';

  @override
  String get storyArrivalSequencingKoba =>
      'Lôn peureulèe mandum langkah jih meuurôt, sa-sa!';

  @override
  String get storyArrivalLoops =>
      'Bak planet nyoe, jalan jih u keue, beulôk, u keue, beulôk, meu-ulang-ulang.';

  @override
  String get storyArrivalLoopsKoba =>
      'Le that langkah jih! Na jalan pintaih, hana?';

  @override
  String get storyArrivalFunctions =>
      'Koba jiteumèe blok ajaib nyang meukilat bak tanoh.';

  @override
  String get storyArrivalFunctionsKoba =>
      'Blok nyoe jeuet jiingat gerakan lôn! Peurunoe sigo, lheuh nyan pakè beule go.';

  @override
  String get storyArrivalConditions =>
      'Kabôt teubai jitôp planet nyoe. Koba hana jeuet jikalon jalan jih!';

  @override
  String get storyArrivalConditionsKoba =>
      'Lôn peuudép lampu lôn ngon lôn kalon u keue sigohlom lôn melangkah.';

  @override
  String get storyArrivalVariables =>
      'Bak planet nyoe, Koba jiteumèe kotak ubit ngon angka.';

  @override
  String get storyArrivalVariablesKoba =>
      'Kotak nyoe jiingat angka! Angka jih jipeugah padum langkah lôn jak.';

  @override
  String get storyArrivalDebugging =>
      'Na nyang jitinggai blok bak jalan, mandum jih ka meutuka.';

  @override
  String get storyArrivalDebuggingKoba =>
      'Blok nyoe goh lom pah. Jak tamita nyang peureulèe peugöt!';

  @override
  String get storyArrivalUntil =>
      'Jeuôh, jeuôh that, na bandéra bak ujông jalan nyang panyang.';

  @override
  String get storyArrivalUntilKoba =>
      'Langkah jih le that keu bileung! Lôn jak laju mantong trôk u bandéra.';

  @override
  String get storyArrivalOtherwise =>
      'Jalan jih meucabang dua. Bak saboh jalan na semak!';

  @override
  String get storyArrivalOtherwiseKoba =>
      'Meunyo jalan jih soh, lôn jak u keue. Meunyo hana, lôn beulôk!';

  @override
  String get storyEnding =>
      'Bintang akhé ka theureubang woe. Tangki Koba ka peunoh!';

  @override
  String get storyEndingKoba =>
      'Teurimong gaséh, Komandan! Kah ka kabantu lôn meuteumèe mandum bintang.';

  @override
  String get storyEndingMore =>
      'Jinoe tanyoe jeuet theureubang u pat mantong. Jak tameu\'en laju sajan-sajan!';

  @override
  String get storyFullAgain => 'Bintang-bintang theureubang woe u tangki.';

  @override
  String get storyNewPlanet =>
      'Wuusss! Angèn angkasa jipeu-ayôn padum boh bintang nibak tangki, u planet nyang goh lom meuteumèe.';

  @override
  String get storyNewPlanetKoba =>
      'Planet barô! Keuneuk kah bantu lôn mita bintang lom, Komandan?';

  @override
  String get storyThanksDirections =>
      'Peunoh lom! Teurimong gaséh ka kapeurunoe lôn wie ngon uneun, Komandan!';

  @override
  String get storyThanksSequencing =>
      'Peunoh lom! Teurimong gaséh ka kapeurunoe lôn langkah meuurôt, Komandan!';

  @override
  String get storyThanksLoops =>
      'Peunoh lom! Teurimong gaséh ka kapeurunoe lôn meu-ulang, Komandan!';

  @override
  String get storyThanksFunctions =>
      'Peunoh lom! Teurimong gaséh ka kapeurunoe lôn Blok Ajaib, Komandan!';

  @override
  String get storyThanksConditions =>
      'Peunoh lom! Teurimong gaséh ka kapeurunoe lôn kalon u keue, Komandan!';

  @override
  String get storyThanksVariables =>
      'Peunoh lom! Teurimong gaséh ka kapeurunoe lôn Kotak Langkah, Komandan!';

  @override
  String get storyThanksDebugging =>
      'Peunoh lom! Teurimong gaséh ka kapeurunoe lôn peugöt blok, Komandan!';

  @override
  String get storyThanksUntil =>
      'Peunoh lom! Teurimong gaséh ka kapeurunoe lôn jak trôk u bandéra, Komandan!';

  @override
  String get storyThanksOtherwise =>
      'Peunoh lom! Teurimong gaséh ka kapeurunoe lôn peue nyang lôn peugöt meunyo hana, Komandan!';

  @override
  String get watchHow => 'Kalon cara jih';

  @override
  String get tutorialDirections =>
      'Teukan blok panah keu peugah bak lôn u pat lôn beujak: u keue, beulôk u wie, beulôk u uneun. Lheuh nyan teukan Jak!';

  @override
  String get tutorialSequencing =>
      'Susôn langkah jih meuurôt, sa-sa, trôk u bandéra.';

  @override
  String get tutorialLoops =>
      'Langkah jih sama laju? Peutamong u blok ulang, lheuh nyan piléh padum go!';

  @override
  String get tutorialFunctions =>
      'Peugöt blok ajaib kah keudroe bak baréh bintang. Lheuh nyan pakè bintang jih beule go!';

  @override
  String get tutorialConditions =>
      'Blok mata jikalon u keue. Meunyo jalan jih soh, lôn jak u keue. Meunyo hana, lôn preh. Jadi blok nyang sama jeuet bak tiep-tiep peta!';

  @override
  String get tutorialVariables =>
      'Keubah angka lam Kotak Langkah. Lheuh nyan pakè langkah keu jak sabe le nyan!';

  @override
  String get tutorialDebugging =>
      'Blok nyoe goh lom pah. Teukan Jak ngon kalon beugot. Lheuh nyan teukan blok nyang peureulèe peugöt, ngon teukan blok nyang beutôi!';

  @override
  String get tutorialUntil =>
      'Ulang trôk u bandéra jijak laju keudroe, jadi kah hana peureulèe bileung!';

  @override
  String get hintPattern =>
      'Blok-blok nyoe jiteuka lom ngon lom. Cuba pakè blok ulang!';

  @override
  String get hintAgain => 'Teukan lampu lom keu kalon blok nyang meu-ulang!';

  @override
  String get hintLookHere =>
      'Kalon blok nyang na lampu. Cuba gantoe blok nyan!';

  @override
  String get hintLookHereMany =>
      'Kalon blok-blok nyang na lampu. Cuba gantoe blok-blok nyan!';

  @override
  String get turnMap => 'Puta peta';

  @override
  String boardNumber(int number) {
    return 'Peta $number';
  }

  @override
  String get tourPalette =>
      'Nyoe blok-blok kah. Teukan saboh, atawa tarék u program kah.';

  @override
  String get tourProgram =>
      'Program kah na di sinoe. Lôn jalankan blok jih meuurôt, nibak nyang phôn. Teukan blok keu gantoe.';

  @override
  String get tourGo => 'Teukan Jak, ngon lôn ikôt blok-blok kah!';

  @override
  String get tourStep =>
      'Tumbôi nyoe jijalankan saboh blok tiep go, jadi kah jeuet kakalon beugot.';

  @override
  String get tourReset => 'Nyang nyoe jiba lôn woe u phôn.';

  @override
  String get tourHint =>
      'Bingông? Lheuh padum go cuba, lampu jiudép. Tiep go teukan jipeuleumah bacut treuk: phôn jalan jih, lheuh nyan blok pat nyang peureulèe gantoe. Tanda ubit bak lampu jipeuleumah peue nyang lheuh nyoe.';

  @override
  String get tourFollow =>
      'Nyoe jiputa peta seuperpeuet putaran tiep go, jadi kah jeuet kakalon nibak sisi lôn.';

  @override
  String get tourBoards =>
      'Di sinoe na padum boh peta. Teukan titék keu kalon tiep peta. Blok kah beujiba lôn trôk u bandéra bak tiep-tiep peta!';

  @override
  String get tourListen =>
      'Teukan speaker keu deungo lom peue nyang beukapeugöt.';

  @override
  String get tourWarmUpListen =>
      'Deungo pertanyaan jih. Teukan speaker keu deungo lom.';

  @override
  String get tourWarmUpAnswer =>
      'Lheuh nyan teukan gamba nyang kah pikée beutôi!';

  @override
  String get tourWarmUpSteps =>
      'Bekaih gaki jipeuleumah padum jeuôh kah ka meu\'en.';

  @override
  String get tourBlockForward => 'Panah ijô jipeujak lôn u keue sa langkah.';

  @override
  String get tourBlockTurnLeft =>
      'Panah biru jipeubeulôk lôn u wie, hana meupinah.';

  @override
  String get tourBlockTurnRight =>
      'Panah oranye jipeubeulôk lôn u uneun, hana meupinah.';

  @override
  String get tourBlockRepeat =>
      'Blok ulang jijalankan blok lam jih meu-ulang go. Teukan kurang atawa tamah keu piléh padum go.';

  @override
  String get tourBlockSetSteps =>
      'Kotak Langkah jikeubah jumlah langkah. Teukan kurang atawa tamah keu gantoe.';

  @override
  String get tourBlockMoveSteps =>
      'Panah nyoe jipeujak lôn u keue sabe le angka lam Kotak Langkah.';

  @override
  String get tourBlockIfPathClear =>
      'Blok mata jikalon u keue. Blok lam jih jijak meunyo jalan jih soh mantong.';

  @override
  String get tourBlockIfElse =>
      'Blok mata nyoe na dua baréh: baréh ateuh jijak meunyo jalan jih soh, baréh yup meunyo hana.';

  @override
  String get tourBlockUntilGoal =>
      'Ulang trôk u bandéra jijalankan blok lam jih laju-laju, trôk lôn trôk u bandéra.';

  @override
  String get tourBlockStar =>
      'Blok bintang jijalankan blok bak baréh bintang kah: blok ajaib peugöt kah keudroe.';

  @override
  String get tourNext => 'Lanjut';

  @override
  String get tourDone => 'Ka meuphôm!';

  @override
  String get tourHelp => 'Pakriban cara jih?';

  @override
  String get breakTitle => 'Watèe meupiôh!';

  @override
  String get breakBody =>
      'Kah ka meu\'en ngon hebat. Peupiôh mata kah, cuba meuregang, lheuh nyan meu\'en lom teuma.';

  @override
  String get breakHome => 'Woe u ureueng meu\'en';

  @override
  String get breakContinue => 'Ureueng tuha jeuet geulanjut';

  @override
  String get breakVoice =>
      'Watèe meupiôh! Kah ka meu\'en ngon hebat. Peupiôh mata kah, cuba meuregang, lheuh nyan meu\'en lom teuma.';

  @override
  String get breakReminder => 'Peuingat meupiôh';

  @override
  String get breakReminderHint =>
      'Lheuh meu\'en teka-teki sabe treb nyoe, aneuk geujak meupiôh. Ureueng tuha mantong nyang jeuet geulanjut.';

  @override
  String get breakOff => 'Mate';

  @override
  String breakMinutes(int minutes) {
    return '$minutes mnt';
  }

  @override
  String nextIslandSoon(int count, String island) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count teka-teki treuk jeuet jiba kah u $island!',
      one: 'Teka-teki nyang lheuh nyoe jeuet jiba kah u $island!',
    );
    return '$_temp0';
  }

  @override
  String get conceptWarmUp => 'Peumanaih';

  @override
  String get warmUpCounting => 'Bileung';

  @override
  String get warmUpColors => 'Warna';

  @override
  String get warmUpShapes => 'Bentuk';

  @override
  String get warmUpPatterns => 'Pola';

  @override
  String get warmUpSides => 'Wie ngon uneun';

  @override
  String get warmUpSteps => 'Langkah';

  @override
  String get warmUpReading => 'Beuet';

  @override
  String get warmUpPick => 'Piléh meu\'en!';

  @override
  String get warmUpDone => 'Hebat that meu\'en kah! Meu\'en lom?';

  @override
  String get playAgain => 'Meu\'en lom';

  @override
  String get promptColorRed => 'Teukan nyang mirah!';

  @override
  String get promptColorBlue => 'Teukan nyang biru!';

  @override
  String get promptColorGreen => 'Teukan nyang ijô!';

  @override
  String get promptColorYellow => 'Teukan nyang kunèng!';

  @override
  String get promptShapeCircle => 'Teukan lingkaran!';

  @override
  String get promptShapeSquare => 'Teukan persegi!';

  @override
  String get promptShapeTriangle => 'Teukan segitiga!';

  @override
  String get promptShapeHeart => 'Teukan até!';

  @override
  String playLevel(int number) {
    return 'Meu\'en level $number';
  }

  @override
  String get stickerBook => 'Kitab stiker';

  @override
  String get stickerBookHello => 'Kalon mandum stiker kah!';

  @override
  String get stickersIslands => 'Planet';

  @override
  String get stickerNotYet => 'Goh lom meuteumèe';

  @override
  String get stickerGold => 'Mandum bintang ka meukumpôi!';

  @override
  String get blockIfElse => 'Meunyo soh, meunyo hana';

  @override
  String get otherwiseRowClear => 'Meunyo jalan jih soh';

  @override
  String get otherwiseRowBlocked => 'Meunyo hana';

  @override
  String get conceptOtherwise => 'Meunyo hana';

  @override
  String get playGoalOtherwise =>
      'Pakè blok mata ngon dua baréh: meunyo jalan jih soh, jak sa langkah. Meunyo hana, beulôk!';

  @override
  String get tutorialOtherwise =>
      'Mata jikalon u keue. Meunyo jalan jih soh, jak sa langkah. Meunyo hana, beulôk. Lheuh nyan mandum jih meu-ulang trôk u bandéra!';

  @override
  String starsEarned(int count) {
    return '$count nibak 3 bintang';
  }
}
