// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Javanese (`jv`).
class AppLocalizationsJv extends AppLocalizations {
  AppLocalizationsJv([String locale = 'jv']) : super(locale);

  @override
  String get appTitle => 'Coba Lagi';

  @override
  String get whoIsPlaying => 'Sapa sing dolanan?';

  @override
  String get editPlayer => 'Owahi pemain';

  @override
  String get addPlayer => 'Pemain anyar';

  @override
  String get nickname => 'Jeneng celukan';

  @override
  String get chooseAvatar => 'Pilih gambar';

  @override
  String get save => 'Simpen';

  @override
  String get cancel => 'Batal';

  @override
  String get delete => 'Busak';

  @override
  String get ok => 'Oke';

  @override
  String greeting(String name) {
    return 'Hai, $name!';
  }

  @override
  String get play => 'Dolanan';

  @override
  String get askAGrownUp => 'Njaluk tulung wong tuwa';

  @override
  String parentGateQuestion(int a, int b) {
    return 'Pira $a × $b?';
  }

  @override
  String get parentGateWrong => 'Durung pas. Coba maneh.';

  @override
  String get parentArea => 'Papan wong tuwa';

  @override
  String get language => 'Basa';

  @override
  String get languageSystem => 'Manut piranti';

  @override
  String get plan => 'Versi';

  @override
  String get planFree => 'Biasa: 1 pemain';

  @override
  String planFull(int count) {
    return 'Sponsor: nganti $count pemain';
  }

  @override
  String appVersion(String version, String build) {
    return 'Versi aplikasi $version ($build)';
  }

  @override
  String progressTitle(String name) {
    return 'Kemajuane $name';
  }

  @override
  String get changeStartingIsland => 'Ganti planet wiwitan';

  @override
  String get progressThisWeek => '7 dina pungkasan';

  @override
  String get progressAllTime => 'Wiwit awal';

  @override
  String progressPuzzles(int count) {
    return '$count teka-teki rampung';
  }

  @override
  String progressMinutes(int count) {
    return '$count menit dolanan';
  }

  @override
  String progressLastPlayed(String date) {
    return 'Pungkasan dolanan: $date';
  }

  @override
  String get progressNotPlayed => 'Durung ngrampungake teka-teki';

  @override
  String get progressIslands => 'Planet';

  @override
  String get statusNotStarted => 'Durung diwiwiti';

  @override
  String get statusPractising => 'Lagi latihan';

  @override
  String get statusMastered => 'Wis dikuwasani';

  @override
  String progressLevels(int solved, int total) {
    return '$solved saka $total level rampung';
  }

  @override
  String get progressSponsorOnly =>
      'Sponsor bisa ndeleng laporan kemajuan sing jangkep: teka-teki sing rampung, wektu dolanan, lan kemajuan ing saben planet.';

  @override
  String get music => 'Musik latar';

  @override
  String get soundEffects => 'Efek swara';

  @override
  String get hintArrowsFollowRoad => 'Panah pitunjuk manut dalan';

  @override
  String get hintArrowsFollowRoadHint =>
      'Mati: panah madhep munggah, kaya ing blok.';

  @override
  String get soundEffectsHint => 'Swara pitunjuk tetep keprungu.';

  @override
  String get supportCobaLagi => 'Dhukung Coba Lagi';

  @override
  String get debugPlanOverride => 'Debug: nganggo versi jangkep';

  @override
  String get players => 'Pemain';

  @override
  String deletePlayerConfirm(String name) {
    return 'Busak $name lan kabeh kemajuane?';
  }

  @override
  String get playerLimitReached =>
      'Versi iki mung kanggo siji pemain. Njaluk tulung wong tuwa.';

  @override
  String get run => 'Mlaku!';

  @override
  String get step => 'Sak langkah';

  @override
  String get reset => 'Wiwit maneh';

  @override
  String get undo => 'Batalke';

  @override
  String get redo => 'Baleni';

  @override
  String get clearBlocks => 'Busak kabeh blok';

  @override
  String get removeBlock => 'Busak blok iki';

  @override
  String get blockForward => 'Maju';

  @override
  String get blockTurnLeft => 'Menggok ngiwa';

  @override
  String get blockTurnRight => 'Menggok nengen';

  @override
  String get blockRepeat => 'Baleni';

  @override
  String get blockStar => 'Blok gaweanku';

