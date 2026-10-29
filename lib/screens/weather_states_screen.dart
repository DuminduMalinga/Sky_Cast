import 'package:flutter/material.dart';

enum WeatherRequestState {
  loading,
  networkError,
  cityNotFound,
  locationPermissionDenied,
  offline,
}

class WeatherStateView extends StatelessWidget {
  const WeatherStateView({
    required this.state,
    this.hasCachedWeather = false,
    this.lastUpdated,
    this.cachedSummary,
    this.onRetry,
    this.onSearch,
    this.onEnableLocation,
    super.key,
  });

  final WeatherRequestState state;
  final bool hasCachedWeather;
  final String? lastUpdated;
  final String? cachedSummary;
  final VoidCallback? onRetry;
  final VoidCallback? onSearch;
  final VoidCallback? onEnableLocation;

  @override
  Widget build(BuildContext context) {
    if (state == WeatherRequestState.loading) {
      return const _LoadingState();
    }

    if (state == WeatherRequestState.networkError) {
      return _MessageState(
        icon: Icons.cloud_off_rounded,
        title: 'Unable to load weather',
        message: 'Check your internet connection and try again.',
        actionLabel: 'Try Again',
        onAction: onRetry,
      );
    }

    if (state == WeatherRequestState.cityNotFound) {
      return _MessageState(
        icon: Icons.location_searching_rounded,
        title: 'City not found',
        message: 'Try another city name.',
        actionLabel: 'Return to Search',
        onAction: onSearch,
      );
    }

    if (state == WeatherRequestState.locationPermissionDenied) {
      return _MessageState(
        icon: Icons.location_disabled_rounded,
        title: 'Location access is off',
        message:
            'SkyCast needs location access for automatic local weather. You can enable it or search for a city manually.',
        actionLabel: 'Enable Location',
        onAction: onEnableLocation,
        secondaryLabel: 'Search Manually',
        onSecondary: onSearch,
      );
    }

    if (hasCachedWeather) {
      return _CachedOfflineState(
        lastUpdated: lastUpdated ?? 'Recently',
        summary: cachedSummary,
        onRetry: onRetry,
      );
    }

    return _MessageState(
      icon: Icons.wifi_off_rounded,
      title: 'You’re offline',
      message: 'Connect to the internet to get the latest weather.',
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }
}

class WeatherStatesScreen extends StatelessWidget {
  const WeatherStatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Weather states',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        titleSpacing: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          const Text(
            'Request feedback',
            style: TextStyle(
              color: Color(0xFF8290A8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in const [
            WeatherRequestState.loading,
            WeatherRequestState.networkError,
            WeatherRequestState.cityNotFound,
            WeatherRequestState.locationPermissionDenied,
            WeatherRequestState.offline,
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _StatePreview(
                title: _stateTitle(item),
                child: WeatherStateView(
                  state: item,
                  onRetry: _noop,
                  onSearch: _noop,
                  onEnableLocation: _noop,
                ),
              ),
            ),
          _StatePreview(
            title: 'Offline with cached weather',
            child: WeatherStateView(
              state: WeatherRequestState.offline,
              hasCachedWeather: true,
              lastUpdated: 'Today, 9:42 AM',
              onRetry: _noop,
            ),
          ),
        ],
      ),
    );
  }

  static String _stateTitle(WeatherRequestState state) {
    switch (state) {
      case WeatherRequestState.loading:
        return 'Loading';
      case WeatherRequestState.networkError:
        return 'Network error';
      case WeatherRequestState.cityNotFound:
        return 'City not found';
      case WeatherRequestState.locationPermissionDenied:
        return 'Location permission denied';
      case WeatherRequestState.offline:
        return 'No internet connection';
    }
  }

  static void _noop() {}
}

class _StatePreview extends StatelessWidget {
  const _StatePreview({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2EAF4)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        children: [
          const _WeatherIllustration(warning: false),
          const SizedBox(height: 12),
          const SizedBox(
            width: 25,
            height: 25,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF63B8FF),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Getting the latest weather…',
            style: TextStyle(
              color: Color(0xFF31537F),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(child: _Skeleton(height: 48)),
              SizedBox(width: 10),
              Expanded(child: _Skeleton(height: 48)),
            ],
          ),
          const SizedBox(height: 10),
          const _Skeleton(height: 74),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      child: Column(
        children: [
          _WeatherIllustration(warning: icon == Icons.cloud_off_rounded),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7185A6),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF63B8FF),
                foregroundColor: const Color(0xFF101B36),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              child: Text(actionLabel),
            ),
          ),
          if (secondaryLabel != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onSecondary,
              child: Text(
                secondaryLabel!,
                style: const TextStyle(
                  color: Color(0xFF357CA9),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CachedOfflineState extends StatelessWidget {
  const _CachedOfflineState({
    required this.lastUpdated,
    required this.onRetry,
    this.summary,
  });

  final String lastUpdated;
  final String? summary;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Color(0xFF63B8FF), size: 20),
              SizedBox(width: 8),
              Text(
                'Showing saved weather',
                style: TextStyle(
                  color: Color(0xFF31537F),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Last updated $lastUpdated',
            style: const TextStyle(color: Color(0xFF8290A8), fontSize: 11),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.cloud_queue_rounded,
                  color: Color(0xFF63B8FF),
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    summary ?? 'Colombo  ·  29°\nPartly cloudy  ·  H 32° / L 25°',
                    style: const TextStyle(
                      color: Color(0xFF31537F),
                      fontSize: 12,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF357CA9),
              minimumSize: const Size.fromHeight(44),
              side: const BorderSide(color: Color(0xFFB8DCF6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherIllustration extends StatelessWidget {
  const _WeatherIllustration({required this.warning});

  final bool warning;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      width: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 72,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F4FF),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.cloud_rounded,
              color: Color(0xFF63B8FF),
              size: 46,
            ),
          ),
          if (warning)
            const Positioned(
              right: 7,
              top: 3,
              child: CircleAvatar(
                radius: 15,
                backgroundColor: Color(0xFFFFE6B8),
                child: Icon(
                  Icons.priority_high_rounded,
                  color: Color(0xFFB87318),
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEF6),
        borderRadius: BorderRadius.circular(13),
      ),
    );
  }
}
