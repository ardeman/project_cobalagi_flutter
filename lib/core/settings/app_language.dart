// Pure Dart, no Flutter imports: the voice tools (tool/) import it too.

/// A language the app speaks, named in its own words in the language picker.
///
/// Regional languages of Indonesia fall back to Indonesian wherever they have
/// nothing of their own: voice clips not recorded yet, and the system texts
/// Flutter's own widgets show (their tooltips and labels).
///
/// A language is offered (in the picker, or picked from the device's
/// language) only once it is [voiced]: every voice clip recorded in it.
enum AppLanguage {
  indonesian('id', 'Bahasa Indonesia'),
  acehnese('ace', 'Bahsa Acèh', fallback: 'id', voiced: false),
  minangkabau('min', 'Baso Minang', fallback: 'id', voiced: false),
  javanese('jv', 'Basa Jawa', fallback: 'id'),
  sundanese('su', 'Basa Sunda', fallback: 'id'),
  english('en', 'English');

  const AppLanguage(this.code, this.name, {this.fallback, this.voiced = true});

  final String code;

  /// The language's own name for itself, the same in every language.
  final String name;

  /// The language used where this one has nothing of its own.
  final String? fallback;

  /// Whether every voice clip is recorded in this language
  /// (`assets/audio/<code>/`), so it can be offered; a test keeps it true.
  final bool voiced;

  /// The languages children and parents can choose, in the picker's order.
  static List<AppLanguage> get offered => [
    for (final language in values)
      if (language.voiced) language,
  ];

  /// The language for [code], or null if the app doesn't speak it.
  static AppLanguage? of(String code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return null;
  }
}
