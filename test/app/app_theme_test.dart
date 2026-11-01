import 'package:cobalagi/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('taps show no ripple, in light and dark', () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      expect(theme.splashFactory, NoSplash.splashFactory);
    }
  });
}
