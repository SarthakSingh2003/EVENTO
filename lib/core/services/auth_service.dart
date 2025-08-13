import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';  // Temporarily disabled
// import 'package:cloud_firestore/cloud_firestore.dart';  // Temporarily disabled
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  // final FirebaseAuth _auth = FirebaseAuth.instance;  // Temporarily disabled
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;  // Temporarily disabled
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // User? get currentUser => _auth.currentUser;  // Temporarily disabled
  bool get isAuthenticated => _userModel != null;
  UserModel? _userModel;
  UserModel? get userModel => _userModel;
  UserRole? get userRole => _userModel?.role;

  AuthService() {
    // Temporarily disabled Firebase auth state listener
    // _auth.authStateChanges().listen((User? user) {
    //   if (user != null) {
    //     _loadUserData(user.uid);
    //   } else {
    //     _userModel = null;
    //     notifyListeners();
    //   }
    // });
  }

  Future<void> _loadUserData(String uid) async {
    // Temporarily disabled Firebase loading
    // try {
    //   final doc = await _firestore.collection('users').doc(uid).get();
    //   if (doc.exists) {
    //     _userModel = UserModel.fromMap(doc.data()!);
    //     notifyListeners();
    //   }
    // } catch (e) {
    //   debugPrint('Error loading user data: $e');
    // }
  }

  Future<bool> signInWithEmailAndPassword(
    String email, 
    String password,
  ) async {
    // Temporarily disabled Firebase auth
    // try {
    //   final credential = await _auth.signInWithEmailAndPassword(
    //     email: email,
    //     password: password,
    //   );
    //   return credential;
    // } on FirebaseAuthException catch (e) {
    //   throw _handleAuthException(e);
    // }
    
    // Mock authentication for testing
    if (email == 'test@example.com' && password == 'password') {
      _userModel = UserModel(
        id: 'mock-user-id',
        email: email,
        name: 'Test User',
        role: UserRole.attendee,
        createdAt: DateTime.now(),
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> signInWithGoogle() async {
    try {
      // Temporarily disabled Firebase Google Sign-In
      // final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      // if (googleUser == null) return false;

      // final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      // final credential = GoogleAuthProvider.credential(
      //   accessToken: googleAuth.accessToken,
      //   idToken: googleAuth.idToken,
      // );

      // final userCredential = await _auth.signInWithCredential(credential);
      // final user = userCredential.user;

      // if (user != null) {
      //   // Check if user exists in Firestore
      //   final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      //   if (!userDoc.exists) {
      //     // Create new user document
      //     final userModel = UserModel(
      //       id: user.uid,
      //       email: user.email!,
      //       name: user.displayName ?? 'Unknown User',
      //       role: UserRole.attendee,
      //       createdAt: DateTime.now(),
      //       profileImage: user.photoURL,
      //     );

      //     await _firestore
      //         .collection('users')
      //         .doc(user.uid)
      //         .set(userModel.toMap());
      //   }

      //   await _loadUserData(user.uid);
      //   return true;
      // }
      
      // Mock Google Sign-In for testing
      _userModel = UserModel(
        id: 'mock-google-user-id',
        email: 'googleuser@gmail.com',
        name: 'Google User',
        role: UserRole.attendee,
        createdAt: DateTime.now(),
        profileImage: 'https://via.placeholder.com/150',
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return false;
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
    // Temporarily disabled Firebase auth
    // try {
    //   final credential = await _auth.createUserWithEmailAndPassword(
    //     email: email,
    //     password: password,
    //   );

    //   // Create user document in Firestore
    //   final userModel = UserModel(
    //     id: credential.user!.uid,
    //     email: email,
    //     name: name,
    //     role: role,
    //     createdAt: DateTime.now(),
    //     username: username,
    //     birthday: birthday,
    //     phone: phone,
    //     securityQuestion: securityQuestion,
    //     securityAnswer: securityAnswer,
    //   );

    //   await _firestore
    //       .collection('users')
    //       .doc(credential.user!.uid)
    //       .set(userModel.toMap());

    //   return credential;
    // } on FirebaseAuthException catch (e) {
    //   throw _handleAuthException(e);
    // }
    
    // Mock signup for testing
    _userModel = UserModel(
      id: 'mock-user-id-${DateTime.now().millisecondsSinceEpoch}',
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
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();
      
      // Temporarily disabled Firebase auth
      // await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
    
    // Mock signout
    _userModel = null;
    notifyListeners();
  }

  Future<void> updateUserProfile({
    String? name,
    String? phone,
    String? profileImage,
  }) async {
    if (_userModel == null) return;

    // Temporarily disabled Firebase updates
    // try {
    //   final updates = <String, dynamic>{};
    //   if (name != null) updates['name'] = name;
    //   if (phone != null) updates['phone'] = phone;
    //   if (profileImage != null) updates['profileImage'] = profileImage;

    //   await _firestore
    //       .collection('users')
    //       .doc(currentUser!.uid)
    //       .update(updates);

    //   await _loadUserData(currentUser!.uid);
    // } catch (e) {
    //   debugPrint('Error updating profile: $e');
    //   rethrow;
    // }
    
    // Mock profile update
    if (name != null) _userModel = _userModel!.copyWith(name: name);
    if (phone != null) _userModel = _userModel!.copyWith(phone: phone);
    if (profileImage != null) _userModel = _userModel!.copyWith(profileImage: profileImage);
    notifyListeners();
  }

  Future<void> addModerator(String eventId, String moderatorEmail) async {
    // Temporarily disabled Firebase operations
    // try {
    //   // Find user by email
    //   final userQuery = await _firestore
    //       .collection('users')
    //       .where('email', isEqualTo: moderatorEmail)
    //       .get();

    //   if (userQuery.docs.isEmpty) {
    //     throw Exception('User not found with this email');
    //   }

    //   final moderatorId = userQuery.docs.first.id;
      
    //   // Add moderator to event
    //   await _firestore
    //       .collection('events')
    //       .doc(eventId)
    //       .collection('moderators')
    //       .doc(moderatorId)
    //       .set({
    //     'email': moderatorEmail,
    //     'addedAt': DateTime.now(),
    //   });

    //   // Update user role to moderator if not already
    //   await _firestore
    //       .collection('users')
    //       .doc(moderatorId)
    //       .update({'role': UserRole.moderator.name});
    // } catch (e) {
    //   debugPrint('Error adding moderator: $e');
    //   rethrow;
    // }
    
    // Mock moderator addition
    debugPrint('Mock: Adding moderator $moderatorEmail to event $eventId');
  }

  Future<void> removeModerator(String eventId, String moderatorId) async {
    // Temporarily disabled Firebase operations
    // try {
    //   await _firestore
    //       .collection('events')
    //       .doc(eventId)
    //       .collection('moderators')
    //       .doc(moderatorId)
    //       .delete();
    // } catch (e) {
    //   debugPrint('Error removing moderator: $e');
    //   rethrow;
    // }
    
    // Mock moderator removal
    debugPrint('Mock: Removing moderator $moderatorId from event $eventId');
  }

  String _handleAuthException(dynamic e) {
    // Temporarily disabled Firebase exception handling
    // switch (e.code) {
    //   case 'user-not-found':
    //     return 'No user found with this email.';
    //   case 'wrong-password':
    //     return 'Wrong password provided.';
    //   case 'email-already-in-use':
    //     return 'An account already exists with this email.';
    //   case 'weak-password':
    //     return 'The password provided is too weak.';
    //   case 'invalid-email':
    //     return 'The email address is invalid.';
    //   case 'user-disabled':
    //     return 'This user account has been disabled.';
    //   case 'too-many-requests':
    //     return 'Too many attempts. Please try again later.';
    //   default:
    //     return 'An error occurred. Please try again.';
    // }
    
    return 'An error occurred. Please try again.';
  }
} 