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
  /// The device position as a "lat,lon" query accepted by WeatherAPI.
  Future<String> currentQuery() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationException(LocationFailure.serviceDisabled);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const LocationException(LocationFailure.deniedForever);
      }
      if (permission == LocationPermission.denied) {
        throw const LocationException(LocationFailure.denied);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return '${position.latitude},${position.longitude}';
    } on LocationException {
      rethrow;
    } catch (_) {
      throw const LocationException(LocationFailure.unavailable);
    }
  }

  Future<void> openSettings() => Geolocator.openAppSettings();
}
