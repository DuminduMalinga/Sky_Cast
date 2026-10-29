import '../services/app_settings.dart';

const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const weekdaysLong = [
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
  'SUNDAY',
];
const months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Formats a Celsius value in the user's preferred temperature unit.
String degrees(double celsius) {
  final value = AppSettings.instance.fahrenheit
      ? celsius * 9 / 5 + 32
      : celsius;
  return '${value.round()}°';
}

/// Formats a km/h value in the user's preferred wind unit.
String wind(double kph) {
  final settings = AppSettings.instance;
  final value = settings.mph ? kph / 1.609344 : kph;
  return '${value.round()} ${settings.windUnit}';
}

/// Formats millimetres of rain in the user's preferred precipitation unit.
String rain(double mm) {
  final settings = AppSettings.instance;
  final value = settings.inches ? mm / 25.4 : mm;
  return '${value.toStringAsFixed(settings.inches ? 2 : 1)} '
      '${settings.precipitationUnit}';
}

/// Formats kilometres of visibility, in miles when the user prefers mph.
String distance(double km) {
  final settings = AppSettings.instance;
  final value = settings.mph ? km / 1.609344 : km;
  return '${value.toStringAsFixed(value < 10 ? 1 : 0)} '
      '${settings.mph ? 'mi' : 'km'}';
}

/// Formats pressure in millibars (hPa).
String pressure(double mb) => '${mb.round()} hPa';

String clock(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${time.hour < 12 ? 'AM' : 'PM'}';
}

/// "11 AM" style label for an hourly slot.
String hourLabel(DateTime time) => clock(time).replaceFirst(':00', '');

final _coordinates = RegExp(r'^-?\d+(\.\d+)?,\s*-?\d+(\.\d+)?$');

/// Whether [query] is a "lat,lon" pair rather than a city name.
bool isCoordinates(String query) => _coordinates.hasMatch(query.trim());
