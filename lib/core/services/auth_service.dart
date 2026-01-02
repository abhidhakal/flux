import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart' as app_models;

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  app_models.User? get currentUser {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    return app_models.User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      lastLoginAt: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
      isEmailVerified: firebaseUser.emailVerified,
    );
  }

  // Stream of auth state changes
  Stream<app_models.User?> get authStateChanges {
    return _auth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;

      return app_models.User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        lastLoginAt: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
        isEmailVerified: firebaseUser.emailVerified,
      );
    });
  }

  // Sign up with email and password
  Future<app_models.User> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw Exception('Failed to create user');

      // Update display name
      await user.updateDisplayName(displayName);

      // Create user document in Firestore
      final userModel = app_models.User(
        id: user.uid,
        email: user.email ?? '',
        displayName: displayName,
        photoUrl: user.photoURL,
        createdAt: user.metadata.creationTime ?? DateTime.now(),
        lastLoginAt: user.metadata.lastSignInTime ?? DateTime.now(),
        isEmailVerified: user.emailVerified,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toJson());

      return userModel;
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  // Sign in with email and password
  Future<app_models.User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw Exception('Failed to sign in');

      // Check if user document exists in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Create user document if it doesn't exist
        final userModel = app_models.User(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoUrl: user.photoURL,
          createdAt: user.metadata.creationTime ?? DateTime.now(),
          lastLoginAt: DateTime.now(),
          isEmailVerified: user.emailVerified,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toJson());

        return userModel;
      } else {
        // Update last login time for existing user
        await _firestore.collection('users').doc(user.uid).update({
          'lastLoginAt': DateTime.now().toIso8601String(),
        });

        return app_models.User(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoUrl: user.photoURL,
          createdAt: user.metadata.creationTime ?? DateTime.now(),
          lastLoginAt: DateTime.now(),
          isEmailVerified: user.emailVerified,
        );
      }
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign in with Google
  Future<app_models.User> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      // Ensure we sign out first to force account selection
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign in cancelled');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) throw Exception('Failed to sign in with Google');

      // Check if user document exists in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Create user document if it doesn't exist
        final userModel = app_models.User(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? googleUser.displayName,
          photoUrl: user.photoURL ?? googleUser.photoUrl,
          createdAt: user.metadata.creationTime ?? DateTime.now(),
          lastLoginAt: DateTime.now(),
          isEmailVerified: user.emailVerified,
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toJson());

        return userModel;
      } else {
        // Update last login time for existing user
        await _firestore.collection('users').doc(user.uid).update({
          'lastLoginAt': DateTime.now().toIso8601String(),
          if (user.photoURL != null) 'photoUrl': user.photoURL,
        });

        // Fetch refreshed user data
        final updatedDoc = await _firestore.collection('users').doc(user.uid).get();
        return app_models.User.fromJson(updatedDoc.data()!);
      }
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Update user profile
  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;

      await _firestore.collection('users').doc(userId).update(updates);

      // Update Firebase Auth profile
      final user = _auth.currentUser;
      if (user != null) {
        if (displayName != null) await user.updateDisplayName(displayName);
        if (photoUrl != null) await user.updatePhotoURL(photoUrl);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Update user email (updates both Firebase Auth and Firestore)
  Future<void> updateEmail({
    required String userId,
    required String newEmail,
  }) async {
    try {
      // Update Firebase Auth email
      final firebase_auth.User authUser = firebase_auth.FirebaseAuth.instance.currentUser!;
      await authUser.verifyBeforeUpdateEmail(newEmail);

      // Update Firestore user document
      await _firestore.collection('users').doc(userId).update({
        'email': newEmail,
      });
    } catch (e) {
      throw Exception('Failed to update email: $e');
    }
  }

  // Set premium status on user preferences
  Future<void> setPremiumStatus({
    required String userId,
    required bool isPremium,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'preferences': {
          'isPremium': isPremium,
        },
      }, firestore.SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update premium status: $e');
    }
  }

  // Get user by ID
  Future<app_models.User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) return null;
      return app_models.User.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }
}
