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
  String get addPlayer => 'Ureueng meu\'en baro';

  @override
  String get nickname => 'Nan panggilan';

  @override
  String get chooseAvatar => 'Pileh gamba';

  @override
  String get save => 'Keubah';

  @override
  String get cancel => 'Batai';

  @override
  String get delete => 'Hapoh';

  @override
  String get ok => 'Nyo';

  @override
  String greeting(String name) {
    return 'Hai, $name!';
  }

  @override
  String get play => 'Meu\'en';

  @override
  String get askAGrownUp => 'Lakee bantu bak ureueng tuha';

  @override
  String parentGateQuestion(int a, int b) {
    return 'Padum $a × $b?';
  }

  @override
  String get parentGateWrong => 'Goh lom beutoi. Cuba lom.';

  @override
  String get parentArea => 'Teumpat ureueng tuha';

  @override
  String get language => 'Bahsa';

  @override
  String get languageSystem => 'Ikot perangkat';

  @override
  String get plan => 'Versi';

  @override
  String get planFree => 'Biasa: 1 ureueng meu\'en';

  @override
  String planFull(int count) {
    return 'Sponsor: trok $count ureueng meu\'en';
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
  String get changeStartingIsland => 'Gantoe planet phon';

  @override
  String get progressThisWeek => '7 uroe nyang ka lheueh';

  @override
  String get progressAllTime => 'Yoh phon';

  @override
  String progressPuzzles(int count) {
    return '$count teka-teki ka lheueh';
  }

  @override
  String progressMinutes(int count) {
    return '$count meunet meu\'en';
  }

  @override
  String progressLastPlayed(String date) {
    return 'Akhe meu\'en: $date';
  }

  @override
  String get progressNotPlayed => 'Goh lom lheueh teka-teki';

  @override
  String get progressIslands => 'Planet';

  @override
  String get statusNotStarted => 'Goh lom phon';

  @override
  String get statusPractising => 'Teungoh meulateh';

  @override
  String get statusMastered => 'Ka meuphom';

  @override
  String progressLevels(int solved, int total) {
    return '$solved nibak $total level ka lheueh';
  }

  @override
  String get progressSponsorOnly =>
      'Sponsor jeuet geukalon laporan kemajuan nyang leungkap: teka-teki nyang ka lheueh, watee meu\'en, ngon kemajuan bak tiep-tiep planet.';

  @override
  String get music => 'Musik';

  @override
  String get soundEffects => 'Su efek';

  @override
  String get hintArrowsFollowRoad => 'Panah peutunjok ikot jalan';

  @override
  String get hintArrowsFollowRoadHint =>
      'Mate: panah ngadap u ateuh, lagee bak blok.';

  @override
  String get soundEffectsHint => 'Su peutunjok teutap meudeungo.';

  @override
  String get supportCobaLagi => 'Dukong Coba Lagi';

  @override
  String get debugPlanOverride => 'Debug: pake versi leungkap';

  @override
  String get players => 'Ureueng meu\'en';

  @override
  String deletePlayerConfirm(String name) {
    return 'Hapoh $name ngon mandum kemajuan jih?';
  }

  @override
  String get playerLimitReached =>
      'Versi nyoe keu sidroe ureueng meu\'en mantong. Lakee bantu bak ureueng tuha.';

  @override
  String get run => 'Jak!';

  @override
  String get step => 'Sa langkah';

  @override
  String get reset => 'Phon lom';

  @override
  String get undo => 'Peuriwang';

  @override
  String get redo => 'Peubalek';

  @override
  String get clearBlocks => 'Hapoh mandum blok';

  @override
  String get removeBlock => 'Hapoh blok nyoe';

  @override
  String get blockForward => 'U keue';

  @override
  String get blockTurnLeft => 'Beulok u wie';

  @override
  String get blockTurnRight => 'Beulok u uneun';

  @override
  String get blockRepeat => 'Ulang';

  @override
  String get blockStar => 'Blok peugot lon';

  @override
  String get toMap => 'U peta';

  @override
  String get tryAgain => 'Cuba lom!';

  @override
  String get feedbackBumped => 'Ups, na nyang theun.';

  @override
  String get feedbackStoppedShort => 'Ka toe! Jak laju trok u bandera.';

  @override
  String get feedbackOtherBoard =>
      'Peta nyan ka jadeh! Peta nyoe laen, jadi kalon u keue sigohlom tiep langkah.';

  @override
  String get feedbackMissedStars => 'Kumpoi mandum bintang dilee.';

  @override
  String get feedbackTooManySteps =>
      'Langkah jih le that! Cuba nyang leubeh bacut.';

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
  String get decisionAdvance => 'Planet baro ka teuhah!';

  @override
  String get decisionPractice => 'Jak tacuba nyang laen!';

  @override
  String get bonusAdventure => 'Petualangan bonus!';

  @override
  String get decisionReview => 'Jak tamita harta karon bak planet nyang ilee.';

  @override
  String get decisionReturn => 'Woe u petualangan kah!';

  @override
  String get decisionMapComplete => 'Kah ka kajeulajah mandum planet!';

  @override
  String get hint => 'Peuleumah jalan jih';

  @override
  String get hintNextPattern => 'Peuleumah blok nyang meu-ulang';

  @override
  String get hintNextRing => 'Peuleumah blok nyang peureulee gantoe';

  @override
  String get repeatMore => 'Tamah sigo';

  @override
  String get repeatFewer => 'Kurang sigo';

  @override
  String get dropBlocksHere => 'Boh blok keunoe';

  @override
  String get pretestWelcome => 'Hai, lon Koba! Jak tameu\'en peumanaih dilee!';

  @override
  String get pretestStart => 'Phon';

  @override
  String get listenAgain => 'Deungo lom';

  @override
  String get promptReading => 'Gamba pat nyang pah ngon tuleh nyoe?';

  @override
  String get promptCounting => 'Padum boh?';

  @override
  String get promptSideLeft => 'Teukan nyang di wie.';

  @override
  String get promptSideRight => 'Teukan nyang di uneun.';

  @override
  String get promptTurnLeft => 'Panah beulok u wie. Jinoe jih tunjok u pat?';

  @override
  String get promptTurnRight => 'Panah beulok u uneun. Jinoe jih tunjok u pat?';

  @override
  String get promptPattern => 'Peue nyang lheuh nyoe?';

  @override
  String get promptSequencing => 'Langkah pat nyang trok u bandera?';

  @override
  String get pretestDone => 'Ka lheueh! Petualangan kah phon jinoe.';

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
  String get wordTree => 'bak kayee';

  @override
  String get wordBall => 'bola';

  @override
  String get wordFlower => 'bungong';

  @override
  String get wordBoat => 'peuraho';

  @override
  String get wordBird => 'cicem';

  @override
  String get wordCake => 'kueh';

  @override
  String get colorRed => 'mirah';

  @override
  String get colorBlue => 'biru';

  @override
  String get colorGreen => 'ijo';

  @override
  String get colorYellow => 'kuneng';

  @override
  String wordsWithColor(String color, String object) {
    return '$object $color';
  }

  @override
  String get startingIsland => 'Planet phon';

  @override
  String get retakePretest => 'Meu\'en peumanaih lom';

  @override
  String placementNowAt(String island) {
    return 'Jinoe di: $island';
  }

  @override
  String get placementNotYet => 'Goh lom meu\'en peumanaih';

  @override
  String get setByParent => 'geuato le ureueng tuha';

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
  String get cheerEncourage4 => 'Teurimong gaseh ka kacuba!';

  @override
  String get cheerEncourage5 => 'Kah hebat!';

  @override
  String get donateExplainer =>
      'Coba Lagi gratis. Donasi padum mantong jeuet geupeuhah fitur sponsor keu keluarga droeneuh ngon geubantu kamoe peugot leubeh le petualangan.';

  @override
  String get donateUnavailable => 'Donasi hana bak perangkat nyoe.';

  @override
  String get restoreDonation => 'Peuriwang donasi nyang ilee';

  @override
  String get tipExplainer =>
      'Coba Lagi gratis. Tip padum mantong jeuet geupeuhah fitur sponsor keu keluarga droeneuh ngon geubantu kamoe peugot leubeh le petualangan.';

  @override
  String get tipsUnavailable => 'Tip hana bak perangkat nyoe.';

  @override
  String get restorePurchases => 'Peuriwang peubloe';

  @override
  String get haveUnlockCode => 'Na kode?';

  @override
  String get buyUnlockCode => 'Bloe kode';

  @override
  String get buyUnlockCodeExplainer =>
      'Bloe kode bak situs kamoe. Kode geukirem lewat email; laju peutamong lewat \"Na kode?\".';

  @override
  String get unlockCode => 'Kode';

  @override
  String get useUnlockCode => 'Pake kode';

  @override
  String get unlockCodeRejected =>
      'Kode nyan hana beulaku. Neupareksa lom, lheuh nyan neucuba sigo treuk.';

  @override
  String get unlockCodeGithubOnly =>
      'Kode nyoe keu aplikasi nibak GitHub. Bak aplikasi nyoe, bantuan meulalui toko aplikasi.';

  @override
  String get thanksForSupport => 'Teurimong gaseh ka neudukong Coba Lagi!';

  @override
  String get playGoal => 'Bantu lon trok u bandera!';

  @override
  String get playGoalStars => 'Kumpoi mandum bintang, lheuh nyan u bandera!';

  @override
  String get playGoalLoops => 'Pake blok ulang keu trok u bandera!';

  @override
  String get playGoalFunctions =>
      'Pasoe blok bintang, lheuh nyan pake beule go keu trok u bandera!';

  @override
  String get playHowTo => 'Tarek blok u kotak puteh, lheuh nyan teukan Jak!';

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
  String get blockUntilGoal => 'Ulang trok u bandera';

  @override
  String get blockIfPathClear => 'Meunyo soh';

  @override
  String get playGoalConditions =>
      'Kalon u keue! Boh blok u keue lam blok mata. Jih jak u keue meunyo jalan di keue soh mantong. Blok kah beu jeuet bak tiep-tiep peta!';

  @override
  String get updateAvailableTitle => 'Na versi baro';

  @override
  String get updateAvailableBody =>
      'Versi baro Coba Lagi ka na. Lakee bantu bak ureueng tuha keu peubaro aplikasi.';

  @override
  String get updateWithParent => 'Lakee bantu keu peubaro';

  @override
  String get updateContinue => 'Lanjut meu\'en';

  @override
  String get updateOpenFailed =>
      'Peubaro goh lom jeuet teuhah. Cuba lom atawa lanjut meu\'en.';

  @override
  String get codeTab => 'Tab Kode';

  @override
  String get codeTabHint =>
      'Aneuk jeuet jiketik kode seulaen pake blok gamba. Meu\'en peumanaih geupeuudep keu aneuk nyang ka jeuet jibeuet.';

  @override
  String get editorBlocks => 'Blok';

  @override
  String get editorCode => 'Kode';

  @override
  String get codeDrafts =>
      'Tiep-tiep editor jikeubah draf droe. Draf kode phon teuka nibak blok kah.';

  @override
  String get codeHelp => 'Panduan kode';

  @override
  String get codeSource => 'Kode kah';

  @override
  String get codeGuide =>
      'Teukan peurintah keu tamah, atawa ketik keudroe. Nan peurintah teutap sama bak bahsa pat mantong. Akhe aksi ngon (); ngon boh isi ulang ngon pareksa antara kurong kurawai buka ngon tutop. Jumlah ulang 1–9. Peugot Blok Ajaib ngon define star, lheuh nyan jalankan ngon star();. // phon komentar. Tiep peurintah teuhitong sa blok, meuhat peurintah lam kurong kurawai. Keubah angka ngon steps = 3; ngon pake move(steps); keu jak u keue sabe le nyan. Angka teutap sama trok kah keubah nyang baro. Keubah dilee sigohlom pake. until_flag jiulang isi kurong kurawai jih trok robot trok u bandera, hana peureulee bileung.';

  @override
  String get codeSyntax =>
      'Pareksa nan peurintah, kurong, kurong kurawai, ngon titek koma.';

  @override
  String get codeNumber => 'Pileh angka nibak 1 trok 9.';

  @override
  String get codeDuplicateStar => 'Pake saboh bagian define star mantong.';

  @override
  String get codeNestedStar => 'Boh define star di luwa ulang ngon pareksa.';

  @override
  String get codeTooLarge =>
      'Cuba program nyang leubeh paneuk ngon leubeh bacut bagian meutingkat.';

  @override
  String get codeDisallowed => 'Pake peurintah nyang na keu teka-teki nyoe.';

  @override
  String get codeLimit => 'Cuba kurang peurintah mangat pah ngon bateue blok.';

  @override
  String get codeEmptyBody => 'Tamah peurintah lam kurong kurawai.';

  @override
  String get codeEmptyStar =>
      'Tamah peurintah u define star sigohlom pake star();.';

  @override
  String get codeRecursiveStar =>
      'Pake langkah, beulok, ulang, atawa pareksa lam define star.';

  @override
  String get codeReady => 'Ka siap keu jalan';

  @override
  String get codeStart => 'Tamah peurintah keu phon.';

  @override
  String codeLine(int line, String message) {
    return 'Bareh $line: $message';
  }

  @override
  String codeRunningLine(int line) {
    return 'Teungoh jalan bareh $line';
  }

  @override
  String get codeDefineStar => 'Peugot blok lon';

  @override
  String get conceptUntil => 'Trok u bandera';

  @override
  String get playGoalUntil =>
      'Pake blok ulang trok u bandera: blok nyan jak laju keudroe, jadi kah hana peureulee bileung!';

  @override
  String get conceptDebugging => 'Peugot!';

  @override
  String get playGoalDebugging =>
      'Ups, blok nyoe goh lom pah! Teukan Jak, kalon peue nyang teujadi, lheuh nyan peugot.';

  @override
  String get conceptVariables => 'Kotak Langkah';

  @override
  String get blockSetSteps => 'Keubah langkah';

  @override
  String get blockMoveSteps => 'Pake langkah';

  @override
  String get stepsFewer => 'Keubah angka nyang leubeh ubit';

  @override
  String get stepsMore => 'Keubah angka nyang leubeh rayek';

  @override
  String get playGoalVariables =>
      'Keubah angka lam Kotak Langkah kah, lheuh nyan pake keu jak u keue sabe le nyan! Angka jih jeuet pake lom atawa gantoe. Trok u bandera ngon kumpoi mandum bintang.';

  @override
  String stepBoxValue(String value) {
    return 'Kotak Langkah: $value';
  }

  @override
  String get codeUnsetSteps =>
      'Keubah angka ngon steps = 2; sigohlom pake move(steps);.';

  @override
  String get variableHint =>
      'Keubah angka dilee, lheuh nyan pake kotak keu jak u keue. Angka teutap sama trok kah gantoe.';

  @override
  String get tutorialTitle => 'Kalon lon!';

  @override
  String get tutorialWatchAgain => 'Kalon lom';

  @override
  String get tutorialLetsPlay => 'Jak tameu\'en!';

  @override
  String get tutorialSkip => 'Liwat';

  @override
  String get storyTitle => 'Kapai bintang Koba';

  @override
  String get storyShelfIntro => 'Phon hikayat';

  @override
  String get storyShelfNewPlanet => 'Planet baro';

  @override
  String get storyShelfEnding => 'Tangki jih ka peunoh!';

  @override
  String get storyShelfFullAgain => 'Tangki jih peunoh lom';

  @override
  String get storyIntroFly =>
      'Nyoe kapai bintang Koba. Kapai nyoe theureubang ngon bintang!';

  @override
  String get storyIntroWind =>
      'Wuusss! Angen angkasa jipeu-ayon bintang nibak tangki jih, u mandum planet.';

  @override
  String get storyIntroLand => 'Bintang jih ka habeh, jadi kapai jih beutron.';

  @override
  String get storyIntroBump => 'Ups, na batee! Hana peue. Lon cuba lom!';

  @override
  String get storyIntroHelp =>
      'Jak tamita bintang jih sajan-sajan. Keuneuk kah bantu lon, Komandan?';

  @override
  String get storyFly =>
      'Tangki lon ka meutamah bintang! Jak u planet nyang lheuh nyoe!';

  @override
  String get storyArrivalDirections =>
      'Kapai jih tron bak planet nyang peunoh papan peutunjok. Arah jih u pat-pat mantong!';

  @override
  String get storyArrivalDirectionsKoba =>
      'Lon beujak u pat? Peuleumah ngon panah: u keue, u wie, atawa u uneun!';

  @override
  String get storyArrivalSequencing =>
      'Di sinoe, bintang jih na sapanjang jalan nyang meubeulok-beulok.';

  @override
  String get storyArrivalSequencingKoba =>
      'Lon peureulee mandum langkah jih meuurot, sa-sa!';

  @override
  String get storyArrivalLoops =>
      'Bak planet nyoe, jalan jih u keue, beulok, u keue, beulok, meu-ulang-ulang.';

  @override
  String get storyArrivalLoopsKoba =>
      'Le that langkah jih! Na jalan pintaih, hana?';

  @override
  String get storyArrivalFunctions =>
      'Koba jiteumee blok ajaib nyang meukilat bak tanoh.';

  @override
  String get storyArrivalFunctionsKoba =>
      'Blok nyoe jeuet jiingat gerakan lon! Peurunoe sigo, lheuh nyan pake beule go.';

  @override
  String get storyArrivalConditions =>
      'Kabot teubai jitop planet nyoe. Koba hana jeuet jikalon jalan jih!';

  @override
  String get storyArrivalConditionsKoba =>
      'Lon peuudep lampu lon ngon lon kalon u keue sigohlom lon melangkah.';

  @override
  String get storyArrivalVariables =>
      'Bak planet nyoe, Koba jiteumee kotak ubit ngon angka.';

  @override
  String get storyArrivalVariablesKoba =>
      'Kotak nyoe jiingat angka! Angka jih jipeugah padum langkah lon jak.';

  @override
  String get storyArrivalDebugging =>
      'Na nyang jitinggai blok bak jalan, mandum jih ka meutuka.';

  @override
  String get storyArrivalDebuggingKoba =>
      'Blok nyoe goh lom pah. Jak tamita nyang peureulee peugot!';

  @override
  String get storyArrivalUntil =>
      'Jeuoh, jeuoh that, na bandera bak ujong jalan nyang panyang.';

  @override
  String get storyArrivalUntilKoba =>
      'Langkah jih le that keu bileung! Lon jak laju mantong trok u bandera.';

  @override
  String get storyArrivalOtherwise =>
      'Jalan jih meucabang dua. Bak saboh jalan na semak!';

  @override
  String get storyArrivalOtherwiseKoba =>
      'Meunyo jalan jih soh, lon jak u keue. Meunyo hana, lon beulok!';

  @override
  String get storyEnding =>
      'Bintang akhe ka theureubang woe. Tangki Koba ka peunoh!';

  @override
  String get storyEndingKoba =>
      'Teurimong gaseh, Komandan! Kah ka kabantu lon meuteumee mandum bintang.';

  @override
  String get storyEndingMore =>
      'Jinoe tanyoe jeuet theureubang u pat mantong. Jak tameu\'en laju sajan-sajan!';

  @override
  String get storyFullAgain => 'Bintang-bintang theureubang woe u tangki.';

  @override
  String get storyNewPlanet =>
      'Wuusss! Angen angkasa jipeu-ayon padum boh bintang nibak tangki, u planet nyang goh lom meuteumee.';

  @override
  String get storyNewPlanetKoba =>
      'Planet baro! Keuneuk kah bantu lon mita bintang lom, Komandan?';

  @override
  String get storyThanksDirections =>
      'Peunoh lom! Teurimong gaseh ka kapeurunoe lon wie ngon uneun, Komandan!';

  @override
  String get storyThanksSequencing =>
      'Peunoh lom! Teurimong gaseh ka kapeurunoe lon langkah meuurot, Komandan!';

  @override
  String get storyThanksLoops =>
      'Peunoh lom! Teurimong gaseh ka kapeurunoe lon meu-ulang, Komandan!';

  @override
  String get storyThanksFunctions =>
      'Peunoh lom! Teurimong gaseh ka kapeurunoe lon Blok Ajaib, Komandan!';

  @override
  String get storyThanksConditions =>
      'Peunoh lom! Teurimong gaseh ka kapeurunoe lon kalon u keue, Komandan!';

  @override
  String get storyThanksVariables =>
      'Peunoh lom! Teurimong gaseh ka kapeurunoe lon Kotak Langkah, Komandan!';

  @override
  String get storyThanksDebugging =>
      'Peunoh lom! Teurimong gaseh ka kapeurunoe lon peugot blok, Komandan!';

  @override
  String get storyThanksUntil =>
      'Peunoh lom! Teurimong gaseh ka kapeurunoe lon jak trok u bandera, Komandan!';

  @override
  String get storyThanksOtherwise =>
      'Peunoh lom! Teurimong gaseh ka kapeurunoe lon peue nyang lon peugot meunyo hana, Komandan!';

  @override
  String get watchHow => 'Kalon cara jih';

  @override
  String get tutorialDirections =>
      'Teukan blok panah keu peugah bak lon u pat lon beujak: u keue, beulok u wie, beulok u uneun. Lheuh nyan teukan Jak!';

  @override
  String get tutorialSequencing =>
      'Suson langkah jih meuurot, sa-sa, trok u bandera.';

  @override
  String get tutorialLoops =>
      'Langkah jih sama laju? Peutamong u blok ulang, lheuh nyan pileh padum go!';

  @override
  String get tutorialFunctions =>
      'Peugot blok ajaib kah keudroe bak bareh bintang. Lheuh nyan pake bintang jih beule go!';

  @override
  String get tutorialConditions =>
      'Blok mata jikalon u keue. Meunyo jalan jih soh, lon jak u keue. Meunyo hana, lon preh. Jadi blok nyang sama jeuet bak tiep-tiep peta!';

  @override
  String get tutorialVariables =>
      'Keubah angka lam Kotak Langkah. Lheuh nyan pake langkah keu jak sabe le nyan!';

  @override
  String get tutorialDebugging =>
      'Blok nyoe goh lom pah. Teukan Jak ngon kalon beugot. Lheuh nyan teukan blok nyang peureulee peugot, ngon teukan blok nyang beutoi!';

  @override
  String get tutorialUntil =>
      'Ulang trok u bandera jijak laju keudroe, jadi kah hana peureulee bileung!';

  @override
  String get hintPattern =>
      'Blok-blok nyoe jiteuka lom ngon lom. Cuba pake blok ulang!';

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
      'Nyoe blok-blok kah. Teukan saboh, atawa tarek u program kah.';

  @override
  String get tourProgram =>
      'Program kah na di sinoe. Lon jalankan blok jih meuurot, nibak nyang phon. Teukan blok keu gantoe.';

  @override
  String get tourGo => 'Teukan Jak, ngon lon ikot blok-blok kah!';

  @override
  String get tourStep =>
      'Tumboi nyoe jijalankan saboh blok tiep go, jadi kah jeuet kakalon beugot.';

  @override
  String get tourReset => 'Nyang nyoe jiba lon woe u phon.';

  @override
  String get tourHint =>
      'Bingong? Lheuh padum go cuba, lampu jiudep. Tiep go teukan jipeuleumah bacut treuk: phon jalan jih, lheuh nyan blok pat nyang peureulee gantoe. Tanda ubit bak lampu jipeuleumah peue nyang lheuh nyoe.';

  @override
  String get tourFollow =>
      'Nyoe jiputa peta seuperpeuet putaran tiep go, jadi kah jeuet kakalon nibak sisi lon.';

  @override
  String get tourBoards =>
      'Di sinoe na padum boh peta. Teukan titek keu kalon tiep peta. Blok kah beujiba lon trok u bandera bak tiep-tiep peta!';

  @override
  String get tourListen =>
      'Teukan speaker keu deungo lom peue nyang beukapeugot.';

  @override
  String get tourWarmUpListen =>
      'Deungo pertanyaan jih. Teukan speaker keu deungo lom.';

  @override
  String get tourWarmUpAnswer =>
      'Lheuh nyan teukan gamba nyang kah pikee beutoi!';

  @override
  String get tourWarmUpSteps =>
      'Bekaih gaki jipeuleumah padum jeuoh kah ka meu\'en.';

  @override
  String get tourBlockForward => 'Panah ijo jipeujak lon u keue sa langkah.';

  @override
  String get tourBlockTurnLeft =>
      'Panah biru jipeubeulok lon u wie, hana meupinah.';

  @override
  String get tourBlockTurnRight =>
      'Panah oranye jipeubeulok lon u uneun, hana meupinah.';

  @override
  String get tourBlockRepeat =>
      'Blok ulang jijalankan blok lam jih meu-ulang go. Teukan kurang atawa tamah keu pileh padum go.';

  @override
  String get tourBlockSetSteps =>
      'Kotak Langkah jikeubah jumlah langkah. Teukan kurang atawa tamah keu gantoe.';

  @override
  String get tourBlockMoveSteps =>
      'Panah nyoe jipeujak lon u keue sabe le angka lam Kotak Langkah.';

  @override
  String get tourBlockIfPathClear =>
      'Blok mata jikalon u keue. Blok lam jih jijak meunyo jalan jih soh mantong.';

  @override
  String get tourBlockIfElse =>
      'Blok mata nyoe na dua bareh: bareh ateuh jijak meunyo jalan jih soh, bareh yup meunyo hana.';

  @override
  String get tourBlockUntilGoal =>
      'Ulang trok u bandera jijalankan blok lam jih laju-laju, trok lon trok u bandera.';

  @override
  String get tourBlockStar =>
      'Blok bintang jijalankan blok bak bareh bintang kah: blok ajaib peugot kah keudroe.';

  @override
  String get tourNext => 'Lanjut';

  @override
  String get tourDone => 'Ka meuphom!';

  @override
  String get tourHelp => 'Pakriban cara jih?';

  @override
  String get breakTitle => 'Watee meupioh!';

  @override
  String get breakBody =>
      'Kah ka meu\'en ngon hebat. Peupioh mata kah, cuba meuregang, lheuh nyan meu\'en lom teuma.';

  @override
  String get breakHome => 'Woe u ureueng meu\'en';

  @override
  String get breakContinue => 'Ureueng tuha jeuet geulanjut';

  @override
  String get breakVoice =>
      'Watee meupioh! Kah ka meu\'en ngon hebat. Peupioh mata kah, cuba meuregang, lheuh nyan meu\'en lom teuma.';

  @override
  String get breakReminder => 'Peuingat meupioh';

  @override
  String get breakReminderHint =>
      'Lheuh meu\'en teka-teki sabe treb nyoe, aneuk geujak meupioh. Ureueng tuha mantong nyang jeuet geulanjut.';

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
  String get warmUpPick => 'Pileh meu\'en!';

  @override
  String get warmUpDone => 'Hebat that meu\'en kah! Meu\'en lom?';

  @override
  String get playAgain => 'Meu\'en lom';

  @override
  String get promptColorRed => 'Teukan nyang mirah!';

  @override
  String get promptColorBlue => 'Teukan nyang biru!';

  @override
  String get promptColorGreen => 'Teukan nyang ijo!';

  @override
  String get promptColorYellow => 'Teukan nyang kuneng!';

  @override
  String get promptShapeCircle => 'Teukan lingkaran!';

  @override
  String get promptShapeSquare => 'Teukan persegi!';

  @override
  String get promptShapeTriangle => 'Teukan segitiga!';

  @override
  String get promptShapeHeart => 'Teukan ate!';

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
  String get stickerNotYet => 'Goh lom meuteumee';

  @override
  String get stickerGold => 'Mandum bintang ka meukumpoi!';

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
      'Pake blok mata ngon dua bareh: meunyo jalan jih soh, jak sa langkah. Meunyo hana, beulok!';

  @override
  String get tutorialOtherwise =>
      'Mata jikalon u keue. Meunyo jalan jih soh, jak sa langkah. Meunyo hana, beulok. Lheuh nyan mandum jih meu-ulang trok u bandera!';

  @override
  String starsEarned(int count) {
    return '$count nibak 3 bintang';
  }

  @override
  String get progressFileTitle => 'Pinah u alat laen';

  @override
  String progressFileHint(String name) {
    return 'Keubah kemajuan $name lam file, lheuh nyan peuhah bak Coba Lagi lam alat laen. Peuhah cit meutamah bak nyang ka na; hana nyang gadoh.';
  }

  @override
  String get saveProgress => 'Keubah kemajuan';

  @override
  String get loadProgress => 'Peuhah kemajuan';

  @override
  String loadProgressConfirm(String fileName, String name) {
    return 'Tamah kemajuan nibak file $fileName u $name? Bintang ngon pelajaran nyang ka seuleusoe nibak duwa jih teutap meukeubah.';
  }

  @override
  String get load => 'Peuhah';

  @override
  String get progressSaved => 'Kemajuan ka meukeubah';

  @override
  String get progressLoaded => 'Kemajuan ka meupeuhah';

  @override
  String get progressFileNotProgress => 'File nyoe kon kemajuan Coba Lagi.';

  @override
  String get progressFileTooNew =>
      'File nyoe nibak Coba Lagi nyang leubeh baro. Peubaro aplikasi dilee.';

  @override
  String get loadPlayer => 'Peuhah ureueng meu\'en nibak file';

  @override
  String playerLoaded(String name) {
    return '$name ka meugabong';
  }
}
