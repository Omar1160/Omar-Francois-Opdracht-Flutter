import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toesteldelen_project/constants/colors.dart';
import 'package:toesteldelen_project/models/appliance.dart';
import 'package:toesteldelen_project/models/reservation.dart';
import 'package:toesteldelen_project/providers/appliance_provider.dart';
import 'package:toesteldelen_project/providers/auth_provider.dart';
import 'package:toesteldelen_project/providers/reservation_provider.dart';
import 'package:toesteldelen_project/screens/add_appliance_screen.dart';
import 'package:toesteldelen_project/screens/profile_screen.dart';
import 'package:toesteldelen_project/screens/reviews_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ReservationDashboardScreen extends StatelessWidget {
  const ReservationDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppAuthProvider>(context).user;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please log in to view your dashboard'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: const Text('Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                );
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppColors.secondary,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Your Appliances'),
              Tab(text: 'Your Reservations'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Your Appliances Tab
            StreamBuilder<List<Appliance>>(
              stream:
                  Provider.of<ApplianceProvider>(context).getUserAppliances(user.id),
              builder: (context, AsyncSnapshot<List<Appliance>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final appliances = snapshot.data ?? [];
                if (appliances.isEmpty) {
                  return const Center(child: Text('No appliances added yet.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: appliances.length,
                  itemBuilder: (context, index) {
                    final appliance = appliances[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: appliance.imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (context, url, error) =>
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
                                  const SizedBox(height: 4),
                                  Text(
                                    'Category: ${appliance.category}',
                                    style: TextStyle(
                                      color: AppColors.text.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: AppColors.accent),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AddApplianceScreen(appliance: appliance),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Appliance'),
                                        content: const Text(
                                            'Are you sure you want to delete this appliance?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Delete',
                                                style:
                                                    TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await Provider.of<ApplianceProvider>(
                                              context,
                                              listen: false)
                                          .deleteAppliance(appliance.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            // Your Reservations Tab
            StreamBuilder<List<Reservation>>(
              stream: Provider.of<ReservationProvider>(context)
                  .getReservationsForUser(user.id, isOwner: false),
              builder: (context, AsyncSnapshot<List<Reservation>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final reservations = snapshot.data ?? [];
                if (reservations.isEmpty) {
                  return const Center(child: Text('No reservations yet.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: reservations.length,
                  itemBuilder: (context, index) {
                    final reservation = reservations[index];
                    return FutureBuilder<Appliance>(
                      future: FirebaseFirestore.instance
                          .collection('appliances')
                          .doc(reservation.applianceId)
                          .get()
                          .then((doc) => Appliance.fromMap(doc.data()!)),
                      builder: (context, AsyncSnapshot<Appliance> applianceSnapshot) {
                        if (applianceSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const ListTile(
                            title: Text('Loading...'),
                          );
                        }
                        if (applianceSnapshot.hasError) {
                          return ListTile(
                            title: const Text('Error loading appliance'),
                            subtitle: Text('Error: ${applianceSnapshot.error}'),
                          );
                        }
                        final appliance = applianceSnapshot.data!;
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: appliance.imageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) =>
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
                                        reservation.dateRangeString,
                                        style: TextStyle(
                                          color: AppColors.text.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Total: €${reservation.totalPrice}',
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (reservation.isCompleted)
                                        const Text(
                                          'Completed',
                                          style: TextStyle(color: Colors.green),
                                        ),
                                    ],
                                  ),
                                ),
                                if (!reservation.isCompleted)
                                  ElevatedButton(
                                    onPressed: () async {
                                      await Provider.of<ReservationProvider>(
                                              context,
                                              listen: false)
                                          .markReservationCompleted(reservation.id);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Reservation marked as completed!')),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accent,
                                    ),
                                    child: const Text('Complete'),
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ReviewsScreen(
                                              applianceId: appliance.id,
                                              toUserId: reservation.renterId),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.secondary,
                                    ),
                                    child: const Text('Review'),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}