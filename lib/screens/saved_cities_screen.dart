import 'package:flutter/material.dart';

import 'city_search_screen.dart';

class SavedCitiesScreen extends StatefulWidget {
  const SavedCitiesScreen({super.key});

  @override
  State<SavedCitiesScreen> createState() => _SavedCitiesScreenState();
}

class _SavedCitiesScreenState extends State<SavedCitiesScreen> {
  final List<SavedCity> _cities = [
    const SavedCity(
      name: 'Colombo',
      country: 'Sri Lanka',
      temperature: '29°',
      condition: 'Partly cloudy',
      high: '32°',
      low: '25°',
      icon: Icons.cloud_queue_rounded,
      isSelected: true,
    ),
    const SavedCity(
      name: 'Kandy',
      country: 'Sri Lanka',
      temperature: '27°',
      condition: 'Mostly sunny',
      high: '30°',
      low: '23°',
      icon: Icons.wb_sunny_rounded,
    ),
    const SavedCity(
      name: 'Galle',
      country: 'Sri Lanka',
      temperature: '28°',
      condition: 'Light rain',
      high: '30°',
      low: '25°',
      icon: Icons.grain_rounded,
    ),
    const SavedCity(
      name: 'Jaffna',
      country: 'Sri Lanka',
      temperature: '31°',
      condition: 'Sunny',
      high: '34°',
      low: '27°',
      icon: Icons.wb_sunny_rounded,
    ),
  ];

  Future<void> _addCity() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CitySearchScreen()));
  }

  void _removeCity(SavedCity city) {
    final index = _cities.indexOf(city);
    setState(() => _cities.remove(city));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${city.name} removed from saved cities'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => setState(() => _cities.insert(index, city)),
        ),
      ),
    );
  }

  void _openCity(SavedCity city) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CityWeatherDetailScreen(city: city),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
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
        child: _cities.isEmpty
            ? const _SavedEmptyState()
            : ListView(
                physics: const BouncingScrollPhysics(),
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
                  ..._cities.map(
                    (city) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SavedCityCard(
                        city: city,
                        onTap: () => _openCity(city),
                        onRemove: () => _removeCity(city),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Weather updates refresh when live data is available.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF9AA8BA), fontSize: 11),
                  ),
                ],
              ),
      ),
    );
  }
}

class SavedCity {
  const SavedCity({
    required this.name,
    required this.country,
    required this.temperature,
    required this.condition,
    required this.high,
    required this.low,
    required this.icon,
    this.isSelected = false,
  });

  final String name;
  final String country;
  final String temperature;
  final String condition;
  final String high;
  final String low;
  final IconData icon;
  final bool isSelected;
}

class _SavedCityCard extends StatelessWidget {
  const _SavedCityCard({
    required this.city,
    required this.onTap,
    required this.onRemove,
  });

  final SavedCity city;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
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
              color: city.isSelected
                  ? const Color(0xFF63B8FF)
                  : Theme.of(context).dividerColor,
              width: city.isSelected ? 1.5 : 1,
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
                  color: city.isSelected
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  city.icon,
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
                        Text(
                          city.name,
                          style: const TextStyle(
                            color: Color(0xFF101B36),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (city.isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                      city.country,
                      style: const TextStyle(
                        color: Color(0xFF8290A8),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${city.condition}  ·  H ${city.high} / L ${city.low}',
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
                  Text(
                    city.temperature,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 25,
                      fontWeight: FontWeight.w300,
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

class CityWeatherDetailScreen extends StatelessWidget {
  const CityWeatherDetailScreen({required this.city, super.key});

  final SavedCity city;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          city.name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF274A80), Color(0xFF559AD1)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city.country,
                  style: const TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  city.temperature,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 58,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                Text(
                  city.condition,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'H ${city.high}  ·  L ${city.low}',
                  style: const TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Detailed weather data can be loaded here from the selected city’s API response.',
            style: TextStyle(
              color: Color(0xFF8290A8),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
