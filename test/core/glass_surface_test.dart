import 'package:cobalagi/app/theme/app_theme.dart';
import 'package:cobalagi/core/widgets/glass_background.dart';
import 'package:cobalagi/core/widgets/glass_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'glass buttons keep keyboard access and disabled state ($dark)',
      (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            builder: (context, child) => GlassBackground(child: child!),
            home: Scaffold(
              body: Center(
                child: GlassSurface(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton(
                        onPressed: () => taps++,
                        child: const Text('Active'),
                      ),
                      const FilledButton(
                        onPressed: null,
                        child: Text('Disabled'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.byType(BackdropFilter), findsOneWidget);
        final button = tester.getSize(
          find.widgetWithText(FilledButton, 'Active'),
        );
        expect(button.height, greaterThanOrEqualTo(64));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(taps, 1);
        await tester.tap(find.text('Disabled'));
        expect(taps, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'high contrast replaces frosted glass with opaque colour ($dark)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark() : AppTheme.light(),
            home: const MediaQuery(
              data: MediaQueryData(highContrast: true),
              child: Scaffold(body: GlassSurface(child: Text('Readable'))),
            ),
          ),
        );
        expect(find.byType(BackdropFilter), findsNothing);
        final decorations = tester.widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(GlassSurface),
            matching: find.byType(DecoratedBox),
          ),
        );
        final panel = decorations
            .map((d) => d.decoration)
            .whereType<BoxDecoration>()
            .singleWhere((d) => d.gradient != null);
        expect(panel.gradient!.colors.every((color) => color.a == 1), isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
