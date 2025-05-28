import 'package:flutter/material.dart';
import 'package:toesteldelen_project/models/reservation.dart';
import 'package:toesteldelen_project/services/firebase_service.dart';

class ReservationProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> createReservation({
    required String applianceId,
    required String renterId,
    required String ownerId,
    required DateTime startDate,
    required DateTime endDate,
    required double totalPrice,
  }) async {
    try {
      String id = DateTime.now().millisecondsSinceEpoch.toString();
      Reservation reservation = Reservation(
        id: id,
        applianceId: applianceId,
        renterId: renterId,
        ownerId: ownerId,
        startDate: startDate,
        endDate: endDate,
        totalPrice: totalPrice,
      );
      await _firebaseService.createReservation(reservation);

      // Send notifications
      await _firebaseService.createNotification(
        userId: ownerId,
        title: 'New Reservation',
        message:
            'You have a new reservation for your appliance from ${startDate.toString().split(' ')[0]} to ${endDate.toString().split(' ')[0]}.',
      );

      await _firebaseService.createNotification(
        userId: renterId,
        title: 'Reservation Confirmation',
        message:
            'Your reservation from ${startDate.toString().split(' ')[0]} to ${endDate.toString().split(' ')[0]} has been created.',
      );

      notifyListeners();
    } catch (e) {
      print('Create reservation error: $e');
      rethrow;
    }
  }

  Future<void> markReservationCompleted(String reservationId) async {
    try {
      await _firebaseService.markReservationCompleted(reservationId);
      notifyListeners();
    } catch (e) {
      print('Error marking reservation as completed: $e');
      rethrow;
    }
  }

  Stream<List<Reservation>> getReservationsForUser(String userId,
      {bool isOwner = false}) {
    return _firebaseService.getReservationsForUser(userId, isOwner: isOwner);
  }
}
