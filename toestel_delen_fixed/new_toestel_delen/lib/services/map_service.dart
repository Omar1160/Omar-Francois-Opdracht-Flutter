import 'package:geolocator/geolocator.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class MapService {
  Future<GeoPoint> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return GeoPoint(latitude: 52.5200, longitude: 13.4050); // Berlin fallback
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return GeoPoint(latitude: 52.5200, longitude: 13.4050);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return GeoPoint(latitude: 52.5200, longitude: 13.4050);
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      print('Location error: $e');
      return GeoPoint(latitude: 52.5200, longitude: 13.4050); // Berlin fallback
    }
  }
}