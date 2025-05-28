import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toesteldelen_project/constants/colors.dart';
import 'package:toesteldelen_project/models/appliance.dart';
import 'package:toesteldelen_project/providers/auth_provider.dart';
import 'package:toesteldelen_project/providers/reservation_provider.dart';
import 'package:toesteldelen_project/screens/login_screen.dart';
import 'package:toesteldelen_project/screens/reviews_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ApplianceDetailScreen extends StatefulWidget {
  final Appliance appliance;

  const ApplianceDetailScreen({Key? key, required this.appliance})
      : super(key: key);

  @override
  State<ApplianceDetailScreen> createState() => _ApplianceDetailScreenState();
}

class _ApplianceDetailScreenState extends State<ApplianceDetailScreen> {
  DateTimeRange? _selectedDateRange;
  bool _showOwnerContact = false;

  Future<String> _getOwnerEmail(String ownerId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(ownerId)
        .get();
    if (userDoc.exists) {
      return userDoc.data()!['email'] ?? 'owner@example.com';
    }
    return 'owner@example.com';
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AppAuthProvider>(context).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(widget.appliance.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReviewsScreen(applianceId: widget.appliance.id),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'appliance-${widget.appliance.id}',
              child: CachedNetworkImage(
                imageUrl: widget.appliance.imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.contain, // Changed from BoxFit.cover to BoxFit.contain
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.appliance.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                      Text(
                        '€${widget.appliance.pricePerDay}/day',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.appliance.description,
                    style: TextStyle(color: AppColors.text.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Location: ${widget.appliance.location}',
                          style:
                              TextStyle(color: AppColors.text.withOpacity(0.7)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Availability:',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text),
                  ),
                  const SizedBox(height: 8),
                  if (widget.appliance.availability.isNotEmpty)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_selectedDateRange != null
                          ? '${DateFormat('MMM d, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_selectedDateRange!.end)}'
                          : 'Select Dates'),
                      onPressed: () async {
                        if (widget.appliance.availability.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No available dates')),
                          );
                          return;
                        }

                        List<DateTime> availableDates = widget
                            .appliance.availability
                            .map((date) => DateTime.parse(date))
                            .toList();
                        availableDates.sort();

                        final DateTimeRange? picked = await showDateRangePicker(
                          context: context,
                          firstDate: availableDates.first,
                          lastDate: availableDates.last
                              .add(const Duration(days: 365)),
                          initialDateRange: _selectedDateRange ??
                              DateTimeRange(
                                start: availableDates.first,
                                end: availableDates.first
                                    .add(const Duration(days: 1)),
                              ),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: AppColors.primary,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: AppColors.text,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (picked != null) {
                          setState(() {
                            _selectedDateRange = picked;
                          });
                        }
                      },
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: widget.appliance.availability.map((date) {
                      return Chip(label: Text(date));
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  if (_showOwnerContact && user != null)
                    FutureBuilder<String>(
                      future: _getOwnerEmail(widget.appliance.ownerId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Owner Contact Information',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.email, size: 18),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () async {
                                      final Uri emailLaunchUri = Uri(
                                        scheme: 'mailto',
                                        path: snapshot.data,
                                        query:
                                            'subject=Regarding your ${widget.appliance.title} rental',
                                      );

                                      if (await canLaunchUrl(emailLaunchUri)) {
                                        await launchUrl(emailLaunchUri);
                                      }
                                    },
                                    child: Text(
                                      snapshot.data ?? 'owner@example.com',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  if (user == null)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: AppColors.primary),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Please log in to reserve this appliance',
                                  style: TextStyle(color: AppColors.text),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 100, vertical: 16),
                          ),
                          child: const Text(
                            'Login to Reserve',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  else if (widget.appliance.availability.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.orange),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'This appliance is currently not available',
                              style: TextStyle(color: AppColors.text),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: () async {
                        if (_selectedDateRange == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Please select dates for your reservation')),
                          );
                          return;
                        }

                        final int days =
                            _selectedDateRange!.duration.inDays + 1;
                        final double totalPrice =
                            days * widget.appliance.pricePerDay;

                        try {
                          await Provider.of<ReservationProvider>(context, listen: false)
                              .createReservation(
                            applianceId: widget.appliance.id,
                            renterId: user.id,
                            ownerId: widget.appliance.ownerId,
                            startDate: _selectedDateRange!.start,
                            endDate: _selectedDateRange!.end,
                            totalPrice: totalPrice,
                          );

                          setState(() {
                            _showOwnerContact = true;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Reservation created successfully!')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 100, vertical: 16),
                      ),
                      child: Text(
                        _selectedDateRange != null
                            ? 'Reserve for €${(widget.appliance.pricePerDay * (_selectedDateRange!.duration.inDays + 1)).toStringAsFixed(2)}'
                            : 'Reserve Now',
                        style: const TextStyle(
                            fontSize: 18, color: AppColors.text),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}