  @override
  String get toMap => 'Menyang peta';

  @override
  String get tryAgain => 'Coba maneh!';

  @override
  String get feedbackBumped => 'Ups, ana sing ngalangi.';

  @override
  String get feedbackStoppedShort => 'Meh wae! Terus mlaku nganti gendera.';

  @override
  String get feedbackOtherBoard =>
      'Peta kuwi wis bisa! Peta iki beda, dadi delengen ngarep sadurunge saben langkah.';

  @override
  String get feedbackMissedStars => 'Klumpukna kabeh lintang dhisik.';

  @override
  String get feedbackTooManySteps => 'Langkahe kakehan! Coba luwih sithik.';

  @override
  String get home => 'Ngarep';

  @override
  String get conceptDirections => 'Arah';

  @override
  String get conceptSequencing => 'Langkah siji-siji';

  @override
  String get conceptLoops => 'Mbaleni';

  @override
  String get conceptFunctions => 'Blok Ajaib';

  @override
  String get decisionAdvance => 'Planet anyar kebukak!';

  @override
  String get decisionPractice => 'Ayo nyoba sing liya!';

  @override
  String get bonusAdventure => 'Petualangan bonus!';

  @override
  String get decisionReview => 'Ayo golek bandha karun ing planet sadurunge.';

  @override
  String get decisionReturn => 'Bali menyang petualanganmu!';

  @override
  String get decisionMapComplete => 'Kowe wis njelajahi kabeh planet!';

  @override
  String get hint => 'Tuduhna dalane';

  @override
  String get hintNextPattern => 'Tuduhna blok sing bola-bali';

  @override
  String get hintNextRing => 'Tuduhna blok sing kudu diganti';

  @override
  String get repeatMore => 'Tambah sepisan';

  @override
  String get repeatFewer => 'Kurangi sepisan';

  @override
  String get dropBlocksHere => 'Selehna blok ing kene';

  @override
  String get pretestWelcome => 'Hai, aku Koba! Ayo dolanan pemanasan dhisik!';

  @override
  String get pretestStart => 'Wiwit';

  @override
  String get listenAgain => 'Rungokna maneh';

  @override
  String get promptReading => 'Gambar endi sing cocog karo tulisan iki?';

  @override
  String get promptCounting => 'Ana pira?';

  @override
  String get promptSideLeft => 'Demok sing ing sisih kiwa.';

  @override
  String get promptSideRight => 'Demok sing ing sisih tengen.';

  @override
  String get promptTurnLeft =>
      'Panahe menggok ngiwa. Saiki nuding menyang endi?';

  @override
  String get promptTurnRight =>
      'Panahe menggok nengen. Saiki nuding menyang endi?';

  @override
  String get promptPattern => 'Apa sing sabanjure?';

  @override
  String get promptSequencing => 'Langkah endi sing tekan gendera?';

  @override
  String get pretestDone => 'Rampung! Petualanganmu diwiwiti saiki.';

  @override
  String get startAdventure => 'Ayo!';

  @override
  String get wordSun => 'srengenge';

  @override
  String get wordStar => 'lintang';

  @override
  String get wordHouse => 'omah';

  @override
  String get wordCar => 'mobil';

  @override
  String get wordTree => 'wit';

  @override
  String get wordBall => 'bal';

  @override
  String get wordFlower => 'kembang';

  @override
  String get wordBoat => 'prau';

  @override
  String get wordBird => 'manuk';

  @override
  String get wordCake => 'jajan';

  @override
  String get colorRed => 'abang';

  @override
  String get colorBlue => 'biru';

  @override
  String get colorGreen => 'ijo';

  @override
  String get colorYellow => 'kuning';

  @override
  String wordsWithColor(String color, String object) {
    return '$object $color';
  }

  @override
  String get startingIsland => 'Planet wiwitan';

  @override
  String get retakePretest => 'Dolanan pemanasan maneh';

  @override
  String placementNowAt(String island) {
    return 'Saiki ing: $island';
  }

  @override
  String get placementNotYet => 'Durung dolanan pemanasan';

  @override
  String get setByParent => 'diatur wong tuwa';

  @override
  String get cheerCelebrate1 => 'Hebat!';

  @override
  String get cheerCelebrate2 => 'Keren!';

  @override
  String get cheerCelebrate3 => 'Kowe kasil!';

  @override
  String get cheerCelebrate4 => 'Super!';

