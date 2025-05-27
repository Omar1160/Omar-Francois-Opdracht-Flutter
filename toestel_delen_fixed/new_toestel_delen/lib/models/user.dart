import 'package:firebase_auth/firebase_auth.dart' show User;

class AppUser {
  final String id;
  final String email;
  final String name;
  final String? address;
  final String? phoneNumber;
  final bool isVerified;
  final double trustScore;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.address,
    this.phoneNumber,
    this.isVerified = false,
    this.trustScore = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'address': address,
      'phoneNumber': phoneNumber,
      'isVerified': isVerified,
      'trustScore': trustScore,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      address: map['address'],
      phoneNumber: map['phoneNumber'],
      isVerified: map['isVerified'] ?? false,
      trustScore: (map['trustScore'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory AppUser.fromFirebaseUser(User? user) {
    if (user == null) {
      throw Exception('User cannot be null');
    }
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      name: '',
    );
  }
}