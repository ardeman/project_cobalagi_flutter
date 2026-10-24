/// A language the app speaks, named in its own words in the language picker.
///
/// Regional languages of Indonesia fall back to Indonesian wherever they have
/// nothing of their own: voice clips not recorded yet, and the system texts
/// Flutter's own widgets show (their tooltips and labels).
enum AppLanguage {
  indonesian('id', 'Bahasa Indonesia'),
  acehnese('ace', 'Bahsa Acèh', fallback: 'id'),
  minangkabau('min', 'Baso Minang', fallback: 'id'),
  english('en', 'English');

  const AppLanguage(this.code, this.name, {this.fallback});

  final String code;

  /// The language's own name for itself, the same in every language.
  final String name;

  /// The language used where this one has nothing of its own.
  final String? fallback;

  /// The language for [code], or null if the app doesn't speak it.
  static AppLanguage? of(String code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return null;
  }
}
