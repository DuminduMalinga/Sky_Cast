import 'package:flutter/material.dart';

import 'forecast_screen.dart';
import 'city_search_screen.dart';

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  int _selectedTab = 0;

  static const _hours = [
    ('Now', '29°', Icons.wb_sunny_rounded),
    ('11 AM', '30°', Icons.wb_sunny_rounded),
    ('12 PM', '31°', Icons.wb_sunny_rounded),
    ('1 PM', '32°', Icons.wb_sunny_rounded),
    ('2 PM', '32°', Icons.cloud_rounded),
    ('3 PM', '31°', Icons.cloud_queue_rounded),
    ('4 PM', '30°', Icons.cloud_rounded),
    ('5 PM', '29°', Icons.wb_twilight_rounded),
  ];

  static const _days = [
    ('Today', 'Partly cloudy', '25°', '32°', Icons.cloud_queue_rounded),
    ('Tomorrow', 'Sunny', '25°', '33°', Icons.wb_sunny_rounded),
    ('Wed, 24 Apr', 'Light rain', '24°', '30°', Icons.grain_rounded),
    ('Thu, 25 Apr', 'Mostly sunny', '25°', '32°', Icons.wb_sunny_rounded),
    ('Fri, 26 Apr', 'Scattered rain', '24°', '31°', Icons.water_drop_rounded),
  ];

  void _showSearch() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CitySearchScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
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
                    child: _TopBar(onSearch: _showSearch),
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
                      onLocationTap: () => _showLocationSnackBar(context),
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
                      onTap: () => _showLocationSnackBar(
                        context,
                        message: 'Detailed insights coming soon',
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
                      children: const [
                        _HighlightCard(
                          label: 'Feels like',
                          value: '32°',
                          icon: Icons.thermostat_rounded,
                          color: Color(0xFFFFA866),
                        ),
                        _HighlightCard(
                          label: 'Humidity',
                          value: '78%',
                          icon: Icons.water_drop_outlined,
                          color: Color(0xFF63B8FF),
                        ),
                        _HighlightCard(
                          label: 'Wind speed',
                          value: '14 km/h',
                          icon: Icons.air_rounded,
                          color: Color(0xFF6D82B6),
                        ),
                        _HighlightCard(
                          label: 'UV index',
                          value: '6',
                          icon: Icons.wb_sunny_outlined,
                          color: Color(0xFFFFB84D),
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
                      itemCount: _hours.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final hour = _hours[index];
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
                    child: _FiveDayForecast(days: _days),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ForecastScreen()),
            );
            return;
          }
          setState(() => _selectedTab = index);
        },
        height: 76,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE4F2FF),
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
      ),
    );
  }

  void _showLocationSnackBar(BuildContext context, {String? message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Colombo is your current location')),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF101B36),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.cloud_rounded, color: Color(0xFF63B8FF), size: 25),
              Positioned(
                right: 7,
                top: 7,
                child: Icon(
                  Icons.wb_sunny_rounded,
                  color: Colors.white,
                  size: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SkyCast',
                style: TextStyle(
                  color: Color(0xFF101B36),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 1),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF6D82B6),
                    size: 13,
                  ),
                  SizedBox(width: 3),
                  Text(
                    'Colombo, Sri Lanka',
                    style: TextStyle(
                      color: Color(0xFF6D82B6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _IconButton(icon: Icons.search_rounded, onTap: onSearch),
        const SizedBox(width: 8),
        const CircleAvatar(
          radius: 19,
          backgroundColor: Color(0xFFDCEBFA),
          child: Icon(Icons.person_outline_rounded, color: Color(0xFF31537F)),
        ),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: const Color(0xFF101B36), size: 22),
        ),
      ),
    );
  }
}

class _HeroWeatherCard extends StatelessWidget {
  const _HeroWeatherCard({required this.onLocationTap});

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
                  const Text(
                    'TUESDAY, 23 APRIL 2024',
                    style: TextStyle(
                      color: Color(0xD9FFFFFF),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onLocationTap,
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                '29°',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 62,
                  height: 0.95,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Partly Cloudy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'H 32°  ·  L 25°',
                style: TextStyle(
                  color: Color(0xD9FFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: Color(0xBFFFFFFF),
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Local time  10:42 AM',
                    style: TextStyle(color: Color(0xD9FFFFFF), fontSize: 11),
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
          style: const TextStyle(
            color: Color(0xFF101B36),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EFF7)),
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
                style: const TextStyle(
                  color: Color(0xFF101B36),
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
    final foreground = isCurrent ? Colors.white : const Color(0xFF101B36);
    return Container(
      width: 67,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFF5BA9E8) : Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: isCurrent ? Colors.transparent : const Color(0xFFE9EFF7),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9EFF7)),
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
              const Divider(height: 1, color: Color(0xFFEEF2F7)),
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
              style: const TextStyle(
                color: Color(0xFF101B36),
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
            style: const TextStyle(
              color: Color(0xFF101B36),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
