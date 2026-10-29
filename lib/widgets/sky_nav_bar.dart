import 'package:flutter/material.dart';

/// App-wide bottom-navigation state. The home screen is the shell that hosts
/// the four tabs; pages pushed on top of it use [go] to jump to a tab.
class AppNav {
  static const home = 0;
  static const forecast = 1;
  static const saved = 2;
  static const settings = 3;

  static final tab = ValueNotifier<int>(home);

  /// Selects [index] and pops back to the shell.
  static void go(BuildContext context, int index) {
    tab.value = index;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class SkyNavigationBar extends StatelessWidget {
  const SkyNavigationBar({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).navigationBarTheme;
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      height: 76,
      backgroundColor: theme.backgroundColor,
      indicatorColor: theme.indicatorColor,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart_rounded),
          label: 'Forecast',
        ),
        NavigationDestination(
          icon: Icon(Icons.bookmark_border_rounded),
          selectedIcon: Icon(Icons.bookmark_rounded),
          label: 'Saved',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
    );
  }
}
