import 'package:flutter/material.dart';
import 'package:toesteldelen_project/constants/colors.dart';

class LocationSearchWidget extends StatelessWidget {
  final String? selectedLocation;
  final double radius;
  final Function(double) onRadiusChanged;
  final VoidCallback onLocationTap;

  const LocationSearchWidget({
    Key? key,
    this.selectedLocation,
    required this.radius,
    required this.onRadiusChanged,
    required this.onLocationTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search by city, neighborhood or ZIP code.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          // Location Input
          InkWell(
            onTap: onLocationTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey.shade600),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        selectedLocation ?? 'Select location',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Radius Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Radius',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${radius.round()} kilometers',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: radius,
                  min: 1,
                  max: 100,
                  divisions: 99,
                  activeColor: AppColors.primary,
                  inactiveColor: Colors.grey.shade300,
                  onChanged: onRadiusChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 