import 'dart:convert';
import 'dart:io';

import 'package:cobalagi/features/play/view/world/world_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every island has its own world', () {
    final concepts = [
      for (final concept
          in (jsonDecode(File('assets/config/skills.json').readAsStringSync())
                  as Map<String, dynamic>)['concepts']
              as List)
        (concept as Map<String, dynamic>)['id'] as String,
    ];
    final themes = [for (final c in concepts) WorldTheme.forConcept(c)];
    // A new island needs a world of its own, not the meadow fallback.
    expect(themes.toSet(), hasLength(concepts.length));
    expect({for (final t in themes) t.obstacle}, hasLength(concepts.length));
    expect({for (final t in themes) t.finish}, hasLength(concepts.length));
  });
}