  @override
  String get cheerCelebrate5 => 'Wah, apik banget!';

  @override
  String get cheerCelebrate6 => 'Luar biasa!';

  @override
  String get cheerEncourage1 => 'Pikirane apik!';

  @override
  String get cheerEncourage2 => 'Usahane apik!';

  @override
  String get cheerEncourage3 => 'Ayo terus!';

  @override
  String get cheerEncourage4 => 'Suwun wis nyoba!';

  @override
  String get cheerEncourage5 => 'Kowe hebat!';

  @override
  String get donateExplainer =>
      'Coba Lagi gratis. Donasi pira wae mbukak fitur sponsor kanggo kulawargamu lan mbantu awake dewe nggawe luwih akeh petualangan.';

  @override
  String get donateUnavailable => 'Donasi ora ana ing piranti iki.';

  @override
  String get restoreDonation => 'Balekna donasi sadurunge';

  @override
  String get tipExplainer =>
      'Coba Lagi gratis. Tip pira wae mbukak fitur sponsor kanggo kulawargamu lan mbantu awake dewe nggawe luwih akeh petualangan.';

  @override
  String get tipsUnavailable => 'Tip ora ana ing piranti iki.';

  @override
  String get restorePurchases => 'Balekna sing wis dituku';

  @override
  String get haveUnlockCode => 'Duwe kode?';

  @override
  String get buyUnlockCode => 'Tuku kode';

  @override
  String get buyUnlockCodeExplainer =>
      'Tuku kode ing situs kita. Kodene dikirim lewat email; banjur lebokna lewat \"Duwe kode?\".';

  @override
  String get unlockCode => 'Kode';

  @override
  String get useUnlockCode => 'Nganggo kode';

  @override
  String get unlockCodeRejected =>
      'Kode kuwi ora laku. Priksanen maneh, banjur coba sepisan engkas.';

  @override
  String get unlockCodeGithubOnly =>
      'Kode iki kanggo aplikasi saka GitHub. Ing aplikasi iki, dhukungan liwat toko aplikasine.';

  @override
  String get thanksForSupport => 'Suwun wis ndhukung Coba Lagi!';

  @override
  String get playGoal => 'Tulungi aku tekan gendera!';

  @override
  String get playGoalStars =>
      'Klumpukna kabeh lintang, banjur menyang gendera!';

  @override
  String get playGoalLoops => 'Nganggo blok baleni supaya tekan gendera!';

  @override
  String get playGoalFunctions =>
      'Isi blok lintang, banjur nganggo bola-bali supaya tekan gendera!';

  @override
  String get playHowTo =>
      'Seret blok menyang kothak putih, banjur pencet Mlaku!';

  @override
  String get backToIsland => 'Bali menyang planet';

  @override
  String get continueAdventure => 'Terusna petualangan';

  @override
  String levelNumber(int number) {
    return 'Level $number';
  }

  @override
  String get levelLocked => 'Durung kebukak';

  @override
  String get answerWas => 'Jawabane sing iki!';

  @override
  String get conceptConditions => 'Deleng ngarep';

  @override
  String get blockUntilGoal => 'Baleni nganti gendera';

  @override
  String get blockIfPathClear => 'Yen kosong';

  @override
  String get playGoalConditions =>
      'Delengen ngarep! Selehna blok maju ing njero blok mripat. Blok kuwi mung maju yen dalan ing ngarep kosong. Blokmu kudu kasil ing saben peta!';

  @override
  String get updateAvailableTitle => 'Ana nganyari';

  @override
  String get updateAvailableBody =>
      'Versi paling anyar Coba Lagi wis ana. Njaluk tulung wong tuwa kanggo nganyari aplikasi.';

  @override
  String get updateWithParent => 'Njaluk tulung nganyari';

  @override
  String get updateContinue => 'Terus dolanan';

  @override
  String get updateOpenFailed =>
      'Nganyari durung bisa dibukak. Coba maneh utawa terus dolanan.';

  @override
  String get codeTab => 'Tab Kode';

  @override
  String get codeTabHint =>
      'Bocah bisa ngetik kode saliyane nganggo blok gambar. Dolanan pemanasan nguripake kanggo bocah sing wis bisa maca.';

  @override
  String get editorBlocks => 'Blok';

  @override
  String get editorCode => 'Kode';

