import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:toesteldelen_project/services/location_service.dart';

class LocationSearchBar extends StatefulWidget {
  final Function(double lat, double lng, String name) onLocationSelected;
  final String? initialLocation;

  const LocationSearchBar({
    Key? key,
    required this.onLocationSelected,
    this.initialLocation,
  }) : super(key: key);

  @override
  _LocationSearchBarState createState() => _LocationSearchBarState();
}

class _LocationSearchBarState extends State<LocationSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final LocationService _locationService = LocationService();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  Position? _currentPosition;
  Timer? _searchDebouncer;
  bool _isSearching = false;
  String? _currentLocationError;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialLocation ?? '';
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLoading = true;
      _currentLocationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied';
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      if (_currentPosition != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );

        if (mounted && placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          String locationName = [
            if (place.locality?.isNotEmpty == true) place.locality,
            if (place.administrativeArea?.isNotEmpty == true) place.administrativeArea,
            if (place.country?.isNotEmpty == true) place.country,
          ].where((e) => e != null && e.isNotEmpty).join(', ');

          // Notify parent about current location
          widget.onLocationSelected(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            locationName,
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Don't set error message for UI, just log it
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Load nearby cities even if current location fails
        await _loadNearbyCities();
      }
    }
  }

  Future<void> _loadNearbyCities() async {
    try {
      _suggestions = [
        if (_currentPosition != null)
          {
            'name': 'Current Location',
            'type': 'Current Location',
            'lat': _currentPosition!.latitude,
            'lng': _currentPosition!.longitude,
          },
        {
          'name': 'Antwerp, Belgium',
          'type': 'Popular City',
          'lat': 51.2194,
          'lng': 4.4025,
        },
        {
          'name': 'Brussels, Belgium',
          'type': 'Popular City',
          'lat': 50.8503,
          'lng': 4.3517,
        },
        {
          'name': 'Ghent, Belgium',
          'type': 'Popular City',
          'lat': 51.0543,
          'lng': 3.7174,
        },
        {
          'name': 'Bruges, Belgium',
          'type': 'Popular City',
          'lat': 51.2093,
          'lng': 3.2247,
        },
        {
          'name': 'Leuven, Belgium',
          'type': 'Popular City',
          'lat': 50.8798,
          'lng': 4.7005,
        },
      ];
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading nearby cities: $e');
    }
  }

  Future<void> _searchLocations(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
      });
      await _loadNearbyCities();
      return;
    }

    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _isSearching = true;
      _currentLocationError = null; // Clear any previous error
    });

    try {
      final results = await _locationService.searchLocation(query);
      
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching locations: $e');
      if (mounted) {
        setState(() {
          _suggestions = _isSearching ? [] : _suggestions;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Search worldwide by city, address or ZIP code',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _isSearching = false;
                              _currentLocationError = null; // Clear error when clearing search
                            });
                            _loadNearbyCities();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (value) {
                  _searchDebouncer?.cancel();
                  _searchDebouncer = Timer(const Duration(milliseconds: 500), () {
                    _searchLocations(value);
                  });
                },
              ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 300),
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
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  leading: Icon(
                    suggestion['type'] == 'Current Location' ? Icons.my_location :
                    suggestion['type'] == 'Popular City' ? Icons.location_city :
                    suggestion['type'] == 'City' ? Icons.location_city :
                    suggestion['type'] == 'Address' ? Icons.home :
                    suggestion['type'] == 'Region' ? Icons.map :
                    Icons.location_on,
                    color: suggestion['type'] == 'Current Location' ? Colors.blue : Colors.grey[600],
                  ),
                  title: Text(
                    suggestion['name'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    suggestion['type'],
                    style: TextStyle(
                      color: suggestion['type'] == 'Current Location' ? Colors.blue : Colors.grey[600],
                    ),
                  ),
                  onTap: () {
                    _controller.text = suggestion['name'];
                    widget.onLocationSelected(
                      suggestion['lat'],
                      suggestion['lng'],
                      suggestion['name'],
                    );
                    setState(() {
                      _suggestions = [];
                      _isSearching = false;
                      _currentLocationError = null; // Clear error when selecting location
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _searchDebouncer?.cancel();
    _controller.dispose();
    super.dispose();
  }
} 