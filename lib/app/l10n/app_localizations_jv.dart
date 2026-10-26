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
  String get feedbackStoppedShort => 'Meh wae! Terus mlaku nganti gendéra.';

  @override
  String get feedbackOtherBoard =>
      'Peta kuwi wis bisa! Peta iki béda, dadi delengen ngarep sadurunge saben langkah.';

  @override
  String get feedbackMissedStars => 'Klumpukna kabeh lintang dhisik.';

  @override
  String get feedbackTooManySteps => 'Langkahé kakehan! Coba luwih sithik.';

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
  String get decisionMapComplete => 'Kowé wis njelajahi kabeh planet!';

  @override
  String get hint => 'Tuduhna dalané';

  @override
  String get hintNextPattern => 'Tuduhna blok sing bola-bali';

  @override
  String get hintNextRing => 'Tuduhna blok sing kudu diganti';

  @override
  String get repeatMore => 'Tambah sepisan';

  @override
  String get repeatFewer => 'Kurangi sepisan';

  @override
  String get dropBlocksHere => 'Selehna blok ing kéné';

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
      'Panahé menggok ngiwa. Saiki nuding menyang endi?';

  @override
  String get promptTurnRight =>
      'Panahé menggok nengen. Saiki nuding menyang endi?';

  @override
  String get promptPattern => 'Apa sing sabanjuré?';

  @override
  String get promptSequencing => 'Langkah endi sing tekan gendéra?';

  @override
  String get pretestDone => 'Rampung! Petualanganmu diwiwiti saiki.';

  @override
  String get startAdventure => 'Ayo!';

  @override
  String get wordSun => 'srengéngé';

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
  String get cheerCelebrate3 => 'Kowé kasil!';

  @override
  String get cheerCelebrate4 => 'Super!';

  @override
  String get cheerCelebrate5 => 'Wah, apik banget!';

  @override
  String get cheerCelebrate6 => 'Luar biasa!';

  @override
  String get cheerEncourage1 => 'Pikirané apik!';

  @override
  String get cheerEncourage2 => 'Usahané apik!';

  @override
  String get cheerEncourage3 => 'Ayo terus!';

  @override
  String get cheerEncourage4 => 'Suwun wis nyoba!';

  @override
  String get cheerEncourage5 => 'Kowé hebat!';

  @override
  String get donateExplainer =>
      'Coba Lagi gratis. Donasi pira waé mbukak fitur sponsor kanggo kulawargamu lan mbantu awaké déwé nggawé luwih akèh petualangan.';

  @override
  String get donateUnavailable => 'Donasi ora ana ing piranti iki.';

  @override
  String get restoreDonation => 'Balèkna donasi sadurungé';

  @override
  String get tipExplainer =>
      'Coba Lagi gratis. Tip pira waé mbukak fitur sponsor kanggo kulawargamu lan mbantu awaké déwé nggawé luwih akèh petualangan.';

  @override
  String get tipsUnavailable => 'Tip ora ana ing piranti iki.';

  @override
  String get restorePurchases => 'Balèkna sing wis dituku';

  @override
  String get haveUnlockCode => 'Duwé kode?';

  @override
  String get unlockCode => 'Kode';

  @override
  String get useUnlockCode => 'Nganggo kode';

  @override
  String get unlockCodeRejected =>
      'Kode kuwi ora laku. Priksanen maneh, banjur coba sepisan engkas.';

  @override
  String get thanksForSupport => 'Suwun wis ndhukung Coba Lagi!';

  @override
  String get playGoal => 'Tulungi aku tekan gendéra!';

  @override
  String get playGoalStars =>
      'Klumpukna kabeh lintang, banjur menyang gendéra!';

  @override
  String get playGoalLoops => 'Nganggo blok baleni supaya tekan gendéra!';

  @override
  String get playGoalFunctions =>
      'Isi blok lintang, banjur nganggo bola-bali supaya tekan gendéra!';

  @override
  String get playHowTo =>
      'Sérét blok menyang kothak putih, banjur pencet Mlaku!';

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
  String get answerWas => 'Jawabané sing iki!';

  @override
  String get conceptConditions => 'Deleng ngarep';

  @override
  String get blockUntilGoal => 'Baleni nganti gendéra';

  @override
  String get blockIfPathClear => 'Yèn kosong';

  @override
  String get playGoalConditions =>
      'Delengen ngarep! Selehna blok maju ing njero blok mripat. Blok kuwi mung maju yèn dalan ing ngarep kosong. Blokmu kudu kasil ing saben peta!';

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
      'Bocah bisa ngetik kode saliyané nganggo blok gambar. Dolanan pemanasan nguripaké kanggo bocah sing wis bisa maca.';

  @override
  String get editorBlocks => 'Blok';

  @override
  String get editorCode => 'Kode';

  @override
  String get codeDrafts =>
      'Saben editor nyimpen draf déwé. Draf kode kapisan asalé saka blokmu.';

  @override
  String get codeHelp => 'Pandhuan kode';

  @override
  String get codeSource => 'Kodemu';

  @override
  String get codeGuide =>
      'Demok préntah kanggo nambahaké, utawa ketik déwé. Jeneng préntah tetep padha ing kabeh basa. Pungkasi aksi nganggo (); lan selehna isi baleni lan pamriksan ing antarané kurung kurawal buka lan tutup. Cacahé baleni 1–9. Gawé Blok Ajaib nganggo define star, banjur lakokna nganggo star();. // miwiti komentar. Saben préntah diétung siji blok, kalebu préntah ing njero kurung kurawal. Simpen angka nganggo steps = 3; lan nganggo move(steps); kanggo maju semono. Angkané tetep padha nganti kowé nyimpen sing anyar. Simpen sadurungé nganggo. until_flag mbaleni isi kurung kurawalé nganti robot tekan gendéra, tanpa étungan.';

  @override
  String get codeSyntax =>
      'Priksa jeneng préntah, tandha kurung, kurung kurawal, lan titik koma.';

  @override
  String get codeNumber => 'Pilih angka saka 1 nganti 9.';

  @override
  String get codeDuplicateStar => 'Nganggo siji bagéan define star waé.';

  @override
  String get codeNestedStar =>
      'Selehna define star ing njaba baleni lan pamriksan.';

  @override
  String get codeTooLarge =>
      'Coba program sing luwih cendhak kanthi bagéan bertingkat sing luwih sithik.';

  @override
  String get codeDisallowed => 'Nganggo préntah sing ana kanggo teka-teki iki.';

  @override
  String get codeLimit =>
      'Coba kurangi préntah supaya cocog karo watesan blok.';

  @override
  String get codeEmptyBody => 'Tambahna préntah ing njero kurung kurawal.';

  @override
  String get codeEmptyStar =>
      'Tambahna préntah menyang define star sadurungé nganggo star();.';

  @override
  String get codeRecursiveStar =>
      'Nganggo langkah, menggok, baleni, utawa pamriksan ing njero define star.';

  @override
  String get codeReady => 'Siap dilakokaké';

  @override
  String get codeStart => 'Tambahna préntah kanggo miwiti.';

  @override
  String codeLine(int line, String message) {
    return 'Baris $line: $message';
  }

  @override
  String codeRunningLine(int line) {
    return 'Nglakokaké baris $line';
  }

  @override
  String get codeDefineStar => 'Gawé blokku';

  @override
  String get conceptUntil => 'Nganti gendéra';

  @override
  String get playGoalUntil =>
      'Nganggo blok baleni nganti gendéra: blok kuwi terus mlaku déwé, dadi kowé ora perlu ngétung!';

  @override
  String get conceptDebugging => 'Bénakna!';

  @override
  String get playGoalDebugging =>
      'Ups, blok iki durung pas! Pencet Mlaku, delengen apa sing kedadéan, banjur bénakna.';

  @override
  String get conceptVariables => 'Kothak Langkah';

  @override
  String get blockSetSteps => 'Simpen langkah';

  @override
  String get blockMoveSteps => 'Nganggo langkah';

  @override
  String get stepsFewer => 'Simpen angka luwih cilik';

  @override
  String get stepsMore => 'Simpen angka luwih gedhé';

  @override
  String get playGoalVariables =>
      'Simpen angka ing Kothak Langkahmu, banjur nganggo kanggo maju semono! Angkané bisa dienggo maneh utawa diganti. Tekan gendéra lan klumpukna kabeh lintang.';

  @override
  String stepBoxValue(String value) {
    return 'Kothak Langkah: $value';
  }

  @override
  String get codeUnsetSteps =>
      'Simpen angka nganggo steps = 2; sadurungé nganggo move(steps);.';

  @override
  String get variableHint =>
      'Simpen angka dhisik, banjur nganggo kothak kanggo maju. Angkané tetep padha nganti kowé ngganti.';

  @override
  String get tutorialTitle => 'Delengen aku!';

  @override
  String get tutorialWatchAgain => 'Deleng maneh';

  @override
  String get tutorialLetsPlay => 'Ayo dolanan!';

  @override
  String get tutorialSkip => 'Liwati';

  @override
  String get storyTitle => 'Kapal lintangé Koba';

  @override
  String get storyShelfIntro => 'Wiwitané crita';

  @override
  String get storyShelfNewPlanet => 'Planet anyar';

  @override
  String get storyShelfEnding => 'Tangkiné kebak!';

  @override
  String get storyShelfFullAgain => 'Tangkiné kebak maneh';

  @override
  String get storyIntroFly =>
      'Iki kapal lintangé Koba. Kapal iki mabur nganggo lintang!';

  @override
  String get storyIntroWind =>
      'Wuusss! Angin angkasa nyebul lintang saka tangkiné, menyang kabeh planet.';

  @override
  String get storyIntroLand => 'Lintangé entèk, dadi kapalé kudu mudhun.';

  @override
  String get storyIntroBump => 'Ups, ana watu! Ora apa-apa. Aku nyoba maneh!';

  @override
  String get storyIntroHelp =>
      'Ayo golèk lintangé bareng. Kowé gelem nulungi aku, Komandan?';

  @override
  String get storyFly =>
      'Tangkiku tambah lintang! Ayo menyang planet sabanjuré!';

  @override
  String get storyArrivalDirections =>
      'Kapalé mudhun ing planet sing kebak papan pitunjuk. Arahé menyang ngendi-endi!';

  @override
  String get storyArrivalDirectionsKoba =>
      'Aku kudu menyang endi? Tuduhna nganggo panah: maju, kiwa, utawa tengen!';

  @override
  String get storyArrivalSequencing =>
      'Ing kéné, lintangé ana ing sadawané dalan sing menggak-menggok.';

  @override
  String get storyArrivalSequencingKoba =>
      'Aku butuh kabeh langkahé urut, siji-siji!';

  @override
  String get storyArrivalLoops =>
      'Ing planet iki, dalané maju, menggok, maju, menggok, terus bola-bali.';

  @override
  String get storyArrivalLoopsKoba =>
      'Akèh banget langkahé! Ana dalan cepet, ora?';

  @override
  String get storyArrivalFunctions =>
      'Koba nemokaké blok ajaib sing gumebyar ing lemah.';

  @override
  String get storyArrivalFunctionsKoba =>
      'Blok iki bisa ngéling-éling obahku! Wulangen sepisan, banjur nganggo bola-bali.';

  @override
  String get storyArrivalConditions =>
      'Pedhut kandel nutupi planet iki. Koba ora bisa ndeleng dalané!';

  @override
  String get storyArrivalConditionsKoba =>
      'Aku nguripaké lampuku lan ndeleng ngarep sadurungé jumangkah.';

  @override
  String get storyArrivalVariables =>
      'Ing planet iki, Koba nemokaké kothak cilik sing ana angkané.';

  @override
  String get storyArrivalVariablesKoba =>
      'Kothak iki ngéling-éling angka! Angkané ngandhani pira langkahku.';

  @override
  String get storyArrivalDebugging =>
      'Ana sing ninggal blok ing dalan, kabeh kewolak-walik.';

  @override
  String get storyArrivalDebuggingKoba =>
      'Blok iki durung pas. Ayo golèk sing kudu dibénakaké!';

  @override
  String get storyArrivalUntil =>
      'Adoh, adoh banget, ana gendéra ing pucuké dalan sing dawa.';

  @override
  String get storyArrivalUntilKoba =>
      'Langkahé kakehan kanggo diétung! Aku mlaku terus waé nganti gendéra.';

  @override
  String get storyArrivalOtherwise =>
      'Dalané pecah dadi loro. Ing salah sijiné ana grumbul!';

  @override
  String get storyArrivalOtherwiseKoba =>
      'Yèn dalané kosong, aku maju. Yèn ora, aku menggok!';

  @override
  String get storyEnding =>
      'Lintang pungkasan mabur mulih. Tangkiné Koba kebak!';

  @override
  String get storyEndingKoba =>
      'Suwun, Komandan! Kowé nulungi aku nemokaké kabeh lintang.';

  @override
  String get storyEndingMore =>
      'Saiki awaké déwé bisa mabur menyang ngendi waé. Ayo terus dolanan bareng!';

  @override
  String get storyFullAgain => 'Lintang-lintang mabur mulih menyang tangki.';

  @override
  String get storyNewPlanet =>
      'Wuusss! Angin angkasa nyebul sawetara lintang saka tangki, menyang planet sing durung tau ditemokaké.';

  @override
  String get storyNewPlanetKoba =>
      'Planet anyar! Kowé gelem nulungi aku golèk lintang maneh, Komandan?';

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
      'Kebak maneh! Suwun wis mulang aku mbénakaké blok, Komandan!';

  @override
  String get storyThanksUntil =>
      'Kebak maneh! Suwun wis mulang aku mlaku nganti gendéra, Komandan!';

  @override
  String get storyThanksOtherwise =>
      'Kebak maneh! Suwun wis mulang aku apa sing ditindakaké yèn ora, Komandan!';

  @override
  String get watchHow => 'Deleng carané';

  @override
  String get tutorialDirections =>
      'Demok blok panah kanggo ngandhani aku kudu menyang endi: maju, menggok ngiwa, menggok nengen. Banjur pencet Mlaku!';

  @override
  String get tutorialSequencing =>
      'Tata langkahé urut, siji-siji, nganti tekan gendéra.';

  @override
  String get tutorialLoops =>
      'Langkahé padha terus? Lebokna ing blok baleni, banjur pilih ping pira!';

  @override
  String get tutorialFunctions =>
      'Gawé blok ajaibmu déwé ing baris lintang. Banjur nganggo lintangé bola-bali!';

  @override
  String get tutorialConditions =>
      'Blok mripat ndeleng ngarep. Yèn dalané kosong, aku maju. Yèn ora, aku ngenteni. Dadi blok sing padha kasil ing saben peta!';

  @override
  String get tutorialVariables =>
      'Simpen angka ing Kothak Langkah. Banjur nganggo langkah kanggo mlaku semono!';

  @override
  String get tutorialDebugging =>
      'Blok iki durung pas. Pencet Mlaku lan gatèkna. Banjur demok blok sing kudu dibénakaké, lan demok blok sing bener!';

  @override
  String get tutorialUntil =>
      'Baleni nganti gendéra terus mlaku déwé, dadi kowé ora perlu ngétung!';

  @override
  String get hintPattern =>
      'Blok-blok iki metu bola-bali. Coba nganggo blok baleni!';

  @override
  String get hintAgain =>
      'Demok lampu maneh kanggo ndeleng blok sing bola-bali!';

  @override
  String get hintLookHere =>
      'Delengen blok sing ana lampuné. Coba ganti blok kuwi!';

  @override
  String get hintLookHereMany =>
      'Delengen blok-blok sing ana lampuné. Coba ganti blok-blok kuwi!';

  @override
  String get turnMap => 'Puter peta';

  @override
  String boardNumber(int number) {
    return 'Peta $number';
  }

  @override
  String get tourPalette =>
      'Iki blok-blokmu. Demok siji, utawa sérét menyang programmu.';

  @override
  String get tourProgram =>
      'Programmu ana ing kéné. Aku nglakokaké bloké urut, saka sing kapisan. Demok blok kanggo ngganti.';

  @override
  String get tourGo => 'Pencet Mlaku, lan aku manut blok-blokmu!';

  @override
  String get tourStep =>
      'Tombol iki nglakokaké siji blok saben pisan, dadi kowé bisa ndeleng kanthi tliti.';

  @override
  String get tourReset => 'Sing iki nggawa aku bali menyang wiwitan.';

  @override
  String get tourHint =>
      'Bingung? Sawisé nyoba kaping pira-pira, lampuné murup. Saben didemok nuduhaké sithik engkas: kapisan dalané, banjur blok endi sing kudu diganti. Tandha cilik ing lampu nuduhaké apa sing sabanjuré.';

  @override
  String get tourFollow =>
      'Iki muter peta saprapat puteran saben pisan, dadi kowé bisa ndeleng saka sisihku.';

  @override
  String get tourBoards =>
      'Ing kéné ana sawetara peta. Demok titik kanggo ndeleng saben peta. Blokmu kudu nggawa aku tekan gendéra ing saben peta!';

  @override
  String get tourListen =>
      'Demok speaker kanggo ngrungokaké maneh apa sing kudu ditindakaké.';

  @override
  String get tourWarmUpListen =>
      'Rungokna pitakoné. Demok speaker kanggo ngrungokaké maneh.';

  @override
  String get tourWarmUpAnswer => 'Banjur demok gambar sing miturutmu bener!';

  @override
  String get tourWarmUpSteps =>
      'Tapak sikil nuduhaké wis tekan ngendi dolananmu.';

  @override
  String get tourBlockForward => 'Panah ijo nggawé aku maju sak langkah.';

  @override
  String get tourBlockTurnLeft =>
      'Panah biru nggawé aku menggok ngiwa, tanpa pindhah.';

  @override
  String get tourBlockTurnRight =>
      'Panah oranye nggawé aku menggok nengen, tanpa pindhah.';

  @override
  String get tourBlockRepeat =>
      'Blok baleni nglakokaké blok ing njeroné bola-bali. Demok min utawa plus kanggo milih ping pira.';

  @override
  String get tourBlockSetSteps =>
      'Kothak Langkah nyimpen cacahé langkah. Demok min utawa plus kanggo ngowahi.';

  @override
  String get tourBlockMoveSteps =>
      'Panah iki nggawé aku maju semono angka ing Kothak Langkah.';

  @override
  String get tourBlockIfPathClear =>
      'Blok mripat ndeleng ngarep. Blok ing njeroné mung mlaku yèn dalané kosong.';

  @override
  String get tourBlockIfElse =>
      'Blok mripat iki duwé rong baris: baris ndhuwur mlaku yèn dalané kosong, baris ngisor yèn ora.';

  @override
  String get tourBlockUntilGoal =>
      'Baleni nganti gendéra nglakokaké blok ing njeroné terus-terusan, nganti aku tekan gendéra.';

  @override
  String get tourBlockStar =>
      'Blok lintang nglakokaké blok ing baris lintangmu: blok ajaib gaweanmu déwé.';

  @override
  String get tourNext => 'Terus';

  @override
  String get tourDone => 'Mudheng!';

  @override
  String get tourHelp => 'Piyé carané?';

  @override
  String get breakTitle => 'Wayahé ngaso!';

  @override
  String get breakBody =>
      'Kowé wis dolanan kanthi hebat. Ngasokna mripatmu, coba ulet-ulet, banjur dolanan maneh mengko.';

  @override
  String get breakHome => 'Bali menyang pemain';

  @override
  String get breakContinue => 'Wong tuwa bisa nerusaké';

  @override
  String get breakVoice =>
      'Wayahé ngaso! Kowé wis dolanan kanthi hebat. Ngasokna mripatmu, coba ulet-ulet, banjur dolanan maneh mengko.';

  @override
  String get breakReminder => 'Pangéling ngaso';

  @override
  String get breakReminderHint =>
      'Sawisé dolanan teka-teki semene suwéné, bocah diajak ngaso. Mung wong tuwa sing bisa nerusaké.';

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
      other: 'Kari $count teka-teki engkas bisa nggawa kowé menyang $island!',
      one: 'Teka-teki sabanjuré bisa nggawa kowé menyang $island!',
    );
    return '$_temp0';
  }

  @override
  String get conceptWarmUp => 'Pemanasan';

  @override
  String get warmUpCounting => 'Ngétung';

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
  String get stickerNotYet => 'Durung éntuk';

  @override
  String get stickerGold => 'Kabeh lintang wis kumpul!';

  @override
  String get blockIfElse => 'Yèn kosong, yèn ora';

  @override
  String get otherwiseRowClear => 'Yèn dalané kosong';

  @override
  String get otherwiseRowBlocked => 'Yèn ora';

  @override
  String get conceptOtherwise => 'Yèn ora';

  @override
  String get playGoalOtherwise =>
      'Nganggo blok mripat sing rong baris: yèn dalané kosong, jumangkah. Yèn ora, menggok!';

  @override
  String get tutorialOtherwise =>
      'Mripat ndeleng ngarep. Yèn dalané kosong, jumangkah. Yèn ora, menggok. Banjur kabeh dibaleni nganti gendéra!';

  @override
  String starsEarned(int count) {
    return '$count saka 3 lintang';
  }
}
