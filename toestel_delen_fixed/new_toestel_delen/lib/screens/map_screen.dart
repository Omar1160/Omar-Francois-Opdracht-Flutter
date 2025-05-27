import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:provider/provider.dart';
import 'package:toesteldelen_project/constants/colors.dart';
import 'package:toesteldelen_project/models/appliance.dart';
import 'package:toesteldelen_project/providers/appliance_provider.dart';
import 'package:toesteldelen_project/providers/location_provider.dart';
import 'package:toesteldelen_project/services/map_service.dart';
import 'package:toesteldelen_project/screens/appliance_detail_screen.dart';
import 'package:toesteldelen_project/widgets/location_search_bar.dart';
import 'package:geocoding/geocoding.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapController? _controller;
  final MapService _mapService = MapService();
  bool _isLoading = true;
  String? _errorMessage;
  GeoPoint? _currentPosition;
  GeoPoint? _selectedPosition;
  double _radius = 5.0; // Start with smaller default radius
  String? _selectedLocationName;
  String? _circleId;
  GeoPoint? _lastMarkerPosition;
  bool _isMapReady = false;

  final List<double> _radiusOptions = [5, 10, 20, 40, 60, 80, 100];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      _currentPosition = await _mapService.getCurrentLocation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          return GeoPoint(latitude: 51.2194, longitude: 4.4025); // Default to Antwerp
        },
      );

      _controller = MapController.withPosition(
        initPosition: _currentPosition!,
      );

      // Wait for map to be fully initialized
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _isLoading = false;
        _isMapReady = true;
      });

      // Set initial position and draw circle
      await _updateSelectedLocation(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        'Current Location'
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize map: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateRadius(double newRadius) async {
    if (!_isMapReady || _controller == null || _selectedPosition == null) return;

    try {
      // Remove existing circle
      if (_circleId != null) {
        try {
          await _controller?.removeCircle(_circleId!);
        } catch (e) {
          debugPrint('Error removing circle: $e');
        }
        _circleId = null;
      }
      
      setState(() {
        _radius = newRadius;
      });

      // Draw new circle with updated radius
      _circleId = 'circle_${DateTime.now().millisecondsSinceEpoch}';
      await _controller?.drawCircle(
        CircleOSM(
          key: _circleId!,
          centerPoint: _selectedPosition!,
          radius: newRadius * 1000, // Convert to meters
          color: Colors.blue.withOpacity(0.2),
          strokeWidth: 2.0,
        ),
      );

      // Update zoom level based on radius
      await _adjustZoomForRadius(newRadius);
    } catch (e) {
      debugPrint('Error updating radius: $e');
    }
  }

  Future<void> _adjustZoomForRadius(double radius) async {
    try {
      double zoom = _getZoomLevel(radius);
      await _controller?.setZoom(zoomLevel: zoom);
    } catch (e) {
      debugPrint('Error adjusting zoom: $e');
    }
  }

  double _getZoomLevel(double radius) {
    // More precise zoom levels based on radius
    if (radius <= 5) return 13;
    if (radius <= 10) return 12;
    if (radius <= 20) return 11;
    if (radius <= 40) return 10;
    if (radius <= 60) return 9;
    if (radius <= 80) return 8;
    return 7;
  }

  Future<void> _updateSelectedLocation(double lat, double lng, [String? locationName]) async {
    if (!_isMapReady || _controller == null) return;

    try {
      final point = GeoPoint(latitude: lat, longitude: lng);
      
      // Remove existing circle and marker
      if (_circleId != null) {
        try {
          await _controller?.removeCircle(_circleId!);
        } catch (e) {
          debugPrint('Error removing circle: $e');
        }
        _circleId = null;
      }

      if (_lastMarkerPosition != null) {
        try {
          await _controller?.removeMarker(_lastMarkerPosition!);
        } catch (e) {
          debugPrint('Error removing marker: $e');
        }
      }

      setState(() {
        _selectedPosition = point;
        _lastMarkerPosition = point;
      });

      // Add marker
      await _controller?.addMarker(
        point,
        markerIcon: const MarkerIcon(
          icon: Icon(
            Icons.location_on,
            color: Colors.red,
            size: 48,
          ),
        ),
      );

      // Draw circle
      _circleId = 'circle_${DateTime.now().millisecondsSinceEpoch}';
      await _controller?.drawCircle(
        CircleOSM(
          key: _circleId!,
          centerPoint: point,
          radius: _radius * 1000, // Convert to meters
          color: Colors.blue.withOpacity(0.2),
          strokeWidth: 2.0,
        ),
      );

      // Change map location and zoom
      if (locationName != null) {
        await _controller?.changeLocation(point);
        await _adjustZoomForRadius(_radius);
      }

      // Update location name
      if (locationName != null) {
        setState(() {
          _selectedLocationName = locationName;
        });
      } else {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
          if (placemarks.isNotEmpty && mounted) {
            setState(() {
              _selectedLocationName = [
                if (placemarks.first.locality?.isNotEmpty == true) placemarks.first.locality,
                if (placemarks.first.administrativeArea?.isNotEmpty == true) placemarks.first.administrativeArea,
                placemarks.first.country,
              ].where((e) => e != null && e.isNotEmpty).join(', ');
            });
          }
        } catch (e) {
          debugPrint('Error getting location name: $e');
        }
      }
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  void _applySelection() async {
    if (_selectedPosition != null && _selectedLocationName != null) {
      try {
        // Update location provider
        final locationProvider = Provider.of<LocationProvider>(context, listen: false);
        locationProvider.setSelectedLocation(
          _selectedPosition!.latitude,
          _selectedPosition!.longitude,
          _selectedLocationName!,
        );
        locationProvider.setRadius(_radius);

        // Pop back to previous screen
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint('Error applying selection: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update location. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location first'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showApplianceDetails(BuildContext context, Appliance appliance) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      appliance.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appliance.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '€${appliance.pricePerDay}/day',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ApplianceDetailScreen(appliance: appliance),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text(
                  'View Details',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initializeMap();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Change location',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar with suggestions
                LocationSearchBar(
                  initialLocation: _selectedLocationName,
                  onLocationSelected: (lat, lng, name) {
                    _updateSelectedLocation(lat, lng, name);
                  },
                ),
                const SizedBox(height: 16),
                // Radius selection
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Search Radius',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_radius.round()} km',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Radius options
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _radiusOptions.map((radius) {
                          bool isSelected = _radius == radius;
                          return InkWell(
                            onTap: () => _updateRadius(radius),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? Colors.blue : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                '${radius.round()} km',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Map
          Expanded(
            child: OSMFlutter(
              controller: _controller!,
              osmOption: OSMOption(
                showZoomController: false,
                userTrackingOption: const UserTrackingOption(
                  enableTracking: true,
                  unFollowUser: true,
                ),
                zoomOption: const ZoomOption(
                  initZoom: 12,
                  minZoomLevel: 3,
                  maxZoomLevel: 19,
                  stepZoom: 1.0,
                ),
              ),
              onGeoPointClicked: (point) => _updateSelectedLocation(
                point.latitude,
                point.longitude,
              ),
            ),
          ),
          // Apply button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _selectedPosition != null ? _applySelection : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedPosition != null ? Colors.blue : Colors.grey,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Apply',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}