  @override
  String get codeDrafts =>
      'Saben editor nyimpen draf dewe. Draf kode kapisan asale saka blokmu.';

  @override
  String get codeHelp => 'Pandhuan kode';

  @override
  String get codeSource => 'Kodemu';

  @override
  String get codeGuide =>
      'Demok prentah kanggo nambahake, utawa ketik dewe. Jeneng prentah tetep padha ing kabeh basa. Pungkasi aksi nganggo (); lan selehna isi baleni lan pamriksan ing antarane kurung kurawal buka lan tutup. Cacahe baleni 1–9. Gawe Blok Ajaib nganggo define star, banjur lakokna nganggo star();. // miwiti komentar. Saben prentah dietung siji blok, kalebu prentah ing njero kurung kurawal. Simpen angka nganggo steps = 3; lan nganggo move(steps); kanggo maju semono. Angkane tetep padha nganti kowe nyimpen sing anyar. Simpen sadurunge nganggo. until_flag mbaleni isi kurung kurawale nganti robot tekan gendera, tanpa etungan.';

  @override
  String get codeSyntax =>
      'Priksa jeneng prentah, tandha kurung, kurung kurawal, lan titik koma.';

  @override
  String get codeNumber => 'Pilih angka saka 1 nganti 9.';

  @override
  String get codeDuplicateStar => 'Nganggo siji bagean define star wae.';

  @override
  String get codeNestedStar =>
      'Selehna define star ing njaba baleni lan pamriksan.';

  @override
  String get codeTooLarge =>
      'Coba program sing luwih cendhak kanthi bagean bertingkat sing luwih sithik.';

  @override
  String get codeDisallowed => 'Nganggo prentah sing ana kanggo teka-teki iki.';

  @override
  String get codeLimit =>
      'Coba kurangi prentah supaya cocog karo watesan blok.';

  @override
  String get codeEmptyBody => 'Tambahna prentah ing njero kurung kurawal.';

  @override
  String get codeEmptyStar =>
      'Tambahna prentah menyang define star sadurunge nganggo star();.';

  @override
  String get codeRecursiveStar =>
      'Nganggo langkah, menggok, baleni, utawa pamriksan ing njero define star.';

  @override
  String get codeReady => 'Siap dilakokake';

  @override
  String get codeStart => 'Tambahna prentah kanggo miwiti.';

  @override
  String codeLine(int line, String message) {
    return 'Baris $line: $message';
  }

  @override
  String codeRunningLine(int line) {
    return 'Nglakokake baris $line';
  }

  @override
  String get codeDefineStar => 'Gawe blokku';

  @override
  String get conceptUntil => 'Nganti gendera';

  @override
  String get playGoalUntil =>
      'Nganggo blok baleni nganti gendera: blok kuwi terus mlaku dewe, dadi kowe ora perlu ngetung!';

  @override
  String get conceptDebugging => 'Benakna!';

  @override
  String get playGoalDebugging =>
      'Ups, blok iki durung pas! Pencet Mlaku, delengen apa sing kedadean, banjur benakna.';

  @override
  String get conceptVariables => 'Kothak Langkah';

  @override
  String get blockSetSteps => 'Simpen langkah';

  @override
  String get blockMoveSteps => 'Nganggo langkah';

  @override
  String get stepsFewer => 'Simpen angka luwih cilik';

  @override
  String get stepsMore => 'Simpen angka luwih gedhe';

  @override
  String get playGoalVariables =>
      'Simpen angka ing Kothak Langkahmu, banjur nganggo kanggo maju semono! Angkane bisa dienggo maneh utawa diganti. Tekan gendera lan klumpukna kabeh lintang.';

  @override
  String stepBoxValue(String value) {
    return 'Kothak Langkah: $value';
  }

  @override
  String get codeUnsetSteps =>
      'Simpen angka nganggo steps = 2; sadurunge nganggo move(steps);.';

  @override
  String get variableHint =>
      'Simpen angka dhisik, banjur nganggo kothak kanggo maju. Angkane tetep padha nganti kowe ngganti.';

  @override
  String get tutorialTitle => 'Delengen aku!';

  @override
  String get tutorialWatchAgain => 'Deleng maneh';

  @override
  String get tutorialLetsPlay => 'Ayo dolanan!';

  @override
  String get tutorialSkip => 'Liwati';

  @override
  String get storyTitle => 'Kapal lintange Koba';

  @override
  String get storyShelfIntro => 'Wiwitane crita';

