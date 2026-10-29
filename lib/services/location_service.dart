import 'package:geolocator/geolocator.dart';

enum LocationFailure { serviceDisabled, denied, deniedForever, unavailable }

class LocationException implements Exception {
  const LocationException(this.failure);

  final LocationFailure failure;

  String get message => switch (failure) {
    LocationFailure.serviceDisabled => 'Turn on location services to continue.',
    LocationFailure.denied => 'Location permission was denied.',
    LocationFailure.deniedForever =>
      'Location permission is blocked. Enable it in app settings.',
    LocationFailure.unavailable => 'Could not determine your location.',
  };

  @override
  String toString() => 'LocationException($failure)';
}

class LocationService {
  /// WeatherAPI's approximate, IP-based location.
  static const ipQuery = 'auto:ip';
  static const _maxCacheAge = Duration(minutes: 10);

  /// The device position as a "lat,lon" query accepted by WeatherAPI.
  ///
  /// With [allowPrompt] false the permission dialog is never shown: if access
  /// has not already been granted this throws [LocationFailure.denied]. Use it
  /// for the automatic lookup on app start so the user is asked only once.
  Future<String> currentQuery({bool allowPrompt = true}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationException(LocationFailure.serviceDisabled);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && allowPrompt) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const LocationException(LocationFailure.deniedForever);
      }
      if (permission == LocationPermission.denied) {
        throw const LocationException(LocationFailure.denied);
      }
      // A cached fix is only trusted while fresh; an old one may be from
      // somewhere else entirely.
      final cached = await Geolocator.getLastKnownPosition();
      final isFresh =
          cached != null &&
          DateTime.now().difference(cached.timestamp) < _maxCacheAge;
      final position = isFresh
          ? cached
          : await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.low,
                timeLimit: Duration(seconds: 8),
              ),
            );
      return '${position.latitude},${position.longitude}';
    } on LocationException {
      rethrow;
    } catch (_) {
      // Permission is granted but there is no GPS fix (common on emulators and
      // indoors): let the weather provider estimate the location from the IP.
      return ipQuery;
    }
  }

  Future<void> openSettings() => Geolocator.openAppSettings();
}
