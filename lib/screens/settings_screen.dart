import 'package:flutter/material.dart';

import '../app.dart';
import '../services/app_settings.dart';
import '../services/location_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({this.onBack, super.key});

  /// Returns to Home when shown as a tab; null pops the route.
  final VoidCallback? onBack;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final ValueNotifier<ThemeMode> _themeMode;
  late final bool _ownsThemeMode;
  final _settings = AppSettings.instance;

  @override
  void initState() {
    super.initState();
    final sharedThemeMode = AppThemeScope.maybeOf(context);
    if (sharedThemeMode == null) {
      _themeMode = ValueNotifier(ThemeMode.system);
      _ownsThemeMode = true;
    } else {
      _themeMode = sharedThemeMode;
      _ownsThemeMode = false;
    }
  }

  @override
  void dispose() {
    if (_ownsThemeMode) _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        titleSpacing: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
        children: [
          _SettingsSection(
            title: 'Appearance',
            children: [
              _ThemeSelector(
                selected: _themeMode.value,
                onChanged: (mode) {
                  _themeMode.value = mode;
                  setState(() {});
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'Weather preferences',
            children: [
              _ChoiceRow(
                icon: Icons.thermostat_rounded,
                title: 'Temperature units',
                subtitle: 'Choose how temperature is displayed',
                value: _settings.temperatureUnit,
                options: const ['°C', '°F'],
                onChanged: (value) {
                  _settings.setFahrenheit(value == '°F');
                  setState(() {});
                },
              ),
              _ChoiceRow(
                icon: Icons.air_rounded,
                title: 'Wind speed units',
                subtitle: 'Choose your preferred wind speed',
                value: _settings.windUnit,
                options: const ['km/h', 'mph'],
                onChanged: (value) {
                  _settings.setMph(value == 'mph');
                  setState(() {});
                },
              ),
              _ChoiceRow(
                icon: Icons.water_drop_outlined,
                title: 'Precipitation',
                subtitle: 'Display rainfall measurements in',
                value: _settings.precipitationUnit,
                options: const ['mm', 'in'],
                onChanged: (value) {
                  _settings.setInches(value == 'in');
                  setState(() {});
                },
              ),
              _SwitchRow(
                icon: Icons.location_on_outlined,
                title: 'Automatic location',
                subtitle: _settings.autoLocation
                    ? 'Using your current location on launch'
                    : 'Using the city you selected',
                value: _settings.autoLocation,
                onChanged: (value) {
                  _settings.setAutoLocation(value);
                  // Turning it on is the moment to ask for access if needed.
                  if (value) _requestLocationAccess();
                  setState(() {});
                },
              ),
            ],
          ),
          _SettingsSection(
            title: 'Application',
            children: [
              _InfoRow(
                icon: Icons.auto_awesome_rounded,
                title: 'About SkyCast',
                onTap: () => _showInfo(
                  context,
                  'About SkyCast',
                  'SkyCast shows current conditions, an hourly outlook and a '
                      '5-day forecast for your location or any city you save.',
                ),
              ),
              _InfoRow(
                icon: Icons.cloud_outlined,
                title: 'Weather data provider',
                subtitle: 'Powered by WeatherAPI.com',
                onTap: () => _showInfo(
                  context,
                  'Weather data provider',
                  'Forecasts, current conditions and city search are provided '
                      'by WeatherAPI.com (weatherapi.com). Data accuracy and '
                      'availability depend on that service.',
                ),
              ),
              _InfoRow(
                icon: Icons.lock_outline_rounded,
                title: 'Privacy Policy',
                onTap: () => _showInfo(
                  context,
                  'Privacy Policy',
                  'SkyCast uses your device location only to look up local '
                      'weather, and only when Automatic location is on or you '
                      'tap the location button. Coordinates and the cities you '
                      'search for are sent to WeatherAPI.com to fetch '
                      'forecasts. Your settings, saved cities and recent '
                      'searches are stored on this device only. SkyCast has no '
                      'account system and does not collect analytics.',
                ),
              ),
              const _InfoRow(
                icon: Icons.info_outline_rounded,
                title: 'App version',
                subtitle: 'SkyCast 1.0.0',
              ),
            ],
          ),
          if (dark)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Dark theme is applied across the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF91A9C6), fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _requestLocationAccess() async {
    try {
      await LocationService().currentQuery();
    } on LocationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _showInfo(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF63B8FF),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.65),
              ),
            ),
            child: Column(
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  children[index],
                  if (index != children.length - 1)
                    Divider(
                      height: 1,
                      indent: 58,
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.55),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.selected, required this.onChanged});

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    const choices = [
      (ThemeMode.light, 'Light Theme', Icons.light_mode_outlined),
      (ThemeMode.dark, 'Dark Theme', Icons.dark_mode_outlined),
      (ThemeMode.system, 'System Default', Icons.settings_suggest_outlined),
    ];
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          for (var index = 0; index < choices.length; index++) ...[
            Expanded(
              child: _ThemeChoice(
                label: choices[index].$2,
                icon: choices[index].$3,
                selected: selected == choices[index].$1,
                onTap: () => onChanged(choices[index].$1),
              ),
            ),
            if (index != choices.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 75,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected
              ? (dark ? const Color(0xFF1C3A5E) : const Color(0xFFE4F2FF))
              : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? const Color(0xFF63B8FF)
                : Theme.of(context).dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? (dark ? const Color(0xFF63B8FF) : const Color(0xFF357CA9))
                  : (dark ? const Color(0xFFC3D0E3) : Theme.of(context).hintColor),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected
                    ? (dark ? Colors.white : const Color(0xFF101B36))
                    : onSurface,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          _LeadingIcon(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: _RowText(title: title, subtitle: subtitle),
          ),
          SegmentedButton<String>(
            segments: [
              for (final option in options)
                ButtonSegment(value: option, label: Text(option)),
            ],
            selected: {value},
            onSelectionChanged: (selection) => onChanged(selection.first),
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? const Color(0xFF63B8FF)
                    : null,
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? const Color(0xFF101B36)
                    : Theme.of(context).colorScheme.onSurface,
              ),
              side: WidgetStatePropertyAll(
                BorderSide(color: Theme.of(context).dividerColor),
              ),
              textStyle: const WidgetStatePropertyAll(
                TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
      child: Row(
        children: [
          _LeadingIcon(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: _RowText(title: title, subtitle: subtitle),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      leading: _LeadingIcon(icon: icon),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: const TextStyle(fontSize: 10)),
      trailing: onTap == null
          ? null
          : const Icon(Icons.chevron_right_rounded, size: 20),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: const Color(0xFF4D9BD8), size: 18),
    );
  }
}

class _RowText extends StatelessWidget {
  const _RowText({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 10),
        ),
      ],
    );
  }
}
