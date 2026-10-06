import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/l10n/app_localizations.dart';

/// "App version 1.0.0 (3)": the installed version and build, so testers can
/// say which one they use.
class AppVersionText extends StatefulWidget {
  const AppVersionText({super.key, this.style});

  final TextStyle? style;

  @override
  State<AppVersionText> createState() => _AppVersionTextState();
}

class _AppVersionTextState extends State<AppVersionText> {
  final _info = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder(
      future: _info,
      builder: (context, snapshot) {
        final info = snapshot.data;
        return Text(
          info == null ? '' : l10n.appVersion(info.version, info.buildNumber),
          textAlign: TextAlign.center,
          style: widget.style ?? Theme.of(context).textTheme.bodySmall,
        );
      },
    );
  }
}
