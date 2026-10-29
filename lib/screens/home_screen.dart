import 'package:flutter/material.dart';

import '../models/weather.dart';
import '../services/app_settings.dart';
import '../services/city_store.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../utils/format.dart';
import 'details_screen.dart';
import 'forecast_screen.dart';
import 'city_search_screen.dart';
import 'saved_cities_screen.dart';
import 'settings_screen.dart';
import '../widgets/sky_nav_bar.dart';
import 'weather_states_screen.dart';

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({this.service, this.location, super.key});

  final WeatherService? service;
  final LocationService? location;

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage>
    with SettingsListener<WeatherHomePage> {
  late final _service = widget.service ?? WeatherService();
  final _visitedTabs = <int>{AppNav.home};
  final _store = CityStore();
  late final _location = widget.location ?? LocationService();
  late String _city = CityStore.defaultCity;
  WeatherReport? _report;
  WeatherRequestState? _state = WeatherRequestState.loading;

  @override
  void initState() {
    super.initState();
    AppNav.tab.value = AppNav.home; // a new shell always starts on Home
    AppNav.tab.addListener(_onTabChanged);
    _init();
  }

  @override
  void dispose() {
    AppNav.tab.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  void _goHome() => AppNav.tab.value = AppNav.home;

  Future<void> _init() async {
    _city = await _store.loadCurrent();
    if (!mounted) return;
    if (AppSettings.instance.autoLocation) {
      try {
        // Silent refresh on every open; never shows the permission dialog.
        final query = await _location.currentQuery(allowPrompt: false);
        if (!mounted) return;
        await _load(query: query);
        return;
      } catch (_) {
        // Fall back to the last selected city.
      }
    }
    await _load();
  }

  /// Loads weather for [query] (defaults to the current city). On success the
  /// canonical city name becomes the current city, so a "lat,lon" query from
  /// the device location is stored as a readable name.
  Future<void> _load({String? query}) async {
    if (_report == null || _state != null) {
      setState(() => _state = WeatherRequestState.loading);
    }
    try {
      final report = await _service.fetchWeather(query ?? _city);
      if (!mounted) return;
      _city = report.query;
      _store.saveCurrent(report.query);
      setState(() {
        _report = report;
        _state = null;
      });
    } on WeatherException catch (error) {
      if (!mounted) return;
      setState(() {
        _state = switch (error.failure) {
          WeatherFailure.cityNotFound => WeatherRequestState.cityNotFound,
          WeatherFailure.network => WeatherRequestState.offline,
          WeatherFailure.server => WeatherRequestState.networkError,
        };
      });
    }
  }

  Future<void> _useLocation() async {
    try {
      final query = await _location.currentQuery();
      if (!mounted) return;
      await _load(query: query);
    } on LocationException catch (error) {
      if (!mounted) return;
      if (error.failure == LocationFailure.deniedForever) {
        await _location.openSettings();
        return;
      }
      if (_report == null) {
        setState(() => _state = WeatherRequestState.locationPermissionDenied);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _showSearch() async {
    final city = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => CitySearchScreen(service: _service)));
    if (city == null || !mounted) return;
    _store.addRecent(city);
    _load(query: city);
  }

  Widget _buildBody(BuildContext context) {
    final report = _report;
    final state = _state;
    if (report == null || state != null) {
      return SafeArea(
        child: WeatherStateView(
          state: state ?? WeatherRequestState.loading,
          hasCachedWeather: report != null,
          lastUpdated: report == null ? null : clock(report.localTime),
          cachedSummary: report == null
              ? null
              : '${report.city}  ·  ${degrees(report.tempC)}\n'
                    '${report.condition}'
                    '${report.today == null ? '' : '  ·  H ${degrees(report.today!.maxC)} / L ${degrees(report.today!.minC)}'}',
          onRetry: _load,
          onSearch: _showSearch,
          onEnableLocation: _useLocation,
        ),
      );
    }
    final hours = [
      for (var i = 0; i < report.hours.length && i < 24; i++)
        (
          i == 0 ? 'Now' : hourLabel(report.hours[i].time),
          degrees(report.hours[i].tempC),
          weatherIcon(report.hours[i].conditionCode, isDay: report.hours[i].isDay),
        ),
    ];
    final days = [
      for (var i = 0; i < report.days.length; i++)
        (
          i == 0
              ? 'Today'
              : i == 1
              ? 'Tomorrow'
              : '${weekdays[report.days[i].date.weekday - 1]}, '
                    '${report.days[i].date.day} ${months[report.days[i].date.month - 1]}',
          report.days[i].condition,
          degrees(report.days[i].minC),
          degrees(report.days[i].maxC),
          weatherIcon(report.days[i].conditionCode),
        ),
    ];
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth > 600 ? 32.0 : 20.0;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    18,
                    horizontalPadding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _TopBar(
                      location: '${report.city}, ${report.country}',
                      onSearch: _showSearch,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    24,
                    horizontalPadding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _HeroWeatherCard(
                      report: report,
                      onLocationTap: _useLocation,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    26,
                    horizontalPadding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _SectionHeading(
                      title: 'Today’s highlights',
                      action: 'See details',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DetailsScreen(report: report),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    14,
                    horizontalPadding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: constraints.maxWidth > 600 ? 2.8 : 1.65,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _HighlightCard(
                          label: 'Feels like',
                          value: degrees(report.feelsLikeC),
                          icon: Icons.thermostat_rounded,
                          color: const Color(0xFFFFA866),
                        ),
                        _HighlightCard(
                          label: 'Humidity',
                          value: '${report.humidity}%',
                          icon: Icons.water_drop_outlined,
                          color: const Color(0xFF63B8FF),
                        ),
                        _HighlightCard(
                          label: 'Wind speed',
                          value: wind(report.windKph),
                          icon: Icons.air_rounded,
                          color: const Color(0xFF6D82B6),
                        ),
                        _HighlightCard(
                          label: 'UV index',
                          value: report.uv.round().toString(),
                          icon: Icons.wb_sunny_outlined,
                          color: const Color(0xFFFFB84D),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    28,
                    horizontalPadding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _SectionHeading(title: 'Hourly forecast'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 126,
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        14,
                        horizontalPadding,
                        0,
                      ),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: hours.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final hour = hours[index];
                        return _HourlyCard(
                          time: hour.$1,
                          temperature: hour.$2,
                          icon: hour.$3,
                          isCurrent: index == 0,
                        );
                      },
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    28,
                    horizontalPadding,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _SectionHeading(title: '5-day forecast'),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    14,
                    horizontalPadding,
                    28,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _FiveDayForecast(days: days),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Tabs are built the first time they are opened and then kept alive.
  Widget _buildTabs(BuildContext context) {
    final selected = AppNav.tab.value;
    _visitedTabs.add(selected);
    Widget tab(int index, Widget Function() build) =>
        _visitedTabs.contains(index) ? build() : const SizedBox.shrink();
    return IndexedStack(
      index: selected,
      children: [
        _buildBody(context),
        tab(
          AppNav.forecast,
          () => _report == null
              ? _buildBody(context)
              : ForecastScreen(report: _report!, onBack: _goHome),
        ),
        tab(
          AppNav.saved,
          () => SavedCitiesScreen(
            currentCity: _city,
            service: _service,
            onBack: _goHome,
          ),
        ),
        tab(AppNav.settings, () => SettingsScreen(onBack: _goHome)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = AppNav.tab.value;
    return PopScope(
      canPop: selected == AppNav.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome();
      },
      child: Scaffold(
        body: _buildTabs(context),
        bottomNavigationBar: SkyNavigationBar(
          selectedIndex: selected,
          onSelected: (index) => AppNav.tab.value = index,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.location, required this.onSearch});

  final String location;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.cloud_rounded, color: Color(0xFF63B8FF), size: 25),
              Positioned(
                right: 7,
                top: 7,
                child: Icon(
                  Icons.wb_sunny_rounded,
                  color: Theme.of(context).cardColor,
                  size: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SkyCast',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF6D82B6),
                    size: 13,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      location,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6D82B6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _IconButton(icon: Icons.search_rounded, onTap: onSearch),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 22),
        ),
      ),
    );
  }
}

class _HeroWeatherCard extends StatelessWidget {
  const _HeroWeatherCard({required this.report, required this.onLocationTap});

  final WeatherReport report;
  final VoidCallback onLocationTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 245,
      padding: const EdgeInsets.fromLTRB(23, 21, 22, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF274A80), Color(0xFF559AD1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A2E6097),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            top: -40,
            child: Container(
              width: 190,
              height: 190,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1263B8FF),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xBFFFFFFF),
                    size: 13,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '${weekdaysLong[report.localTime.weekday - 1]}, '
                    '${report.localTime.day} '
                    '${months[report.localTime.month - 1].toUpperCase()} '
                    '${report.localTime.year}',
                    style: const TextStyle(
                      color: Color(0xD9FFFFFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onLocationTap,
                    child: Icon(
                      Icons.my_location_rounded,
                      color: Theme.of(context).cardColor,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                degrees(report.tempC),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 62,
                  height: 0.95,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -3,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 150,
                child: Text(
                  report.condition,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              if (report.today != null)
                Text(
                  'H ${degrees(report.today!.maxC)}  ·  L ${degrees(report.today!.minC)}',
                  style: const TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: Color(0xBFFFFFFF),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Local time  ${clock(report.localTime)}',
                    style: const TextStyle(
                      color: Color(0xD9FFFFFF),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Positioned(right: 13, top: 45, child: _WeatherIllustration()),
        ],
      ),
    );
  }
}

class _WeatherIllustration extends StatelessWidget {
  const _WeatherIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 142,
      height: 122,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 5,
            right: 15,
            child: Container(
              width: 67,
              height: 67,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFC96B),
                boxShadow: [
                  BoxShadow(color: Color(0x55FFD98F), blurRadius: 19),
                ],
              ),
              child: const Icon(
                Icons.wb_sunny_rounded,
                color: Color(0xFFFFE6A7),
                size: 31,
              ),
            ),
          ),
          Positioned(
            left: 3,
            bottom: 8,
            child: Container(
              width: 130,
              height: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFF5FBFF),
                borderRadius: BorderRadius.circular(38),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44638DB7),
                    blurRadius: 12,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: const Align(
                alignment: Alignment.topCenter,
                child: Icon(
                  Icons.cloud_rounded,
                  color: Color(0xFFE4F1FA),
                  size: 75,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.action, this.onTap});

  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (action != null)
          GestureDetector(
            onTap: onTap,
            child: const Text(
              'See details',
              style: TextStyle(
                color: Color(0xFF4D9BD8),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF8290A8), fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HourlyCard extends StatelessWidget {
  const _HourlyCard({
    required this.time,
    required this.temperature,
    required this.icon,
    required this.isCurrent,
  });

  final String time;
  final String temperature;
  final IconData icon;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final foreground = isCurrent ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return Container(
      width: 67,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFF5BA9E8) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: isCurrent ? Colors.transparent : Theme.of(context).dividerColor,
        ),
        boxShadow: isCurrent
            ? const [
                BoxShadow(
                  color: Color(0x315BA9E8),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            time,
            style: TextStyle(
              color: isCurrent
                  ? const Color(0xE6FFFFFF)
                  : const Color(0xFF8290A8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Icon(
            icon,
            color: isCurrent
                ? const Color(0xFFFFD477)
                : const Color(0xFF63B8FF),
            size: 24,
          ),
          Text(
            temperature,
            style: TextStyle(
              color: foreground,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FiveDayForecast extends StatelessWidget {
  const _FiveDayForecast({required this.days});

  final List<(String, String, String, String, IconData)> days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          for (var index = 0; index < days.length; index++) ...[
            _ForecastRow(
              day: days[index].$1,
              condition: days[index].$2,
              low: days[index].$3,
              high: days[index].$4,
              icon: days[index].$5,
            ),
            if (index != days.length - 1)
              Divider(height: 1, color: Theme.of(context).dividerColor),
          ],
        ],
      ),
    );
  }
}

class _ForecastRow extends StatelessWidget {
  const _ForecastRow({
    required this.day,
    required this.condition,
    required this.low,
    required this.high,
    required this.icon,
  });

  final String day;
  final String condition;
  final String low;
  final String high;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: Row(
        children: [
          SizedBox(
            width: 83,
            child: Text(
              day,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(icon, color: const Color(0xFF63B8FF), size: 23),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              condition,
              style: const TextStyle(color: Color(0xFF8290A8), fontSize: 12),
            ),
          ),
          Text(
            low,
            style: const TextStyle(
              color: Color(0xFF8290A8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 13),
          Text(
            high,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