  @override
  String get storyShelfNewPlanet => 'Planet anyar';

  @override
  String get storyShelfEnding => 'Tangkine kebak!';

  @override
  String get storyShelfFullAgain => 'Tangkine kebak maneh';

  @override
  String get storyIntroFly =>
      'Iki kapal lintange Koba. Kapal iki mabur nganggo lintang!';

  @override
  String get storyIntroWind =>
      'Wuusss! Angin angkasa nyebul lintang saka tangkine, menyang kabeh planet.';

  @override
  String get storyIntroLand => 'Lintange entek, dadi kapale kudu mudhun.';

  @override
  String get storyIntroBump => 'Ups, ana watu! Ora apa-apa. Aku nyoba maneh!';

  @override
  String get storyIntroHelp =>
      'Ayo golek lintange bareng. Kowe gelem nulungi aku, Komandan?';

  @override
  String get storyFly =>
      'Tangkiku tambah lintang! Ayo menyang planet sabanjure!';

  @override
  String get storyArrivalDirections =>
      'Kapale mudhun ing planet sing kebak papan pitunjuk. Arahe menyang ngendi-endi!';

  @override
  String get storyArrivalDirectionsKoba =>
      'Aku kudu menyang endi? Tuduhna nganggo panah: maju, kiwa, utawa tengen!';

  @override
  String get storyArrivalSequencing =>
      'Ing kene, lintange ana ing sadawane dalan sing menggak-menggok.';

  @override
  String get storyArrivalSequencingKoba =>
      'Aku butuh kabeh langkahe urut, siji-siji!';

  @override
  String get storyArrivalLoops =>
      'Ing planet iki, dalane maju, menggok, maju, menggok, terus bola-bali.';

  @override
  String get storyArrivalLoopsKoba =>
      'Akeh banget langkahe! Ana dalan cepet, ora?';

  @override
  String get storyArrivalFunctions =>
      'Koba nemokake blok ajaib sing gumebyar ing lemah.';

  @override
  String get storyArrivalFunctionsKoba =>
      'Blok iki bisa ngeling-eling obahku! Wulangen sepisan, banjur nganggo bola-bali.';

  @override
  String get storyArrivalConditions =>
      'Pedhut kandel nutupi planet iki. Koba ora bisa ndeleng dalane!';

  @override
  String get storyArrivalConditionsKoba =>
      'Aku nguripake lampuku lan ndeleng ngarep sadurunge jumangkah.';

  @override
  String get storyArrivalVariables =>
      'Ing planet iki, Koba nemokake kothak cilik sing ana angkane.';

  @override
  String get storyArrivalVariablesKoba =>
      'Kothak iki ngeling-eling angka! Angkane ngandhani pira langkahku.';

  @override
  String get storyArrivalDebugging =>
      'Ana sing ninggal blok ing dalan, kabeh kewolak-walik.';

  @override
  String get storyArrivalDebuggingKoba =>
      'Blok iki durung pas. Ayo golek sing kudu dibenakake!';

  @override
  String get storyArrivalUntil =>
      'Adoh, adoh banget, ana gendera ing pucuke dalan sing dawa.';

  @override
  String get storyArrivalUntilKoba =>
      'Langkahe kakehan kanggo dietung! Aku mlaku terus wae nganti gendera.';

  @override
  String get storyArrivalOtherwise =>
      'Dalane pecah dadi loro. Ing salah sijine ana grumbul!';

  @override
  String get storyArrivalOtherwiseKoba =>
      'Yen dalane kosong, aku maju. Yen ora, aku menggok!';

  @override
  String get storyEnding =>
      'Lintang pungkasan mabur mulih. Tangkine Koba kebak!';

  @override
  String get storyEndingKoba =>
      'Suwun, Komandan! Kowe nulungi aku nemokake kabeh lintang.';

  @override
  String get storyEndingMore =>
      'Saiki awake dewe bisa mabur menyang ngendi wae. Ayo terus dolanan bareng!';

  @override
  String get storyFullAgain => 'Lintang-lintang mabur mulih menyang tangki.';

  @override
  String get storyNewPlanet =>
      'Wuusss! Angin angkasa nyebul sawetara lintang saka tangki, menyang planet sing durung tau ditemokake.';

  @override
  String get storyNewPlanetKoba =>
      'Planet anyar! Kowe gelem nulungi aku golek lintang maneh, Komandan?';

