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

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  double _distance = 5.0;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
  }

  Future<void> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _distance,
                        min: 1,
                        max: 50,
                        divisions: 49,
                        label: 'Within ${_distance.round()} km',
                        onChanged: (value) {
                          setState(() {
                            _distance = value;
                          });
                        },
                        activeColor: AppColors.primary,
                        inactiveColor: Colors.grey[300],
                      ),
                    ),
                    Text('${_distance.round()} km',
                        style: const TextStyle(color: AppColors.text)),
                  ],
                ),
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
                  if (_currentPosition != null &&
                      appliance.location.contains(',')) {
                    try {
                      List<String> coordinates = appliance.location.split(',');
                      double lat = double.parse(coordinates[0].trim());
                      double lng = double.parse(coordinates[1].trim());

                      double distanceInMeters = Geolocator.distanceBetween(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                          lat,
                          lng);

                      double distanceInKm = distanceInMeters / 1000;
                      distanceMatch = distanceInKm <= _distance;
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
  }
}