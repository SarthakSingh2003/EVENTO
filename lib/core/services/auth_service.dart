import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _userModel != null;
  UserModel? _userModel;
  UserModel? get userModel => _userModel;
  UserRole? get userRole => _userModel?.role;

  AuthService() {
    debugPrint('AuthService initialized');
    _auth.authStateChanges().listen((User? user) {
      debugPrint('Auth state changed - User: ${user?.email}');
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _userModel = null;
        debugPrint('User signed out, notifying listeners');
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      debugPrint('Loading user data for UID: $uid');
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _userModel = UserModel.fromMap(doc.data()!);
        debugPrint('User data loaded: ${_userModel?.name} (${_userModel?.role})');
        notifyListeners();
      } else {
        debugPrint('User document does not exist in Firestore');
        // Create a default user model if document doesn't exist and persist it
        _userModel = UserModel(
          id: uid,
          email: _auth.currentUser?.email ?? '',
          name: _auth.currentUser?.displayName ?? 'Unknown User',
          role: UserRole.attendee,
          createdAt: DateTime.now(),
          profileImage: _auth.currentUser?.photoURL,
        );
        try {
          await _firestore.collection('users').doc(uid).set(_userModel!.toMap());
          debugPrint('Created user document in Firestore for $uid');
        } catch (e) {
          debugPrint('Failed to persist default user document: $e');
          // Continue with local model; rules will still allow non-admin actions
        }
        debugPrint('Created default user model: ${_userModel?.name}');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      // Create a default user model on error
      _userModel = UserModel(
        id: uid,
        email: _auth.currentUser?.email ?? '',
        name: _auth.currentUser?.displayName ?? 'Unknown User',
        role: UserRole.attendee,
        createdAt: DateTime.now(),
        profileImage: _auth.currentUser?.photoURL,
      );
      debugPrint('Created default user model due to error: ${_userModel?.name}');
      notifyListeners();
    }
  }

  Future<bool> signInWithEmailAndPassword(
    String email, 
    String password,
  ) async {
    try {
      debugPrint('Attempting email/password sign in for: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('Email/password sign in successful: ${credential.user?.email}');
      return credential.user != null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Email/password sign in failed: ${e.message}');
      throw _handleAuthException(e);
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in
        return false;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user == null) return false;

      // Ensure user document exists and load into _userModel
      final docRef = _firestore.collection('users').doc(user.uid);
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        final userModel = UserModel(
          id: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? 'Unknown User',
          role: UserRole.attendee,
          createdAt: DateTime.now(),
          profileImage: user.photoURL,
        );
        await docRef.set(userModel.toMap());
        _userModel = userModel;
      } else {
        _userModel = UserModel.fromMap(snapshot.data()!);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error with Google sign in: $e');
      rethrow;
    }
  }

  Future<bool> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
    UserRole role, {
    String? username,
    DateTime? birthday,
    String? phone,
    String? securityQuestion,
    String? securityAnswer,
  }) async {
    try {
      debugPrint('Attempting email/password sign up for: $email');
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('User account created: ${credential.user?.email}');
      // Create user document in Firestore
      final userModel = UserModel(
        id: credential.user!.uid,
        email: email,
        name: name,
        role: role,
        createdAt: DateTime.now(),
        username: username,
        birthday: birthday,
        phone: phone,
        securityQuestion: securityQuestion,
        securityAnswer: securityAnswer,
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userModel.toMap());

      debugPrint('User document created in Firestore');
      
      // Set the user model immediately for navigation
      _userModel = userModel;
      notifyListeners();
      
      return credential.user != null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Email/password sign up failed: ${e.message}');
      throw _handleAuthException(e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    try {
      debugPrint('Signing out user');
      // Sign out from Firebase
      await _auth.signOut();
      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  Future<void> updateUserProfile({
    String? name,
    String? phone,
    String? profileImage,
  }) async {
    if (_userModel == null) return;

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (profileImage != null) updates['profileImage'] = profileImage;

      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update(updates);

      await _loadUserData(currentUser!.uid);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  Future<void> addModerator(String eventId, String moderatorEmail) async {
    try {
      // Find user by email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: moderatorEmail)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('User not found with this email');
      }

      final moderatorId = userQuery.docs.first.id;
      
      // Add moderator to event
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('moderators')
          .doc(moderatorId)
          .set({
        'email': moderatorEmail,
        'addedAt': DateTime.now(),
      });

      // Update user role to moderator if not already
      await _firestore
          .collection('users')
          .doc(moderatorId)
          .update({'role': UserRole.moderator.name});
    } catch (e) {
      debugPrint('Error adding moderator: $e');
      rethrow;
    }
  }

  Future<void> removeModerator(String eventId, String moderatorId) async {
    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('moderators')
          .doc(moderatorId)
          .delete();
    } catch (e) {
      debugPrint('Error removing moderator: $e');
      rethrow;
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