  @override
  String get storyThanksDirections =>
      'Kebak maneh! Suwun wis mulang aku kiwa lan tengen, Komandan!';

  @override
  String get storyThanksSequencing =>
      'Kebak maneh! Suwun wis mulang aku langkah sing urut, Komandan!';

  @override
  String get storyThanksLoops =>
      'Kebak maneh! Suwun wis mulang aku mbaleni, Komandan!';

  @override
  String get storyThanksFunctions =>
      'Kebak maneh! Suwun wis mulang aku Blok Ajaib, Komandan!';

  @override
  String get storyThanksConditions =>
      'Kebak maneh! Suwun wis mulang aku ndeleng ngarep, Komandan!';

  @override
  String get storyThanksVariables =>
      'Kebak maneh! Suwun wis mulang aku Kothak Langkah, Komandan!';

  @override
  String get storyThanksDebugging =>
      'Kebak maneh! Suwun wis mulang aku mbenakake blok, Komandan!';

  @override
  String get storyThanksUntil =>
      'Kebak maneh! Suwun wis mulang aku mlaku nganti gendera, Komandan!';

  @override
  String get storyThanksOtherwise =>
      'Kebak maneh! Suwun wis mulang aku apa sing ditindakake yen ora, Komandan!';

  @override
  String get watchHow => 'Deleng carane';

  @override
  String get tutorialDirections =>
      'Demok blok panah kanggo ngandhani aku kudu menyang endi: maju, menggok ngiwa, menggok nengen. Banjur pencet Mlaku!';

  @override
  String get tutorialSequencing =>
      'Tata langkahe urut, siji-siji, nganti tekan gendera.';

  @override
  String get tutorialLoops =>
      'Langkahe padha terus? Lebokna ing blok baleni, banjur pilih ping pira!';

  @override
  String get tutorialFunctions =>
      'Gawe blok ajaibmu dewe ing baris lintang. Banjur nganggo lintange bola-bali!';

  @override
  String get tutorialConditions =>
      'Blok mripat ndeleng ngarep. Yen dalane kosong, aku maju. Yen ora, aku ngenteni. Dadi blok sing padha kasil ing saben peta!';

  @override
  String get tutorialVariables =>
      'Simpen angka ing Kothak Langkah. Banjur nganggo langkah kanggo mlaku semono!';

  @override
  String get tutorialDebugging =>
      'Blok iki durung pas. Pencet Mlaku lan gatekna. Banjur demok blok sing kudu dibenakake, lan demok blok sing bener!';

  @override
  String get tutorialUntil =>
      'Baleni nganti gendera terus mlaku dewe, dadi kowe ora perlu ngetung!';

  @override
  String get hintPattern =>
      'Blok-blok iki metu bola-bali. Coba nganggo blok baleni!';

  @override
  String get hintAgain =>
      'Demok lampu maneh kanggo ndeleng blok sing bola-bali!';

  @override
  String get hintLookHere =>
      'Delengen blok sing ana lampune. Coba ganti blok kuwi!';

  @override
  String get hintLookHereMany =>
      'Delengen blok-blok sing ana lampune. Coba ganti blok-blok kuwi!';

  @override
  String get turnMap => 'Puter peta';

  @override
  String boardNumber(int number) {
    return 'Peta $number';
  }

  @override
  String get tourPalette =>
      'Iki blok-blokmu. Demok siji, utawa seret menyang programmu.';

  @override
  String get tourProgram =>
      'Programmu ana ing kene. Aku nglakokake bloke urut, saka sing kapisan. Demok blok kanggo ngganti.';

  @override
  String get tourGo => 'Pencet Mlaku, lan aku manut blok-blokmu!';

  @override
  String get tourStep =>
      'Tombol iki nglakokake siji blok saben pisan, dadi kowe bisa ndeleng kanthi tliti.';

  @override
  String get tourReset => 'Sing iki nggawa aku bali menyang wiwitan.';

  @override
  String get tourHint =>
      'Bingung? Sawise nyoba kaping pira-pira, lampune murup. Saben didemok nuduhake sithik engkas: kapisan dalane, banjur blok endi sing kudu diganti. Tandha cilik ing lampu nuduhake apa sing sabanjure.';

  @override
  String get tourFollow =>
      'Iki muter peta saprapat puteran saben pisan, dadi kowe bisa ndeleng saka sisihku.';

