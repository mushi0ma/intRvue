import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/settings_repository.dart';
import 'settings_screen.dart';

/// «Көрініс пен тіл»: интерфейс тілі және жарық/қараңғы тақырып.
class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  late final _settings = context.read<SettingsRepository>();
  late ThemeMode _mode = _settings.themeMode;
  late InterfaceLanguage _language = _settings.language;
  late bool _systemColors = _settings.systemColors;

  Future<void> _save() async {
    await _settings.setAppearance(
      _mode,
      _language,
      systemColors: _systemColors,
    );
    if (!mounted) return;
    showAppSnackBar(context, S.appearanceSaved);
    context.popOr(Routes.settings);
  }

  @override
  Widget build(BuildContext context) {
    final label = context.text.bodyLarge!.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    return AppPage(
      showBack: true,
      title: S.appearanceTitle,
      subtitle: S.appearanceSubtitle,
      headerGap: 40,
      body: [
        Text(S.interfaceLanguage, style: label),
        const SizedBox(height: 16),
        ChoiceGroup<InterfaceLanguage>(
          values: InterfaceLanguage.values,
          selected: _language,
          labelOf: (l) => l.label,
          onChanged: (l) {
            setState(() => _language = l);
          },
        ),
        const SizedBox(height: 32),
        Text(S.theme, style: label),
        const SizedBox(height: 16),
        ChoiceGroup<ThemeMode>(
          columns: 1,
          values: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
          selected: _mode,
          labelOf: SettingsScreen.themeLabel,
          onChanged: (m) => setState(() => _mode = m),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(S.systemColors, style: context.text.titleSmall),
          subtitle: Text(
            S.systemColorsHint,
            style: label.copyWith(fontSize: 14),
          ),
          value: _systemColors,
          onChanged: (v) => setState(() => _systemColors = v),
        ),
        const SizedBox(height: 24),
        Text(S.appearanceNote, style: label),
      ],
      actions: [AppButton(label: S.save, onPressed: _save)],
    );
  }
}
