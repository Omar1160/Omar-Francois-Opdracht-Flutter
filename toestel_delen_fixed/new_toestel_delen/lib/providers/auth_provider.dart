import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:toesteldelen_project/models/user.dart';
import 'package:toesteldelen_project/services/firebase_service.dart';

class AppAuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  AppUser? _user;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isSigningUp = false; // Flag to track if signUp is in progress

  AppAuthProvider() {
    _auth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        try {
          // Fetch the user from Firestore with a slight delay to ensure data is written
          await Future.delayed(const Duration(milliseconds: 500));
          final userData = await _firebaseService.getUser(firebaseUser.uid);
          _user = userData;
          debugPrint('User fetched from Firestore: ${_user!.name}');
        } catch (e) {
          if (e.toString().contains('User not found')) {
            if (_isSigningUp) {
              debugPrint(
                  'User not found but signUp is in progress — waiting for proper creation');
              return; // ✅ EXIT: avoid creating a user with empty name
            }

            debugPrint(
                'User not found in Firestore, creating new user (not during signup)');
            final newUser = AppUser(
              id: firebaseUser.uid,
              email: firebaseUser.email ?? '',
              name: firebaseUser.displayName ?? '',
              isVerified: false,
              trustScore: 0.0,
            );
            await _firebaseService.createUser(newUser);
            _user = newUser;
            debugPrint(
                'New user created during authStateChanges: ${_user!.name}');
          } else {
            _errorMessage = 'Error fetching user: $e';
            debugPrint(_errorMessage);
          }
        }
      } else {
        _user = null;
        debugPrint('No user logged in');
      }
      notifyListeners();
    }, onError: (error) {
      debugPrint('Auth state changes error: $error');
      _errorMessage = 'Error monitoring auth state: $error';
      notifyListeners();
    });
  }

  AppUser? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<bool> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Login failed');
      }

      // Wait for the authStateChanges listener to update the user
      await Future.delayed(const Duration(milliseconds: 1000));

      if (_user == null) {
        throw Exception('User data could not be fetched after login');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on auth.FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      throw Exception(_errorMessage);
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Login failed: ${e.toString()}';
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    try {
      _isLoading = true;
      _isSigningUp = true; // Set the flag to true
      _errorMessage = null;
      notifyListeners();

      debugPrint('Starting signup with email: $email, name: $name');

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
        name: name, // Ensure the name is set here
        isVerified: false,
        trustScore: 0.0,
      );

      debugPrint('Creating user in Firestore with name: ${newUser.name}');

      // Ensure user is created in Firestore
      await _firebaseService.createUser(newUser);

      debugPrint('User created in Firestore, fetching user to verify');

      // Fetch the user to ensure the data is correct with a delay
      await Future.delayed(const Duration(milliseconds: 500));
      final userData = await _firebaseService.getUser(userCredential.user!.uid);
      _user = userData;

      debugPrint('Fetched user after signup: ${_user!.name}');

      if (_user == null || _user!.name != name) {
        throw Exception(
            'User data could not be fetched or name was not saved correctly');
      }

      _isSigningUp = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } on auth.FirebaseAuthException catch (e) {
      _isLoading = false;
      _isSigningUp = false;
      _errorMessage = _getErrorMessage(e.code);
      notifyListeners();
      throw Exception(_errorMessage);
    } catch (e) {
      _isLoading = false;
      _isSigningUp = false;
      _errorMessage = 'Registration failed: ${e.toString()}';
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  Future<void> updateUser(AppUser updatedUser) async {
    try {
      debugPrint('Updating user with name: ${updatedUser.name}');
      await _firebaseService.updateUser(updatedUser);
      _user = updatedUser;
      debugPrint('User updated in Firestore: ${_user!.name}');
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update user: ${e.toString()}';
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Sign out failed: ${e.toString()}';
      notifyListeners();
      throw Exception(_errorMessage);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'email-already-in-use':
        return 'An account already exists for this email';
      case 'weak-password':
        return 'Password is too weak';
      default:
        return 'Authentication failed: $code';
    }
  }
}
