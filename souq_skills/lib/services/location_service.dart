import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:souq_skills/core/city_coordinates.dart';

class LocationUnavailable implements Exception {
  const LocationUnavailable(this.message);

  final String message;
}

/// Reads the device's position as latitude and longitude.
abstract interface class DeviceLocator {
  Future<(double, double)> currentPosition();
}

class GeolocatorDeviceLocator implements DeviceLocator {
  @override
  Future<(double, double)> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationUnavailable('Turn on location services first.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationUnavailable('Allow location access to use this.');
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return (position.latitude, position.longitude);
  }
}

class LocationService {
  static DeviceLocator locator = GeolocatorDeviceLocator();

  /// Returns the offered city closest to the device.
  Future<String> currentCity() async {
    try {
      final (latitude, longitude) = await locator.currentPosition();
      return nearestCity(latitude, longitude);
    } on LocationUnavailable {
      rethrow;
    } catch (_) {
      throw const LocationUnavailable('Could not find your location.');
    }
  }

  String nearestCity(double latitude, double longitude) {
    double distanceTo((double, double) city) {
      final dLat = city.$1 - latitude;
      final dLng = (city.$2 - longitude) * cos(latitude * pi / 180);
      return dLat * dLat + dLng * dLng;
    }

    return cityCoordinates.entries
        .reduce(
          (closest, city) => distanceTo(city.value) < distanceTo(closest.value)
              ? city
              : closest,
        )
        .key;
  }
}
