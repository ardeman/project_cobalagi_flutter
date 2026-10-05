import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/audio/audio_service.dart';
import 'core/entitlement/entitlement_service.dart';
import 'core/entitlement/plan.dart';
import 'core/settings/settings_repository.dart';
import 'core/storage/app_database.dart';
import 'features/learning/data/curriculum_repository.dart';
import 'features/learning/data/progress_repository.dart';
import 'features/profiles/data/profile_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await openAppDatabase();
  runApp(
    CobaLagiApp(
      profiles: ProfileRepository(db),
      settings: SettingsRepository(db),
      // Replaced by store billing in Phase 5.
      entitlement: const StaticEntitlementService(Plan.free),
      audio: AudioplayersAudioService(),
      curriculum: CurriculumRepository(),
      progress: ProgressRepository(db),
    ),
  );
}
