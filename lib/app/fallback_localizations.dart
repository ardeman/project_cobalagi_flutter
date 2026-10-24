import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/settings/app_language.dart';
import 'l10n/app_localizations.dart';

/// The app's texts, then Flutter's own, with a fallback for regional languages.
const appLocalizationsDelegates = <LocalizationsDelegate<Object?>>[
  ...AppLocalizations.localizationsDelegates,
  ...FallbackLocalizationsDelegate.all,
];

/// Flutter's own widget texts (tooltips, the back button's label) exist only
/// for widely used languages, so a regional language loads its fallback's.
class FallbackLocalizationsDelegate<T> extends LocalizationsDelegate<T> {
  const FallbackLocalizationsDelegate(this._delegate);

  final LocalizationsDelegate<T> _delegate;

  static const all = <LocalizationsDelegate<Object?>>[
    FallbackLocalizationsDelegate<MaterialLocalizations>(
      GlobalMaterialLocalizations.delegate,
    ),
    FallbackLocalizationsDelegate<CupertinoLocalizations>(
      GlobalCupertinoLocalizations.delegate,
    ),
    FallbackLocalizationsDelegate<WidgetsLocalizations>(
      GlobalWidgetsLocalizations.delegate,
    ),
  ];

  static String? _fallbackOf(Locale locale) =>
      AppLanguage.of(locale.languageCode)?.fallback;

  @override
  bool isSupported(Locale locale) =>
      !_delegate.isSupported(locale) && _fallbackOf(locale) != null;

  @override
  Future<T> load(Locale locale) => _delegate.load(Locale(_fallbackOf(locale)!));

  @override
  bool shouldReload(FallbackLocalizationsDelegate<T> old) => false;
}