  @override
  String get tourBoards =>
      'Ing kene ana sawetara peta. Demok titik kanggo ndeleng saben peta. Blokmu kudu nggawa aku tekan gendera ing saben peta!';

  @override
  String get tourListen =>
      'Demok speaker kanggo ngrungokake maneh apa sing kudu ditindakake.';

  @override
  String get tourWarmUpListen =>
      'Rungokna pitakone. Demok speaker kanggo ngrungokake maneh.';

  @override
  String get tourWarmUpAnswer => 'Banjur demok gambar sing miturutmu bener!';

  @override
  String get tourWarmUpSteps =>
      'Tapak sikil nuduhake wis tekan ngendi dolananmu.';

  @override
  String get tourBlockForward => 'Panah ijo nggawe aku maju sak langkah.';

  @override
  String get tourBlockTurnLeft =>
      'Panah biru nggawe aku menggok ngiwa, tanpa pindhah.';

  @override
  String get tourBlockTurnRight =>
      'Panah oranye nggawe aku menggok nengen, tanpa pindhah.';

  @override
  String get tourBlockRepeat =>
      'Blok baleni nglakokake blok ing njerone bola-bali. Demok min utawa plus kanggo milih ping pira.';

  @override
  String get tourBlockSetSteps =>
      'Kothak Langkah nyimpen cacahe langkah. Demok min utawa plus kanggo ngowahi.';

  @override
  String get tourBlockMoveSteps =>
      'Panah iki nggawe aku maju semono angka ing Kothak Langkah.';

  @override
  String get tourBlockIfPathClear =>
      'Blok mripat ndeleng ngarep. Blok ing njerone mung mlaku yen dalane kosong.';

  @override
  String get tourBlockIfElse =>
      'Blok mripat iki duwe rong baris: baris ndhuwur mlaku yen dalane kosong, baris ngisor yen ora.';

  @override
  String get tourBlockUntilGoal =>
      'Baleni nganti gendera nglakokake blok ing njerone terus-terusan, nganti aku tekan gendera.';

  @override
  String get tourBlockStar =>
      'Blok lintang nglakokake blok ing baris lintangmu: blok ajaib gaweanmu dewe.';

  @override
  String get tourNext => 'Terus';

  @override
  String get tourDone => 'Mudheng!';

  @override
  String get tourHelp => 'Piye carane?';

  @override
  String get breakTitle => 'Wayahe ngaso!';

  @override
  String get breakBody =>
      'Kowe wis dolanan kanthi hebat. Ngasokna mripatmu, coba ulet-ulet, banjur dolanan maneh mengko.';

  @override
  String get breakHome => 'Bali menyang pemain';

  @override
  String get breakContinue => 'Wong tuwa bisa nerusake';

  @override
  String get breakVoice =>
      'Wayahe ngaso! Kowe wis dolanan kanthi hebat. Ngasokna mripatmu, coba ulet-ulet, banjur dolanan maneh mengko.';

  @override
  String get breakReminder => 'Pangeling ngaso';

