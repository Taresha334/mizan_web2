// filepath: lib/core/services/location_service.dart

import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  /// Converts a city name like "Bishoftu" to LatLng coordinates
  static Future<LatLng?> getCoordinatesFromCity(String cityName) async {
    try {
      // We append "Ethiopia" to ensure accuracy (e.g., "Adama, Ethiopia")
      List<Location> locations = await locationFromAddress(
        "$cityName, Ethiopia",
      );

      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
      return null;
    } catch (e) {
      print("Geocoding Error for $cityName: $e");
      return null;
    }
  }
}
