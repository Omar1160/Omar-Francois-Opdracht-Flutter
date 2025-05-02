import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:provider/provider.dart';
import 'package:toesteldelen_project/constants/colors.dart';
import 'package:toesteldelen_project/models/appliance.dart';
import 'package:toesteldelen_project/providers/appliance_provider.dart';
import 'package:toesteldelen_project/services/map_service.dart';
import 'package:toesteldelen_project/screens/appliance_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapController? _controller;
  final MapService _mapService = MapService();
  bool _isLoading = true; // Track loading state explicitly
  String? _errorMessage; // Store error message if initialization fails
  GeoPoint? _currentPosition; // Store the current position for centering

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // Try to get the current location
      _currentPosition = await _mapService.getCurrentLocation().timeout(
        const Duration(seconds: 10), // Timeout after 10 seconds
        onTimeout: () {
          // Fallback to AP Hogeschool Ellermanstraat, Antwerp if geolocation times out
          return GeoPoint(latitude: 51.2300, longitude: 4.4150);
        },
      );

      // Use the named constructor withPosition to ensure proper initialization
      _controller = MapController.withPosition(
        initPosition: _currentPosition!,
        areaLimit: BoundingBox.world(),
      );
    } catch (e) {
      // Handle any errors during initialization
      setState(() {
        _errorMessage = 'Failed to initialize map: $e';
      });
    } finally {
      // Always update the loading state
      setState(() {
        _isLoading = false;
      });
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
                  _initializeMap(); // Retry initialization
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: StreamBuilder<List<Appliance>>(
        stream: Provider.of<ApplianceProvider>(context).getAppliances(),
        builder: (context, AsyncSnapshot<List<Appliance>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final appliances = snapshot.data ?? [];

          // Convert appliances to a list of StaticPositionGeoPoint for staticPoints
          final List<StaticPositionGeoPoint> staticPoints = appliances
              .asMap()
              .entries
              .map((entry) {
            final index = entry.key;
            final appliance = entry.value;
            if (appliance.location.contains(',')) {
              try {
                final coordinates = appliance.location.split(',');
                final latitude = double.parse(coordinates[0].trim());
                final longitude = double.parse(coordinates[1].trim());
                return StaticPositionGeoPoint(
                  'appliance-$index', // Unique ID for each marker
                  MarkerIcon(
                    icon: Icon(
                      Icons.location_pin,
                      color: AppColors.primary,
                      size: 48,
                    ),
                  ),
                  [
                    GeoPoint(latitude: latitude, longitude: longitude),
                  ],
                );
              } catch (e) {
                // Log the error but don't let it break the map
                debugPrint('Error parsing coordinates for ${appliance.title}: $e');
                return null;
              }
            }
            return null;
          })
              .where((point) => point != null)
              .cast<StaticPositionGeoPoint>()
              .toList();

          return OSMFlutter(
            controller: _controller!,
            osmOption: OSMOption(
              showZoomController: true, // Explicitly enable zoom controls
              userTrackingOption: const UserTrackingOption(
                enableTracking: true,
                unFollowUser: false,
              ),
              zoomOption: const ZoomOption(
                initZoom: 15, // Increased initial zoom level for better visibility
                minZoomLevel: 3,
                maxZoomLevel: 19,
                stepZoom: 1.0,
              ),
              userLocationMarker: UserLocationMaker(
                personMarker: const MarkerIcon(
                  icon: Icon(
                    Icons.location_history,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
                directionArrowMarker: const MarkerIcon(
                  icon: Icon(
                    Icons.double_arrow,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
              ),
              staticPoints: staticPoints,
              showDefaultInfoWindow: true,
            ),
            onMapIsReady: (isReady) async {
              if (isReady) {
                try {
                  // Center the map on the current position
                  await _controller!.changeLocation(_currentPosition!);
                  // Enable tracking to follow the user's location
                  await _controller!.enableTracking();
                } catch (e) {
                  setState(() {
                    _errorMessage = 'Failed to enable tracking: $e';
                    _isLoading = false;
                  });
                }
              }
            },
            onGeoPointClicked: (geoPoint) {
              final appliance = appliances.firstWhere(
                    (appliance) {
                  if (appliance.location.contains(',')) {
                    final coordinates = appliance.location.split(',');
                    final latitude = double.parse(coordinates[0].trim());
                    final longitude = double.parse(coordinates[1].trim());
                    return geoPoint.latitude == latitude &&
                        geoPoint.longitude == longitude;
                  }
                  return false;
                },
                orElse: () => appliances.first,
              );
              _showApplianceDetails(context, appliance);
            },
          );
        },
      ),
    );
  }
}