import 'package:cobalagi/app/l10n/app_localizations.dart';
import 'package:cobalagi/core/settings/app_language.dart';
import 'package:cobalagi/core/settings/settings_cubit.dart';
import 'package:cobalagi/core/widgets/glass_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The Parent area's language dropdown: the device's language, then the
/// national languages (Bahasa Indonesia, English), then, below a line, the
/// regional languages of Indonesia. The field and its menu are glass panels.
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});

  /// The menu's value for "Same as device" (the setting itself is null).
  static const _system = '';

  static const _radius = 20.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final code = context.watch<SettingsCubit>().state?.languageCode;
    final offered = AppLanguage.offered;
    final groups = [
      [(_system, l10n.languageSystem)],
      for (final regional in [false, true])
        [
          for (final language in offered)
            if ((language.fallback != null) == regional)
              (language.code, language.name),
        ],
    ].where((group) => group.isNotEmpty).toList();
    final value = code ?? _system;
    final selected = AppLanguage.of(value)?.name ?? l10n.languageSystem;

    return LayoutBuilder(
      builder: (context, constraints) => PopupMenuButton<String>(
        tooltip: l10n.language,
        initialValue: value,
        position: PopupMenuPosition.under,
        offset: const Offset(0, 8),
        // The glass panel is the menu's only entry; the menu's own Material
        // stays invisible so the blur shows through.
        color: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        menuPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(_radius)),
        ),
        clipBehavior: Clip.antiAlias,
        constraints: BoxConstraints.tightFor(width: constraints.maxWidth),
        onSelected: (value) => context.read<SettingsCubit>().setLanguageCode(
          value == _system ? null : value,
        ),
        itemBuilder: (context) => [
          _GlassMenu(groups: groups, selected: value, radius: _radius),
        ],
        child: GlassSurface(
          radius: _radius,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                const Icon(Icons.translate_rounded),
                const SizedBox(width: 16),
                Expanded(child: Text(selected)),
                const Icon(Icons.expand_more_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Every option on one glass panel, groups split by a line.
class _GlassMenu extends PopupMenuEntry<String> {
  const _GlassMenu({
    required this.groups,
    required this.selected,
    required this.radius,
  });

  final List<List<(String, String)>> groups;
  final String selected;
  final double radius;

  @override
  double get height =>
      groups.fold(16, (sum, group) => sum + group.length * 64) +
      (groups.length - 1) * 17;

  @override
  bool represents(String? value) =>
      groups.any((group) => group.any((option) => option.$1 == value));

  @override
  State<_GlassMenu> createState() => _GlassMenuState();
}

class _GlassMenuState extends State<_GlassMenu> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassSurface(
      radius: widget.radius,
      shadow: false,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, group) in widget.groups.indexed) ...[
            if (index > 0) const Divider(height: 17, indent: 20, endIndent: 20),
            for (final (value, name) in group)
              InkWell(
                autofocus: value == widget.selected,
                onTap: () => Navigator.pop(context, value),
                child: SizedBox(
                  height: 64,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(child: Text(name)),
                        if (value == widget.selected)
                          Icon(Icons.check_rounded, color: colors.primary),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
