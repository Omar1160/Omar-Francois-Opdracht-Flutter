import 'dart:io';
import 'package:flutter/material.dart';
import 'package:toesteldelen_project/models/appliance.dart';
import 'package:toesteldelen_project/services/firebase_service.dart';
import 'package:geolocator/geolocator.dart';

class ApplianceProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  Stream<List<Appliance>> getAppliances() {
    return _firebaseService.getAppliances();
  }

  Stream<List<Appliance>> getUserAppliances(String userId) {
    return _firebaseService.getUserAppliances(userId);
  }

  Future<String> addAppliance({
    required String title,
    required String description,
    required double pricePerDay,
    required String category,
    required String ownerId,
    required File image,
    required String location,
    required List<String> availability,
  }) async {
    try {
      String imageUrl = await _firebaseService.uploadImage(image);

      String finalLocation = location;
      if (finalLocation.isEmpty) {
        try {
          Position position = await Geolocator.getCurrentPosition();
          finalLocation = '${position.latitude}, ${position.longitude}';
        } catch (e) {
          print('Error getting location: $e');
          finalLocation = '50.8503, 4.3517'; // Default to Brussels, Belgium
        }
      }

      String id = DateTime.now().millisecondsSinceEpoch.toString();
      Appliance appliance = Appliance(
        id: id,
        title: title,
        description: description,
        pricePerDay: pricePerDay,
        category: category,
        ownerId: ownerId,
        imageUrl: imageUrl,
        location: finalLocation,
        availability: availability,
      );

      await _firebaseService.addAppliance(appliance);
      notifyListeners();
      return imageUrl; // Return the imageUrl for use in AddApplianceScreen
    } catch (e) {
      print('Error adding appliance: $e');
      rethrow;
    }
  }

  Future<void> updateAppliance(Appliance appliance) async {
    try {
      await _firebaseService.updateAppliance(appliance);
      notifyListeners();
    } catch (e) {
      print('Error updating appliance: $e');
      rethrow;
    }
  }

  Future<void> deleteAppliance(String applianceId) async {
    try {
      await _firebaseService.deleteAppliance(applianceId);
      notifyListeners();
    } catch (e) {
      print('Error deleting appliance: $e');
      rethrow;
    }
  }
}