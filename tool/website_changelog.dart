// Writes website/changelog.html, and the newest release's card on the home
// page, from store/releases.json and the release notes in
// store/changelogs/<locale>/, so the website never keeps its own copy of
// them. Run from the project root after bumping the version:
//   dart run tool/website_changelog.dart
// test/store/website_changelog_test.dart fails while either page is stale.
import 'dart:convert';
import 'dart:io';

const pagePath = 'website/changelog.html';
const homePath = 'website/index.html';

const _latestStart =
    '        <!-- Newest release, written by tool/website_changelog.dart. -->\n';
const _latestEnd = '        <!-- /Newest release -->\n';

const _monthsId = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', //
  'Agustus', 'September', 'Oktober', 'November', 'Desember',
];
const _monthsEn = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', //
  'August', 'September', 'October', 'November', 'December',
];

String _escape(String s) => const HtmlEscape(HtmlEscapeMode.element).convert(s);
String _attr(String s) => const HtmlEscape(HtmlEscapeMode.attribute).convert(s);

/// A release note: "- " or "• " lines become a list, other lines paragraphs.
List<(bool, String)> _notes(String text) => [
  for (final line in const LineSplitter().convert(text))
    if (line.trim().isNotEmpty)
      switch (line.trim()) {
        final l when l.startsWith('- ') || l.startsWith('• ') => (
          true,
          l.substring(2).trim(),
        ),
        final l => (false, l),
      },
];

/// Indonesian in the HTML, English in data-en, as on the rest of the site.
String _bilingual(List<(bool, String)> id, List<(bool, String)> en) {
  if (id.length != en.length) {
    throw StateError('Release notes differ in length between id and en-US');
  }
  final out = StringBuffer();
  var inList = false;
  for (var i = 0; i < id.length; i++) {
    final (item, idText) = id[i];
    final enText = en[i].$2;
    if (item && !inList) out.writeln('          <ul>');
    if (!item && inList) out.writeln('          </ul>');
    inList = item;
    final tag = item ? 'li' : 'p';
    out.writeln(
      '${item ? '            ' : '          '}<$tag data-en="${_attr(enText)}">'
      '${_escape(idText)}</$tag>',
    );
  }
  if (inList) out.writeln('          </ul>');
  return out.toString();
}

/// The site's shared header, taken from the privacy page so every page
/// has the same menu.
String _header(String root) {
  final privacy = File('$root/website/privacy.html').readAsStringSync();
  final start = privacy.indexOf('  <header>\n');
  final end = privacy.indexOf('  </header>\n') + '  </header>\n'.length;
  return privacy.substring(start, end);
}

/// The site's shared footer, also taken from the privacy page.
String _footer(String root) {
  final privacy = File('$root/website/privacy.html').readAsStringSync();
  final start = privacy.indexOf('  <footer>\n');
  final end = privacy.indexOf('  </footer>\n') + '  </footer>\n'.length;
  return privacy.substring(start, end);
}

List<Map<String, dynamic>> _releases(String root) =>
    ((jsonDecode(File('$root/store/releases.json').readAsStringSync())
                as Map<String, dynamic>)['releases']
            as List)
        .cast<Map<String, dynamic>>();

String _body(String root, int build) {
  String notes(String locale) =>
      File('$root/store/changelogs/$locale/$build.txt').readAsStringSync();
  return _bilingual(_notes(notes('id')), _notes(notes('en-US')));
}

String _time(Map<String, dynamic> r) {
  final date = DateTime.parse(r['date'] as String);
  final dateId = '${date.day} ${_monthsId[date.month - 1]} ${date.year}';
  final dateEn = '${date.day} ${_monthsEn[date.month - 1]} ${date.year}';
  return '<time datetime="${r['date']}" data-en="$dateEn">$dateId</time>';
}

String buildChangelogPage({String root = '.'}) {
  final releases = _releases(root);
  // Test uploads of one release share its version name: one card each,
  // newest build first, so the page doesn't grow with every retry.
  final versions = <List<Map<String, dynamic>>>[];
  for (final release in releases.reversed) {
    if (versions.isNotEmpty &&
        versions.last.first['version'] == release['version']) {
      versions.last.add(release);
    } else {
      versions.add([release]);
    }
  }
  String body(int build) => _body(root, build);

  final entries = StringBuffer();
  for (final builds in versions) {
    final version = builds.first['version'] as String;
    final newest = entries.isEmpty
        ? '<span class="newest" data-en="Newest">Terbaru</span> '
        : '';
    if (builds.length == 1) {
      final r = builds.single;
      final build = r['build'] as int;
      entries.write('''
        <article class="release" id="build-$build">
          <h2>$newest$version <span class="build" data-en="build $build">build $build</span></h2>
          <p class="updated">${_time(r)}</p>
${body(build)}        </article>
''');
      continue;
    }
    final range = '${builds.last['build']}–${builds.first['build']}';
    entries.write('''
        <article class="release">
          <h2>$newest$version <span class="build" data-en="builds $range">build $range</span></h2>
''');
    for (final r in builds) {
      final build = r['build'] as int;
      entries.write('''
          <section class="release-build" id="build-$build">
          <h3><span class="build" data-en="build $build">build $build</span> ${_time(r)}</h3>
${body(build)}          </section>
''');
    }
    entries.write('        </article>\n');
  }
  return '''
<!doctype html>
<!-- Generated by tool/website_changelog.dart from store/; do not edit. -->
<html lang="id">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title data-en="What's new · Coba Lagi">Yang baru · Coba Lagi</title>
  <meta name="description" content="Catatan rilis Coba Lagi: apa yang berubah di setiap versi.">
  <meta name="theme-color" content="#0b0f2c">
  <link rel="icon" href="icon.png">
  <link rel="stylesheet" href="site.css">
</head>
<body>
${_header(root)}
  <main>
    <div class="wrap page-head">
      <h1 data-en="What's new">Yang baru</h1>
      <p class="updated" data-en="What changed in each version of Coba Lagi. The newest is at the top.">Apa yang berubah di setiap versi Coba Lagi. Yang terbaru ada di paling atas.</p>
    </div>
    <div class="sheet">
      <div class="wrap doc releases">
${entries.toString().trimRight()}
      </div>
    </div>
  </main>

${_footer(root)}
  <script src="site.js"></script>
</body>
</html>
''';
}

/// The home page with its newest-release card (between the markers in the
/// download section) rewritten from the newest build's notes.
String buildHomePage({String root = '.'}) {
  final home = File('$root/$homePath').readAsStringSync();
  final start = home.indexOf(_latestStart);
  final end = home.indexOf(_latestEnd);
  if (start < 0 || end < start) {
    throw StateError('$homePath has no newest-release markers');
  }
  final r = _releases(root).last;
  final build = r['build'] as int;
  final card =
      '''
        <article class="latest">
          <h3><span class="newest" data-en="What's new">Yang baru</span> ${r['version']} ${_time(r)}</h3>
${_body(root, build)}          <a href="changelog.html#build-$build" data-keep-lang data-en="All release notes">Semua catatan rilis</a>
        </article>
''';
  return home.substring(0, start + _latestStart.length) +
      card +
      home.substring(end);
}

void main() {
  File(pagePath).writeAsStringSync(buildChangelogPage());
  stdout.writeln('Wrote $pagePath');
  File(homePath).writeAsStringSync(buildHomePage());
  stdout.writeln('Wrote the newest release on $homePath');
}
