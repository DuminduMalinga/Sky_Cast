import 'dart:async';

import 'package:flutter/material.dart';

class CitySearchScreen extends StatefulWidget {
  const CitySearchScreen({super.key});

  @override
  State<CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends State<CitySearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _loadingTimer;
  bool _isLoading = false;
  String _query = '';

  final List<_CityResult> _recentCities = [
    const _CityResult(
      city: 'Colombo',
      country: 'Sri Lanka',
      temperature: '29°',
      icon: Icons.cloud_queue_rounded,
    ),
    const _CityResult(city: 'Kandy', country: 'Sri Lanka'),
    const _CityResult(city: 'Galle', country: 'Sri Lanka'),
    const _CityResult(city: 'Jaffna', country: 'Sri Lanka'),
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
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
    setState(() {
      _query = value.trim();
      _isLoading = value.trim().isNotEmpty;
    });
    if (value.trim().isNotEmpty) {
      _loadingTimer = Timer(const Duration(milliseconds: 450), () {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _onQueryChanged('');
    _focusNode.requestFocus();
  }

  void _selectCity(_CityResult city) {
    Navigator.of(context).pop(city.city);
  }

  void _removeRecent(_CityResult city) {
    setState(() => _recentCities.remove(city));
  }

  void _useLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location access is required to find nearby weather.'),
      ),
    );
  }

  List<_CityResult> get _matches {
    if (_query.isEmpty) return const [];
    final normalizedQuery = _query.toLowerCase();
    return _recentCities
        .where(
          (city) =>
              city.city.toLowerCase().contains(normalizedQuery) ||
              city.country.toLowerCase().contains(normalizedQuery),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final showingResults = _query.isNotEmpty && !_isLoading;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
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
            else if (showingResults)
              _SearchResults(results: _matches, onSelect: _selectCity)
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
    this.temperature,
    this.icon,
  });

  final String city;
  final String country;
  final String? temperature;
  final IconData? icon;
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
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 17),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Color(0xFFE2EAF4)),
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
        backgroundColor: const Color(0xFFEAF5FF),
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
        const SizedBox(height: 8),
        const Text(
          'Only saved cities are shown until live weather search is connected.',
          style: TextStyle(color: Color(0xFF93A0B3), fontSize: 11),
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
      color: Colors.white,
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
                  color: const Color(0xFFEAF5FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  city.icon ?? Icons.location_city_rounded,
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
                      style: const TextStyle(
                        color: Color(0xFF101B36),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      city.country,
                      style: const TextStyle(
                        color: Color(0xFF8290A8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (city.temperature != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    city.temperature!,
                    style: const TextStyle(
                      color: Color(0xFF101B36),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
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
      style: const TextStyle(
        color: Color(0xFF101B36),
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
            decoration: const BoxDecoration(
              color: Color(0xFFEAF5FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF63B8FF), size: 29),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF101B36),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF8290A8), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
