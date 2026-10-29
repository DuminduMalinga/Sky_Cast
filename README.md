# SkyCast

A Flutter weather app that shows live conditions, an hourly outlook and a
5-day forecast for your location or any city in the world, using the
[WeatherAPI.com](https://www.weatherapi.com/) REST API.

## Screenshots

<p align="center">
  <img src="docs/screenshots/welcome.png" width="190" alt="Welcome screen">
  <img src="docs/screenshots/home.png" width="190" alt="Home dashboard">
  <img src="docs/screenshots/home-forecast.png" width="190" alt="Hourly and 5-day forecast on the dashboard">
  <img src="docs/screenshots/details.png" width="190" alt="Weather details">
</p>
<p align="center">
  <img src="docs/screenshots/forecast-hourly.png" width="190" alt="Hourly forecast with 24-hour chart">
  <img src="docs/screenshots/forecast-5day.png" width="190" alt="5-day forecast">
  <img src="docs/screenshots/search.png" width="190" alt="City search with autocomplete">
  <img src="docs/screenshots/saved.png" width="190" alt="Saved cities">
</p>
<p align="center">
  <img src="docs/screenshots/settings.png" width="190" alt="Settings">
  <img src="docs/screenshots/home-light.png" width="190" alt="Light theme">
</p>

## Features

- **Live weather** for your current location (GPS, with an IP-based fallback) or a chosen city.
  Location permission is requested **once**, on first launch; after that the location is refreshed
  silently every time the app opens, and the welcome screen is shown only the first time
- **Dashboard**: temperature, condition, high/low, feels-like, humidity, wind, UV
- **Weather details**: sunrise/sunset, pressure, visibility, precipitation, chance of rain, cloud cover
- **Hourly and 5-day forecast** with a 24-hour temperature chart
- **City search** with autocomplete and recent searches; WeatherAPI results are merged with
  [Open-Meteo](https://open-meteo.com/en/docs/geocoding-api) geocoding so smaller towns are found
- **Saved cities** with live weather cards; the list is stored on the device and kept between launches
- **Settings**: light/dark/system theme, °C/°F, km/h/mph, mm/in, automatic location
  (all persisted on the device)
- **Loading, offline, server-error, city-not-found and location-permission-denied states**
  with retry and recovery paths
- Persistent bottom navigation (Home, Forecast, Saved, Settings) on every screen
- Pull-to-refresh, responsive layout, custom app icon and splash/welcome screen

## Getting started

1. Get a free API key at <https://www.weatherapi.com/>.
2. Create the key file (it is git-ignored, so your key is never committed):

   ```sh
   cp lib/config/api_config.example.dart lib/config/api_config.dart
   ```

   Then open `lib/config/api_config.dart` and replace `YOUR_WEATHERAPI_KEY`.
3. Run the app:

   ```sh
   flutter pub get
   flutter run
   ```

On an emulator, set a location in *Extended controls → Location* (or
`adb emu geo fix <longitude> <latitude>`), otherwise the default is California.

## Project structure

```
lib/
  app.dart, main.dart          App shell, light/dark themes
  config/                      API base URL and key
  models/weather.dart          JSON models (current, hourly, daily, city suggestions)
  services/
    weather_service.dart       REST calls, timeouts, error mapping, city search
    location_service.dart      Permissions and device location
    city_store.dart            Current city, saved cities, recent searches
    app_settings.dart          Persisted user preferences
  screens/                     Onboarding, home, details, forecast, search, saved, settings, states
  utils/format.dart            Unit conversion and formatting
tool/                          App icon generator (see below)
test/widget_test.dart          Widget tests with a mocked HTTP client
docs/screenshots/              Screenshots used in this README
```

## Error handling

`WeatherService` maps failures to `WeatherFailure.network`, `cityNotFound` or
`server`, and the home screen shows the matching state screen with a retry
action. Requests time out after 12 seconds. The location service reports
permission denied, permanently denied and location-services-off separately.

## Tests

```sh
flutter analyze
flutter test
```

## App icon

The icon is drawn in code. To regenerate it and the platform sizes:

```sh
flutter test tool/generate_icon_test.dart
python tool/build_icons.py   # requires Pillow
```

## Credits

Weather data by [WeatherAPI.com](https://www.weatherapi.com/); extra city
lookup by [Open-Meteo](https://open-meteo.com/).