  @override
  String get breakReminderHint =>
      'Sawise dolanan teka-teki semene suwene, bocah diajak ngaso. Mung wong tuwa sing bisa nerusake.';

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
      other: 'Kari $count teka-teki engkas bisa nggawa kowe menyang $island!',
      one: 'Teka-teki sabanjure bisa nggawa kowe menyang $island!',
    );
    return '$_temp0';
  }

  @override
  String get conceptWarmUp => 'Pemanasan';

  @override
  String get warmUpCounting => 'Ngetung';

  @override
  String get warmUpColors => 'Werna';

  @override
  String get warmUpShapes => 'Wujud';

  @override
  String get warmUpPatterns => 'Pola';

  @override
  String get warmUpSides => 'Kiwa lan tengen';

  @override
  String get warmUpSteps => 'Langkah';

  @override
  String get warmUpReading => 'Maca';

  @override
  String get warmUpPick => 'Pilih dolanan!';

  @override
  String get warmUpDone => 'Apik banget dolananmu! Dolanan maneh?';

  @override
  String get playAgain => 'Dolanan maneh';

  @override
  String get promptColorRed => 'Demok sing abang!';

  @override
  String get promptColorBlue => 'Demok sing biru!';

  @override
  String get promptColorGreen => 'Demok sing ijo!';

  @override
  String get promptColorYellow => 'Demok sing kuning!';

  @override
  String get promptShapeCircle => 'Demok bunderan!';

  @override
  String get promptShapeSquare => 'Demok kothak!';

  @override
  String get promptShapeTriangle => 'Demok segitiga!';

  @override
  String get promptShapeHeart => 'Demok ati!';

  @override
  String playLevel(int number) {
    return 'Dolanan level $number';
  }

  @override
  String get stickerBook => 'Buku stiker';

  @override
  String get stickerBookHello => 'Delengen kabeh stikermu!';

  @override
  String get stickersIslands => 'Planet';

  @override
  String get stickerNotYet => 'Durung entuk';

  @override
  String get stickerGold => 'Kabeh lintang wis kumpul!';

  @override
  String get blockIfElse => 'Yen kosong, yen ora';

  @override
  String get otherwiseRowClear => 'Yen dalane kosong';

  @override
  String get otherwiseRowBlocked => 'Yen ora';

  @override
  String get conceptOtherwise => 'Yen ora';

  @override
  String get playGoalOtherwise =>
      'Nganggo blok mripat sing rong baris: yen dalane kosong, jumangkah. Yen ora, menggok!';

  @override
  String get tutorialOtherwise =>
      'Mripat ndeleng ngarep. Yen dalane kosong, jumangkah. Yen ora, menggok. Banjur kabeh dibaleni nganti gendera!';

  @override
  String starsEarned(int count) {
    return '$count saka 3 lintang';
  }

  @override
  String get progressFileTitle => 'Pindhah menyang piranti liya';

  @override
  String progressFileHint(String name) {
    return 'Simpen kemajuane $name menyang file, banjur bukak ing Coba Lagi ing piranti liya. Mbukak mung nambahi sing wis ana; ora ana sing ilang.';
  }

  @override
  String get saveProgress => 'Simpen kemajuan';

  @override
  String get loadProgress => 'Bukak kemajuan';

  @override
  String loadProgressConfirm(String fileName, String name) {
    return 'Tambahna kemajuan saka file $fileName menyang $name? Lintang lan pelajaran sing wis rampung saka loro-lorone tetep disimpen.';
  }

  @override
  String get load => 'Bukak';

  @override
  String get progressSaved => 'Kemajuan wis disimpen';

  @override
  String get progressLoaded => 'Kemajuan wis dibukak';

  @override
  String get progressFileNotProgress => 'File iki dudu kemajuan Coba Lagi.';

  @override
  String get progressFileTooNew =>
      'File iki saka Coba Lagi sing luwih anyar. Anyarana aplikasine dhisik.';

  @override
  String get loadPlayer => 'Bukak pemain saka file';

  @override
  String get conceptExamples => 'Warahi Koba';

  @override
  String get playGoalExamples =>
      'Mripat ndeleng barang ing ngarep. Yen katon aman, jumangkah. Yen ora, menggok!';

  @override
  String get tutorialExamples =>
      'Kowe wis nuduhake gambar sing aman. Mripat ndeleng ngarep. Yen katon aman, aku jumangkah. Yen ora, aku menggok, nganti gendera!';

  @override
  String get storyArrivalExamples => 'Ana barang anyar ing dalane planet iki.';

  @override
  String get storyArrivalExamplesKoba =>
      'Ana sing aman diliwati, ana sing ora. Warahi aku nganggo gambar, mengko aku sinau!';

  @override
  String get storyThanksExamples =>
      'Kebak maneh! Suwun wis mulang aku sinau saka conto, Komandan!';

  @override
  String get sortSafe => 'Sing aman dilebokke kene.';

  @override
  String get sortNotSafe => 'Sing iki ora aman.';

  @override
  String get sortKobaTries => 'Aku nyoba sing anyar.';

  @override
  String get sortKobaWrong =>
      'Aku nebak saka gambare. Gambare kok mirip banget.';

  @override
  String get sortMore => 'Gambar maneh';

  @override
  String get sortLetsGo => 'Ayo dolan!';

  @override
  String get tourSortPicture => 'Gambar anyar. Lebokke ing klompok sing pas.';

  @override
  String get tourSortSafe => 'Gambar sing aman mlebu klompok iki.';

  @override
  String get tourSortNot => 'Gambar sing ora aman mlebu klompok iki.';

  @override
  String playerLoaded(String name) {
    return '$name wis melu';
  }
}
