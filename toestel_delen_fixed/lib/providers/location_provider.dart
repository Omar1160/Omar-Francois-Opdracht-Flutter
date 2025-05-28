import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider extends ChangeNotifier {
  double? _selectedLat;
  double? _selectedLng;
  String? _selectedLocationName;
  double _selectedRadius = 5.0; // Default radius in km

  double? get selectedLat => _selectedLat;
  double? get selectedLng => _selectedLng;
  String? get selectedLocationName => _selectedLocationName;
  double get selectedRadius => _selectedRadius;

  void setSelectedLocation(double lat, double lng, String locationName) {
    _selectedLat = lat;
    _selectedLng = lng;
    _selectedLocationName = locationName;
    notifyListeners();
  }

  void setRadius(double radius) {
    _selectedRadius = radius;
    notifyListeners();
  }

  void clearSelection() {
    _selectedLat = null;
    _selectedLng = null;
    _selectedLocationName = null;
    _selectedRadius = 5.0;
    notifyListeners();
  }

  bool isLocationSelected() {
    return _selectedLat != null && _selectedLng != null;
  }

  double calculateDistanceToSelected(double lat, double lng) {
    if (!isLocationSelected()) return 0;
    
    return Geolocator.distanceBetween(
      _selectedLat!,
      _selectedLng!,
      lat,
      lng,
    ) / 1000; // Convert to kilometers
  }
} 