import 'dart:async';

import 'package:flutter/material.dart';

import '../services/city_store.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';

class CitySearchScreen extends StatefulWidget {
  const CitySearchScreen({this.service, super.key});

  final WeatherService? service;

  @override
  State<CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends State<CitySearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  late final _service = widget.service ?? WeatherService();
  Timer? _loadingTimer;
  bool _isLoading = false;
  String _query = '';
  String? _error;
  List<_CityResult> _results = const [];

  final _store = CityStore();
  final _location = LocationService();
  List<_CityResult> _recentCities = const [];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final names = await _store.loadRecent();
    if (!mounted) return;
    setState(() {
      _recentCities = [
        for (final name in names) _CityResult(city: name, country: ''),
      ];
    });
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _loadingTimer?.cancel();
    final query = value.trim();
    setState(() {
      _query = query;
      _isLoading = query.isNotEmpty;
      _error = null;
    });
    if (query.isNotEmpty) {
      _loadingTimer = Timer(
        const Duration(milliseconds: 450),
        () => _search(query),
      );
    }
  }

  Future<void> _search(String query) async {
    try {
      final suggestions = await _service.searchCities(query);
      if (!mounted || query != _query) return;
      setState(() {
        _results = [
          for (final city in suggestions)
            _CityResult(
              city: city.name,
              query: city.query,
              country: [
                if (city.region.isNotEmpty) city.region,
                city.country,
              ].join(', '),
            ),
        ];
        _isLoading = false;
      });
    } on WeatherException {
      if (!mounted || query != _query) return;
      setState(() {
        _error = 'Could not search right now. Check your connection.';
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _onQueryChanged('');
    _focusNode.requestFocus();
  }

  Future<void> _selectCity(_CityResult city) async {
    await _store.addRecent(city.query);
    if (!mounted) return;
    Navigator.of(context).pop(city.query);
  }

  Future<void> _removeRecent(_CityResult city) async {
    await _store.removeRecent(city.query);
    await _loadRecent();
  }

  Future<void> _useLocation() async {
    try {
      final query = await _location.currentQuery();
      if (!mounted) return;
      Navigator.of(context).pop(query);
    } on LocationException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final showingResults = _query.isNotEmpty && !_isLoading;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Search City',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            _SearchField(
              controller: _searchController,
              focusNode: _focusNode,
              isLoading: _isLoading,
              onChanged: _onQueryChanged,
              onClear: _clearSearch,
            ),
            const SizedBox(height: 16),
            _LocationButton(onPressed: _useLocation),
            const SizedBox(height: 30),
            if (_isLoading)
              const _SearchLoadingState()
            else if (_error != null)
              _EmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Search unavailable',
                message: _error!,
              )
            else if (showingResults)
              _SearchResults(results: _results, onSelect: _selectCity)
            else
              _RecentSearches(
                cities: _recentCities,
                onSelect: _selectCity,
                onRemove: _removeRecent,
              ),
          ],
        ),
      ),
    );
  }
}

class _CityResult {
  const _CityResult({
    required this.city,
    required this.country,
    String? query,
  }) : query = query ?? city;

  final String city;
  final String country;

  /// What is stored and returned when this result is picked.
  final String query;
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search for a city',
        hintStyle: const TextStyle(color: Color(0xFF92A0B7), fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6383AB)),
        suffixIcon: isLoading
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : controller.text.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 17),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Color(0xFF63B8FF), width: 1.5),
        ),
      ),
    );
  }
}

class _LocationButton extends StatelessWidget {
  const _LocationButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.my_location_rounded, size: 19),
      label: const Text('Use My Location'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2D78B4),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        side: BorderSide.none,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SearchLoadingState extends StatelessWidget {
  const _SearchLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 36),
      child: Column(
        children: [
          CircularProgressIndicator(color: Color(0xFF63B8FF)),
          SizedBox(height: 18),
          Text(
            'Searching for cities...',
            style: TextStyle(
              color: Color(0xFF6D82A2),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.cities,
    required this.onSelect,
    required this.onRemove,
  });

  final List<_CityResult> cities;
  final ValueChanged<_CityResult> onSelect;
  final ValueChanged<_CityResult> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Recent searches'),
        const SizedBox(height: 12),
        if (cities.isEmpty)
          const _EmptyState(
            icon: Icons.history_rounded,
            title: 'No recent searches',
            message: 'Cities you open will appear here.',
          )
        else
          ...cities.map(
            (city) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CityListItem(
                city: city,
                onTap: () => onSelect(city),
                trailing: IconButton(
                  tooltip: 'Remove ${city.city}',
                  onPressed: () => onRemove(city),
                  icon: const Icon(Icons.close_rounded, size: 19),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results, required this.onSelect});

  final List<_CityResult> results;
  final ValueChanged<_CityResult> onSelect;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return _EmptyState(
        icon: Icons.location_off_rounded,
        title: 'No cities found',
        message: 'Try a different spelling or search another city.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Suggestions'),
        const SizedBox(height: 12),
        ...results.map(
          (city) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CityListItem(
              city: city,
              onTap: () => onSelect(city),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: Color(0xFF9AA9BD),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CityListItem extends StatelessWidget {
  const _CityListItem({
    required this.city,
    required this.onTap,
    required this.trailing,
  });

  final _CityResult city;
  final VoidCallback onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.location_city_rounded,
                  color: const Color(0xFF63B8FF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city.city,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (city.country.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        city.country,
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 35),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF63B8FF), size: 29),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
