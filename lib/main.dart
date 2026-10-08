import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import 'app/app.dart';
import 'core/audio/audio_service.dart';
import 'core/entitlement/entitlement_factory.dart';
import 'core/entitlement/unlock_code.dart';
import 'core/settings/settings_repository.dart';
import 'core/storage/app_database.dart';
import 'features/learning/data/curriculum_repository.dart';
import 'features/learning/data/progress_repository.dart';
import 'features/profiles/data/profile_repository.dart';
import 'package:cobalagi/features/splash/data/app_update_factory.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Compile the liquid glass shaders up front, so the first glass bar is
  // glass at once. If they can't load, the bars fall back to frosted glass.
  try {
    await LiquidGlassShaders.ensureLoaded();
  } on Object catch (_) {}
  final db = await openAppDatabase();
  final settings = SettingsRepository(db);
  final donations =
      jsonDecode(await rootBundle.loadString('assets/config/donations.json'))
          as Map<String, Object?>;
  runApp(
    CobaLagiApp(
      profiles: ProfileRepository(db),
      settings: settings,
      entitlement: createEntitlementService(
        productIds: {...(donations['products']! as List).cast<String>()},
        unlockCodes: UnlockCodes({
          ...(donations['unlock_code_sha256']! as List).cast<String>(),
        }),
        settings: settings,
      ),
      audio: AudioplayersAudioService(),
      curriculum: CurriculumRepository(),
      progress: ProgressRepository(db),
      updates: createAppUpdateService(),
    ),
  );
}
