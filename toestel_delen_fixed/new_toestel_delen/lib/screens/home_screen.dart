import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toesteldelen_project/constants/colors.dart';
import 'package:toesteldelen_project/models/appliance.dart';
import 'package:toesteldelen_project/providers/appliance_provider.dart';
import 'package:toesteldelen_project/providers/auth_provider.dart';
import 'package:toesteldelen_project/screens/add_appliance_screen.dart';
import 'package:toesteldelen_project/screens/appliance_detail_screen.dart';
import 'package:toesteldelen_project/screens/login_screen.dart';
import 'package:toesteldelen_project/screens/map_screen.dart';
import 'package:toesteldelen_project/screens/reservation_dashboard_screen.dart';
import 'package:toesteldelen_project/screens/profile_screen.dart';
import 'package:toesteldelen_project/screens/notifications_screen.dart';
import 'package:toesteldelen_project/widgets/appliance_card.dart';
import 'package:toesteldelen_project/services/map_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:toesteldelen_project/providers/location_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (kIsWeb) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: const Text('Share Device'),
            actions: [
              IconButton(
                icon: const Icon(Icons.map),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MapScreen()),
                  );
                },
              ),
              Consumer<AppAuthProvider>(
                builder: (context, auth, child) {
                  final user = auth.user;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: user != null
                        ? [
                            IconButton(
                              icon: const Icon(Icons.notifications),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const NotificationsScreen()),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.dashboard),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ReservationDashboardScreen()),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.person),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const ProfileScreen()),
                                );
                              },
                            ),
                          ]
                        : [
                            TextButton.icon(
                              icon: const Icon(Icons.login, color: Colors.white),
                              label: const Text('Login',
                                  style: TextStyle(color: Colors.white)),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const LoginScreen()),
                                );
                              },
                            ),
                          ],
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.white,
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search appliances...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      value: _selectedCategory,
                      items: ['All', 'Cleaning', 'Gardening', 'Cooking', 'Tools']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    if (locationProvider.isLocationSelected()) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    locationProvider.selectedLocationName!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Within ${locationProvider.selectedRadius.round()} km',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                locationProvider.clearSelection();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Appliance>>(
                  stream: Provider.of<ApplianceProvider>(context).getAppliances(),
                  builder: (context, AsyncSnapshot<List<Appliance>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No appliances available'));
                    }

                    List<Appliance> filteredAppliances =
                        snapshot.data!.where((appliance) {
                      bool categoryMatch = _selectedCategory == 'All' ||
                          appliance.category == _selectedCategory;
                      bool searchMatch =
                          appliance.title.toLowerCase().contains(_searchQuery) ||
                              appliance.description
                                  .toLowerCase()
                                  .contains(_searchQuery);

                      bool distanceMatch = true;
                      if (locationProvider.isLocationSelected() &&
                          appliance.location.contains(',')) {
                        try {
                          List<String> coordinates = appliance.location.split(',');
                          double lat = double.parse(coordinates[0].trim());
                          double lng = double.parse(coordinates[1].trim());

                          double distanceInKm = locationProvider.calculateDistanceToSelected(lat, lng);
                          distanceMatch = distanceInKm <= locationProvider.selectedRadius;
                        } catch (e) {
                          print('Error calculating distance: $e');
                        }
                      }

                      return categoryMatch && searchMatch && distanceMatch;
                    }).toList();

                    return ListView.builder(
                      itemCount: filteredAppliances.length,
                      itemBuilder: (context, index) {
                        return ApplianceCard(
                          appliance: filteredAppliances[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ApplianceDetailScreen(
                                    appliance: filteredAppliances[index]),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: Consumer<AppAuthProvider>(
            builder: (context, auth, child) {
              if (auth.user == null) return const SizedBox();
              return FloatingActionButton(
                backgroundColor: AppColors.primary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddApplianceScreen()),
                  );
                },
                child: const Icon(Icons.add),
              );
            },
          ),
        );
      },
    );
  }
}