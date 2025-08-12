import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:splitzy/models/user_model.dart';
import 'package:logger/logger.dart';
import 'dart:async';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // Instance variables with consistent naming
  User? _currentFirebaseUser;
  SplitzyUser? _currentSplitzyUser;
  GoogleSignInAccount? _currentGoogleUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isGoogleSignInInitialized = false;
  bool _isSigningIn = false;

  // Static constants for timeouts
  static const int _signInTimeout = 30;
  static const int _saveUserTimeout = 20;
  static const int _silentSignInTimeout = 10;

  // Getters
  User? get currentFirebaseUser => _currentFirebaseUser ?? _auth.currentUser;
  SplitzyUser? get currentUser => _currentSplitzyUser;
  GoogleSignInAccount? get currentGoogleUser => _currentGoogleUser;
  bool get isSignedIn => currentFirebaseUser != null && _currentSplitzyUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => currentFirebaseUser?.uid;
  bool get isSigningIn => _isSigningIn;

  AuthService() {
    _init();
  }

  void _init() {
    try {
      _currentFirebaseUser = _auth.currentUser;
      _auth.authStateChanges().listen(_onAuthStateChanged);
      _initializeGoogleSignIn();
      if (_currentFirebaseUser != null) {
        _loadCurrentUser();
      }
    } catch (e) {
      _logger.e('Error initializing AuthService: $e');
    }
  }

  Future<void> _initializeGoogleSignIn() async {
    if (_isGoogleSignInInitialized) return;

    try {
      await _googleSignIn.signInSilently();
      _isGoogleSignInInitialized = true;
      _logger.i('Google Sign-In initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize Google Sign-In: $e');
      _isGoogleSignInInitialized = false;
    }
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      await _initializeGoogleSignIn();
    }
    if (!_isGoogleSignInInitialized) {
      throw Exception('Google Sign-In initialization failed');
    }
  }

  void _onAuthStateChanged(User? user) {
    _currentFirebaseUser = user;
    if (user != null) {
      _loadCurrentUser();
    } else {
      _currentSplitzyUser = null;
      _currentGoogleUser = null;
    }
    notifyListeners();
  }

  Future<void> _loadCurrentUser() async {
    if (_currentFirebaseUser == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentFirebaseUser!.uid)
          .get();

      if (doc.exists) {
        _currentSplitzyUser = SplitzyUser.fromMap(doc.data()!);
      } else {
        _currentSplitzyUser = SplitzyUser(
          uid: _currentFirebaseUser!.uid,
          name: _currentFirebaseUser!.displayName ?? '',
          email: _currentFirebaseUser!.email ?? '',
          photoUrl: _currentFirebaseUser!.photoURL,
        );
        await _saveUserToFirestore(_currentSplitzyUser!);
      }
      notifyListeners();
    } catch (e) {
      _logger.e('Error loading current user: $e');
      _setError('Failed to load user data');
    }
  }

  Future<void> _saveUserToFirestore(SplitzyUser user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toMap())
          .timeout(Duration(seconds: _saveUserTimeout));
    } on TimeoutException {
      _logger.e('Timeout saving user to Firestore');
      throw TimeoutException('Failed to save user data');
    } catch (e) {
      _logger.e('Error saving user to Firestore: $e');
      rethrow;
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _setError(null);
  }

  Future<UserCredential?> signInWithGoogle() async {
    if (_isSigningIn) return null;
    
    try {
      _isSigningIn = true;
      _setLoading(true);
      _setError(null);

      await _ensureGoogleSignInInitialized();

      final GoogleSignInAccount? googleUser = await _googleSignIn
          .signIn()
          .timeout(Duration(seconds: _signInTimeout));

      if (googleUser == null) {
        _setError('Sign-in was cancelled');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication
          .timeout(Duration(seconds: _signInTimeout));

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final UserCredential userCredential = await _auth
          .signInWithCredential(credential)
          .timeout(Duration(seconds: _signInTimeout));

      _currentGoogleUser = googleUser;

      if (userCredential.user != null) {
        final splitzyUser = SplitzyUser(
          uid: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? googleUser.displayName ?? '',
          email: userCredential.user!.email ?? googleUser.email,
          photoUrl: userCredential.user!.photoURL ?? googleUser.photoUrl,
        );

        await _saveUserToFirestore(splitzyUser);
        _currentSplitzyUser = splitzyUser;
      }

      _logger.i('Google sign-in successful');
      return userCredential;

    } on TimeoutException {
      _logger.e('Sign-in operation timed out');
      _setError('Sign-in timed out. Please try again.');
      await _handleSignInCleanup();
      return null;

    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth error: ${e.code} - ${e.message}');
      _setError(_getAuthErrorMessage(e.code));
      await _handleSignInCleanup();
      return null;

    } catch (e) {
      _logger.e('Google sign-in error: $e');
      _setError('Sign-in failed. Please try again.');
      await _handleSignInCleanup();
      return null;

    } finally {
      _setLoading(false);
      _isSigningIn = false;
    }
  }

  Future<void> _handleSignInCleanup() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      _logger.w('Error during sign-in cleanup: $e');
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(Duration(seconds: _signInTimeout));

      _logger.i('Email sign-in successful');
      return userCredential;

    } on TimeoutException {
      _setError('Sign-in timed out. Please try again.');
      return null;

    } on FirebaseAuthException catch (e) {
      _logger.e('Email sign-in error: ${e.code} - ${e.message}');
      _setError(_getAuthErrorMessage(e.code));
      return null;

    } finally {
      _setLoading(false);
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(Duration(seconds: _signInTimeout));

      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);

        final splitzyUser = SplitzyUser(
          uid: userCredential.user!.uid,
          name: name,
          email: email,
        );

        await _saveUserToFirestore(splitzyUser);
        _currentSplitzyUser = splitzyUser;
      }

      _logger.i('Account creation successful');
      return userCredential;

    } on TimeoutException {
      _setError('Operation timed out. Please try again.');
      return null;

    } on FirebaseAuthException catch (e) {
      _logger.e('Account creation error: ${e.code} - ${e.message}');
      _setError(_getAuthErrorMessage(e.code));
      return null;

    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInSilently() async {
    try {
      await _ensureGoogleSignInInitialized();

      final GoogleSignInAccount? googleUser = await _googleSignIn
          .signInSilently()
          .timeout(Duration(seconds: _silentSignInTimeout));

      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      _currentGoogleUser = googleUser;

      if (userCredential.user != null) {
        await _loadCurrentUser();
        return true;
      }

      return false;

    } catch (e) {
      _logger.w('Silent sign-in failed: $e');
      await _handleSignInCleanup();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      _setError(null);

      await Future.wait([
        _googleSignIn.signOut(),
        _auth.signOut(),
      ]);

      _currentSplitzyUser = null;
      _currentGoogleUser = null;
      _currentFirebaseUser = null;
      
      _logger.i('Sign out successful');

    } catch (e) {
      _logger.e('Sign out error: $e');
      _setError('Failed to sign out');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount() async {
    if (_currentFirebaseUser == null) {
      _setError('No user is currently signed in');
      return;
    }

    try {
      _setLoading(true);
      _setError(null);

      final userId = _currentFirebaseUser!.uid;

      // Delete user data from Firestore
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .delete()
            .timeout(Duration(seconds: _saveUserTimeout));
        
        _logger.i('User data deleted from Firestore');
      } catch (e) {
        _logger.w('Failed to delete user data from Firestore: $e');
        // Continue with account deletion
      }

      // Delete Firebase Auth account
      await _currentFirebaseUser!.delete();
      
      // Clear local state
      _currentSplitzyUser = null;
      _currentGoogleUser = null;
      _currentFirebaseUser = null;

      _logger.i('Account deletion successful');

    } on FirebaseAuthException catch (e) {
      _logger.e('Account deletion error: ${e.code} - ${e.message}');
      _setError(_getAuthErrorMessage(e.code));
      rethrow;

    } catch (e) {
      _logger.e('Account deletion error: $e');
      _setError('Failed to delete account');
      rethrow;

    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserProfile({
    String? name,
    String? photoUrl,
    String? phoneNumber,
  }) async {
    if (_currentSplitzyUser == null || _currentFirebaseUser == null) {
      _setError('No user is currently signed in');
      return;
    }

    try {
      _setLoading(true);
      _setError(null);

      final updatedUser = _currentSplitzyUser!.copyWith(
        name: name ?? _currentSplitzyUser!.name,
        photoUrl: photoUrl ?? _currentSplitzyUser!.photoUrl,
        phoneNumber: phoneNumber ?? _currentSplitzyUser!.phoneNumber,
      );

      if (name != null) {
        await _currentFirebaseUser!.updateDisplayName(name);
      }

      await _saveUserToFirestore(updatedUser);
      _currentSplitzyUser = updatedUser;

      _logger.i('Profile update successful');

    } catch (e) {
      _logger.e('Profile update error: $e');
      _setError('Failed to update profile');
      rethrow;

    } finally {
      _setLoading(false);
    }
  }

  Future<String?> getAccessToken() async {
    if (_currentGoogleUser == null) return null;

    try {
      final GoogleSignInAuthentication auth = await _currentGoogleUser!.authentication;
      return auth.accessToken;
    } catch (e) {
      _logger.e('Failed to get access token: $e');
      return null;
    }
  }

  Future<SplitzyUser?> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(Duration(seconds: _signInTimeout));

      return doc.exists ? SplitzyUser.fromMap(doc.data()!) : null;

    } catch (e) {
      _logger.e('Error getting user by ID: $e');
      return null;
    }
  }

  Future<List<SplitzyUser>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('email', isLessThan: '${query.toLowerCase()}\uf8ff')
          .limit(10)
          .get()
          .timeout(Duration(seconds: _signInTimeout));

      return snapshot.docs
          .map((doc) => SplitzyUser.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

    } catch (e) {
      _logger.e('Error searching users: $e');
      return [];
    }
  }

  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email address but different sign-in credentials.';
      case 'invalid-credential':
        return 'The credential provided is malformed or has expired.';
      case 'network-request-failed':
        return 'A network error occurred. Please check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}