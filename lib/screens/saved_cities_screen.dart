import 'package:flutter/material.dart';

import '../models/weather.dart';
import '../services/app_settings.dart';
import '../services/city_store.dart';
import '../services/weather_service.dart';
import '../utils/format.dart';
import 'city_search_screen.dart';
import 'forecast_screen.dart';

class SavedCitiesScreen extends StatefulWidget {
  const SavedCitiesScreen({
    required this.currentCity,
    this.service,
    this.onBack,
    super.key,
  });

  /// The city shown on the home screen; it is highlighted and saved by default.
  final String currentCity;
  final WeatherService? service;

  /// Returns to Home when shown as a tab; null pops the route.
  final VoidCallback? onBack;

  @override
  State<SavedCitiesScreen> createState() => _SavedCitiesScreenState();
}

class _SavedCitiesScreenState extends State<SavedCitiesScreen>
    with SettingsListener<SavedCitiesScreen> {
  late final _service = widget.service ?? WeatherService();
  final _store = CityStore();
  final List<String> _names = [];
  final Map<String, WeatherReport> _reports = {};
  final Set<String> _failed = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final saved = await _store.loadSaved();
    if (!mounted) return;
    setState(() {
      _names.addAll(saved ?? [widget.currentCity]);
      _loaded = true;
    });
    if (saved == null) await _store.saveSaved(_names);
    await _refresh();
  }

  Future<void> _refresh() => Future.wait([for (final n in _names) _fetch(n)]);

  Future<void> _fetch(String name) async {
    setState(() => _failed.remove(name));
    try {
      final report = await _service.fetchWeather(name);
      if (!mounted) return;
      setState(() => _reports[name] = report);
    } on WeatherException {
      if (!mounted) return;
      setState(() => _failed.add(name));
    }
  }

  Future<void> _addCity() async {
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => CitySearchScreen(service: _service)),
    );
    if (picked == null || !mounted) return;
    var city = picked;
    if (isCoordinates(city)) {
      // Device location: resolve to a city name before saving.
      try {
        final report = await _service.fetchWeather(city);
        city = report.query;
        _reports[city] = report;
      } on WeatherException {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load your location.')),
        );
        return;
      }
      if (!mounted) return;
    }
    if (_names.any((name) => name.toLowerCase() == city.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$city is already saved')),
      );
      return;
    }
    setState(() => _names.add(city));
    await _store.saveSaved(_names);
    await _fetch(city);
  }

  void _removeCity(String name) {
    final index = _names.indexOf(name);
    setState(() => _names.remove(name));
    _store.saveSaved(_names);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name removed from saved cities'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => _names.insert(index, name));
            _store.saveSaved(_names);
          },
        ),
      ),
    );
  }

  void _openCity(String name) {
    final report = _reports[name];
    if (report == null) {
      _fetch(name);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ForecastScreen(report: report)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Saved Cities',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        titleSpacing: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _addCity,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add City'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF63B8FF),
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : _names.isEmpty
            ? const _SavedEmptyState()
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                  children: [
                    const Text(
                      'Your locations',
                      style: TextStyle(
                        color: Color(0xFF8290A8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 13),
                    ..._names.map(
                      (name) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SavedCityCard(
                          name: name,
                          report: _reports[name],
                          failed: _failed.contains(name),
                          isCurrent:
                              name.toLowerCase() ==
                              widget.currentCity.toLowerCase(),
                          onTap: () => _openCity(name),
                          onRemove: () => _removeCity(name),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pull down to refresh live weather.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF9AA8BA), fontSize: 11),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SavedCityCard extends StatelessWidget {
  const _SavedCityCard({
    required this.name,
    required this.report,
    required this.failed,
    required this.isCurrent,
    required this.onTap,
    required this.onRemove,
  });

  final String name;
  final WeatherReport? report;
  final bool failed;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final report = this.report;
    final today = report?.today;
    final subtitle = report != null
        ? report.country
        : failed
        ? 'Unable to load'
        : 'Loading...';
    final detail = report == null
        ? (failed ? 'Tap to retry' : '')
        : '${report.condition}'
              '${today == null ? '' : '  ·  H ${degrees(today.maxC)} / L ${degrees(today.minC)}'}';
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.fromLTRB(17, 16, 10, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: isCurrent
                  ? const Color(0xFF63B8FF)
                  : Theme.of(context).dividerColor,
              width: isCurrent ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D1D4770),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isCurrent
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  report == null
                      ? (failed
                            ? Icons.cloud_off_rounded
                            : Icons.cloud_queue_rounded)
                      : weatherIcon(report.conditionCode, isDay: report.isDay),
                  color: const Color(0xFF63B8FF),
                  size: 28,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Text(
                              'Current',
                              style: TextStyle(
                                color: Color(0xFF357CA9),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8290A8),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      detail,
                      style: const TextStyle(
                        color: Color(0xFF647A9B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    tooltip: 'City options',
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: Color(0xFF8290A8),
                    ),
                    onSelected: (value) {
                      if (value == 'remove') onRemove();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'remove',
                        child: Text('Remove city'),
                      ),
                    ],
                  ),
                  if (report != null)
                    Text(
                      degrees(report.tempC),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 25,
                        fontWeight: FontWeight.w300,
                      ),
                    )
                  else if (!failed)
                    const Padding(
                      padding: EdgeInsets.only(right: 12, top: 6),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedEmptyState extends StatelessWidget {
  const _SavedEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: Color(0xFFE7F4FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                color: Color(0xFF63B8FF),
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No saved cities yet',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a city to quickly check its weather forecast here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8290A8),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
