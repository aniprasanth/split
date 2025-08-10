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

  User? _currentFirebaseUser;
  SplitzyUser? _currentSplitzyUser;
  GoogleSignInAccount? _currentGoogleUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isGoogleSignInInitialized = false;
  bool _isSigningIn = false;

  // Getters
  User? get currentFirebaseUser => _currentFirebaseUser ?? _auth.currentUser;
  SplitzyUser? get currentUser => _currentSplitzyUser;
  GoogleSignInAccount? get currentGoogleUser => _currentGoogleUser;
  bool get isSignedIn => currentFirebaseUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentUserId => currentFirebaseUser?.uid;
  bool get isSigningIn => _isSigningIn;

  AuthService() {
    _init();
  }

  void _init() {
    _currentFirebaseUser = _auth.currentUser;
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _initializeGoogleSignIn();
    if (_currentFirebaseUser != null) {
      _loadCurrentUser();
    }
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
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
    }
  }

  Future<void> _saveUserToFirestore(SplitzyUser user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toMap());
    } catch (e) {
      _logger.e('Error saving user to Firestore: $e');
      rethrow;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _setError(null);
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (_isSigningIn) return null;
      _isSigningIn = true;
      _setLoading(true);
      _setError(null);

      await _ensureGoogleSignInInitialized();

      final GoogleSignInAccount? googleUser = await _googleSignIn
          .signIn()
          .timeout(const Duration(seconds: 30), onTimeout: () => null);

      if (googleUser == null) {
        _setError('Sign-in was cancelled');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication
          .timeout(const Duration(seconds: 30), onTimeout: () => throw TimeoutException('Google authentication timed out'));

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final UserCredential userCredential = await _auth
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 30), onTimeout: () => throw TimeoutException('Firebase sign-in timed out'));
      _currentGoogleUser = googleUser;

      if (userCredential.user != null) {
        final splitzyUser = SplitzyUser(
          uid: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? googleUser.displayName ?? '',
          email: userCredential.user!.email ?? googleUser.email,
          photoUrl: userCredential.user!.photoURL ?? googleUser.photoUrl,
        );

        // Saving user can also hang on poor networks; guard with timeout
        await _saveUserToFirestore(splitzyUser).timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw TimeoutException('Saving user timed out'),
        );
        _currentSplitzyUser = splitzyUser;
      }

      _logger.i('Google sign-in successful');
      return userCredential;
    } on TimeoutException catch (e) {
      _logger.e('Timeout during Google sign-in: ${e.message}');
      _setError(e.message ?? 'Operation timed out');
      // Best-effort cleanup
      try { await _googleSignIn.disconnect(); } catch (_) {}
      return null;
    } on FirebaseAuthException catch (e) {
      _logger.e('Firebase Auth error: ${e.code} - ${e.message}');
      _setError('Authentication failed: ${e.message}');
      return null;
    } catch (e) {
      _logger.e('Google sign-in error: $e');
      _setError('Sign-in failed. Please try again.');
      return null;
    } finally {
      _setLoading(false);
      _isSigningIn = false;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _logger.i('Email sign-in successful');
      return userCredential;
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

      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

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
          .timeout(const Duration(seconds: 10), onTimeout: () => null);

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        _currentGoogleUser = GoogleSignInAccount;

        // Ensure user data is loaded
        if (userCredential.user != null) {
          await _loadCurrentUser();
        }

        return true;
      }

      return false;
    } catch (e) {
      _logger.w('Silent sign-in failed: $e');
      // Clear any stale auth state
      try {
        await _googleSignIn.signOut();
        await _auth.signOut();
      } catch (signOutError) {
        _logger.w('Error clearing auth state: $signOutError');
      }
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await Future.wait([
        _googleSignIn.signOut(),
        _auth.signOut(),
      ]);
      _currentSplitzyUser = null;
      _currentGoogleUser = null;
      _logger.i('Sign out successful');
    } catch (e) {
      _logger.e('Sign out error: $e');
      _setError('Failed to sign out');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount() async {
    try {
      _setLoading(true);

      if (_currentFirebaseUser != null) {
        await _firestore
            .collection('users')
            .doc(_currentFirebaseUser!.uid)
            .delete();

        await _currentFirebaseUser!.delete();

        _currentSplitzyUser = null;
        _currentGoogleUser = null;
        _logger.i('Account deletion successful');
      }
    } on FirebaseAuthException catch (e) {
      _logger.e('Account deletion error: ${e.code} - ${e.message}');
      _setError('Failed to delete account: ${e.message}');
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
    if (_currentSplitzyUser == null) return;

    try {
      _setLoading(true);

      final updatedUser = _currentSplitzyUser!.copyWith(
        name: name ?? _currentSplitzyUser!.name,
        photoUrl: photoUrl ?? _currentSplitzyUser!.photoUrl,
        phoneNumber: phoneNumber ?? _currentSplitzyUser!.phoneNumber,
      );

      await _saveUserToFirestore(updatedUser);
      _currentSplitzyUser = updatedUser;

      if (name != null && _currentFirebaseUser != null) {
        await _currentFirebaseUser!.updateDisplayName(name);
      }

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
          .get();

      if (doc.exists) {
        return SplitzyUser.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting user by ID: $e');
      return null;
    }
  }

  Future<List<SplitzyUser>> searchUsers(String query) async {
    try {
      if (query.isEmpty) return [];

      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('email', isLessThan: '${query.toLowerCase()}\uf8ff')
          .limit(10)
          .get();

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
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}