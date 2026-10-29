import 'package:flutter/material.dart';

import '../models/weather.dart';
import '../services/app_settings.dart';
import '../utils/format.dart';
import '../widgets/sky_nav_bar.dart';

/// Extra current conditions: sun times, pressure, visibility and more.
class DetailsScreen extends StatefulWidget {
  const DetailsScreen({required this.report, super.key});

  final WeatherReport report;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen>
    with SettingsListener<DetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final rainChance = report.today?.chanceOfRain ?? 0;
    final tiles = [
      _Detail(
        'Pressure',
        report.pressureMb > 0 ? pressure(report.pressureMb) : '—',
        Icons.speed_rounded,
        const Color(0xFF8E9BFF),
      ),
      _Detail(
        'Visibility',
        report.visibilityKm > 0 ? distance(report.visibilityKm) : '—',
        Icons.visibility_outlined,
        const Color(0xFF63B8FF),
      ),
      _Detail(
        'Precipitation',
        rain(report.precipMm),
        Icons.water_drop_outlined,
        const Color(0xFF4FC3F7),
      ),
      _Detail(
        'Chance of rain',
        '$rainChance%',
        Icons.umbrella_outlined,
        const Color(0xFF6D82B6),
      ),
      _Detail(
        'Cloud cover',
        '${report.cloud}%',
        Icons.cloud_outlined,
        const Color(0xFFA8B4C8),
      ),
      _Detail(
        'Wind',
        report.windDir.isEmpty
            ? wind(report.windKph)
            : '${wind(report.windKph)} ${report.windDir}',
        Icons.air_rounded,
        const Color(0xFF6D82B6),
      ),
    ];
    return Scaffold(
      bottomNavigationBar: SkyNavigationBar(
        selectedIndex: AppNav.home,
        onSelected: (index) => AppNav.go(context, index),
      ),
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weather details',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            Text(
              '${report.city}, ${report.country}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
        titleSpacing: 0,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _SunCard(sunrise: report.sunrise, sunset: report.sunset),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) => GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: constraints.maxWidth > 500 ? 2.6 : 1.5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [for (final tile in tiles) _DetailCard(tile)],
            ),
          ),
        ],
      ),
    );
  }
}

class _Detail {
  const _Detail(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
  color: Theme.of(context).cardColor,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: Theme.of(context).dividerColor),
);

class _SunCard extends StatelessWidget {
  const _SunCard({required this.sunrise, required this.sunset});

  final String sunrise;
  final String sunset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Row(
        children: [
          Expanded(
            child: _SunTime(
              label: 'Sunrise',
              time: sunrise,
              icon: Icons.wb_twilight_rounded,
              color: const Color(0xFFFFB84D),
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: Theme.of(context).dividerColor,
          ),
          Expanded(
            child: _SunTime(
              label: 'Sunset',
              time: sunset,
              icon: Icons.nights_stay_outlined,
              color: const Color(0xFFFFA866),
            ),
          ),
        ],
      ),
    );
  }
}

class _SunTime extends StatelessWidget {
  const _SunTime({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String label;
  final String time;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          time.isEmpty ? '—' : time,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard(this.detail);

  final _Detail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(detail.icon, color: detail.color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.label,
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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
