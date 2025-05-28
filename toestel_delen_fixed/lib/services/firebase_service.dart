import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:toesteldelen_project/models/appliance.dart';
import 'package:toesteldelen_project/models/reservation.dart';
import 'package:toesteldelen_project/models/user.dart';
import 'package:toesteldelen_project/models/review.dart';
import 'package:toesteldelen_project/models/notification.dart';
import 'package:uuid/uuid.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Authentication
  Future<AppUser> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Login failed');
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        final newUser = AppUser(
          id: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          name: '',
        );
        await _firestore
            .collection('users')
            .doc(newUser.id)
            .set(newUser.toMap());
        return newUser;
      }

      return AppUser.fromMap(userDoc.data() as Map<String, dynamic>);
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid email or password';
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<AppUser> signUp(String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Registration failed');
      }

      final newUser = AppUser(
        id: userCredential.user!.uid,
        email: userCredential.user!.email ?? '',
        name: name,
      );

      await _firestore.collection('users').doc(newUser.id).set(newUser.toMap());

      return newUser;
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        message = 'An account already exists for this email';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<void> createUser(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user: ${e.toString()}');
    }
  }

  Future<AppUser> getUser(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }
      return AppUser.fromMap(userDoc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch user: ${e.toString()}');
    }
  }

  Future<void> updateUser(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Appliance Management
  Future<String> uploadImage(File image) async {
    try {
      String fileName = const Uuid().v4();
      Reference ref = _storage.ref().child('appliance_images/$fileName');

      // Explicitly set metadata to null to avoid plugin issues
      UploadTask uploadTask = ref.putFile(
        image,
        SettableMetadata(
          contentType: 'image/jpeg', // Specify content type explicitly
          cacheControl: null,
          contentDisposition: null,
          contentEncoding: null,
          contentLanguage: null,
          customMetadata: null,
        ),
      );

      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  Future<void> addAppliance(Appliance appliance) async {
    try {
      await _firestore
          .collection('appliances')
          .doc(appliance.id)
          .set(appliance.toMap());
    } catch (e) {
      throw Exception('Failed to add appliance: ${e.toString()}');
    }
  }

  Future<void> updateAppliance(Appliance appliance) async {
    try {
      await _firestore
          .collection('appliances')
          .doc(appliance.id)
          .update(appliance.toMap());
    } catch (e) {
      throw Exception('Failed to update appliance: ${e.toString()}');
    }
  }

  Future<void> deleteAppliance(String applianceId) async {
    try {
      final applianceDoc =
          await _firestore.collection('appliances').doc(applianceId).get();
      if (applianceDoc.exists) {
        final appliance = Appliance.fromMap(applianceDoc.data()!);

        if (appliance.imageUrl.isNotEmpty) {
          try {
            final fileRef = _storage.refFromURL(appliance.imageUrl);
            await fileRef.delete();
          } catch (e) {
            print('Error deleting image: $e');
          }
        }

        final reservationsQuery = await _firestore
            .collection('reservations')
            .where('applianceId', isEqualTo: applianceId)
            .get();

        final batch = _firestore.batch();
        for (var doc in reservationsQuery.docs) {
          batch.delete(doc.reference);
        }

        batch.delete(_firestore.collection('appliances').doc(applianceId));

        await batch.commit();
      } else {
        throw Exception('Appliance not found');
      }
    } catch (e) {
      throw Exception('Failed to delete appliance: ${e.toString()}');
    }
  }

  Stream<List<Appliance>> getAppliances() {
    return _firestore.collection('appliances').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Appliance.fromMap(doc.data())).toList();
    });
  }

  Stream<List<Appliance>> getUserAppliances(String userId) {
    return _firestore
        .collection('appliances')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Appliance.fromMap(doc.data())).toList();
    });
  }

  // Reservation Management
  Future<void> createReservation(Reservation reservation) async {
    try {
      await _firestore
          .collection('reservations')
          .doc(reservation.id)
          .set(reservation.toMap());
    } catch (e) {
      throw Exception('Failed to create reservation: ${e.toString()}');
    }
  }

  Future<void> markReservationCompleted(String reservationId) async {
    try {
      await _firestore
          .collection('reservations')
          .doc(reservationId)
          .update({'isCompleted': true});
    } catch (e) {
      throw Exception(
          'Failed to mark reservation as completed: ${e.toString()}');
    }
  }

  Stream<List<Reservation>> getReservationsForUser(String userId,
      {bool isOwner = false}) {
    return _firestore
        .collection('reservations')
        .where(isOwner ? 'ownerId' : 'renterId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Reservation.fromMap(doc.data()))
          .toList();
    });
  }

  // Review Management
  Future<void> createReview(Review review) async {
    try {
      await _firestore.collection('reviews').doc(review.id).set(review.toMap());

      // Update user's trust score
      final reviews = await _firestore
          .collection('reviews')
          .where('reviewerId', isEqualTo: review.reviewerId)
          .get();
      double averageRating = reviews.docs
              .map((doc) => Review.fromMap(doc.data()).rating)
              .fold(0.0, (sum, rating) => sum + rating) /
          reviews.docs.length;

      await _firestore.collection('users').doc(review.reviewerId).update({
        'trustScore': averageRating,
      });
    } catch (e) {
      throw Exception('Failed to create review: ${e.toString()}');
    }
  }

  Stream<List<Review>> getReviewsForAppliance(String applianceId) {
    return _firestore
        .collection('reviews')
        .where('applianceId', isEqualTo: applianceId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Review.fromMap(doc.data())).toList();
    });
  }

  // Notification Management
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    try {
      String id = DateTime.now().millisecondsSinceEpoch.toString();
      AppNotification notification = AppNotification(
        id: id,
        userId: userId,
        title: title,
        message: message,
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection('notifications')
          .doc(id)
          .set(notification.toMap());
    } catch (e) {
      throw Exception('Failed to create notification: ${e.toString()}');
    }
  }

  Stream<List<AppNotification>> getNotificationsForUser(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppNotification.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: ${e.toString()}');
    }
  }
}
