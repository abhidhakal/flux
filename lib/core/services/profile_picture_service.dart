import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePictureTooLargeException implements Exception {
  const ProfilePictureTooLargeException(this.maxSizeInBytes);

  final int maxSizeInBytes;

  @override
  String toString() =>
      'Profile picture must be smaller than ${maxSizeInBytes ~/ (1024 * 1024)} MB.';
}

class ProfilePictureService {
  static final ProfilePictureService _instance = ProfilePictureService._internal();
  static const int maxFileSizeInBytes = 2 * 1024 * 1024;
  static const int _downloadUrlRetryCount = 3;

  factory ProfilePictureService() => _instance;
  ProfilePictureService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  File? _profileImage;
  String? _profileImageUrl;

  File? get profileImage => _profileImage;
  bool get hasProfileImage =>
      _profileImage != null || (_profileImageUrl?.isNotEmpty ?? false);

  Future<void> setProfileImage(File? image, {required String userId}) async {
    if (image != null) {
      final imageSize = await image.length();
      if (imageSize > maxFileSizeInBytes) {
        throw const ProfilePictureTooLargeException(maxFileSizeInBytes);
      }
      final previousImage = _profileImage;
      final previousImageUrl = _profileImageUrl;

      try {
        final storageRef =
            _storage.ref().child('users/$userId/profile_picture.jpg');
        final snapshot = await storageRef.putFile(
          image,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final downloadUrl = await _getDownloadUrlWithRetry(snapshot.ref);

        _profileImageUrl = downloadUrl;
        _profileImage = image;
        await _firestore.collection('users').doc(userId).update({
          'photoUrl': downloadUrl,
          'profileImageBase64': FieldValue.delete(),
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_path_$userId', image.path);

        final user = _auth.currentUser;
        if (user != null && user.uid == userId) {
          await user.updatePhotoURL(downloadUrl);
        }
      } catch (e) {
        _profileImage = previousImage;
        _profileImageUrl = previousImageUrl;
        debugPrint('Error saving profile image to Firebase Storage: $e');
        rethrow;
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_image_path_$userId');
      _profileImageUrl = null;

      try {
        await _storage.ref().child('users/$userId/profile_picture.jpg').delete();
      } catch (e) {
        debugPrint('Error removing profile image from Firebase Storage: $e');
      }

      try {
        await _firestore.collection('users').doc(userId).update({
          'photoUrl': FieldValue.delete(),
          'profileImageBase64': FieldValue.delete(),
        });

        final user = _auth.currentUser;
        if (user != null && user.uid == userId) {
          await user.updatePhotoURL(null);
        }
      } catch (e) {
        debugPrint('Error removing profile image from Firestore: $e');
        rethrow;
      }
    }
  }

  Future<void> loadProfileImage({required String userId}) async {
    _profileImage = null;
    _profileImageUrl = null;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      final photoUrl = data?['photoUrl'] as String?;
      if (photoUrl != null && photoUrl.isNotEmpty) {
        _profileImageUrl = photoUrl;

        final prefs = await SharedPreferences.getInstance();
        final imagePath = prefs.getString('profile_image_path_$userId');
        if (imagePath != null && File(imagePath).existsSync()) {
          _profileImage = File(imagePath);
        }

        return;
      }
    } catch (e) {
      debugPrint('Error loading profile image URL from Firestore: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_path_$userId');
    if (imagePath != null && File(imagePath).existsSync()) {
      _profileImage = File(imagePath);
    } else {
      _profileImage = null;
    }
  }

  Future<void> removeProfileImage({required String userId}) async {
    await setProfileImage(null, userId: userId);
  }

  Future<String> _getDownloadUrlWithRetry(Reference ref) async {
    Object? lastError;

    for (var attempt = 0; attempt < _downloadUrlRetryCount; attempt++) {
      try {
        return await ref.getDownloadURL();
      } on FirebaseException catch (e) {
        lastError = e;
        if (e.code != 'object-not-found' || attempt == _downloadUrlRetryCount - 1) {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      }
    }

    throw lastError ?? Exception('Failed to fetch profile image download URL.');
  }

  Widget buildProfileAvatar({
    required String? displayName,
    required ColorScheme colorScheme,
    double radius = 25,
  }) {
    ImageProvider<Object>? imageProvider;
    if (_profileImage != null) {
      imageProvider = FileImage(_profileImage!);
    } else if (_profileImageUrl?.isNotEmpty ?? false) {
      imageProvider = NetworkImage(_profileImageUrl!);
    }

    if (imageProvider != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: colorScheme.primary,
        backgroundImage: imageProvider,
      );
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundColor: colorScheme.primary,
        child: Text(
          (displayName?.isNotEmpty == true) ? displayName![0].toUpperCase() : 'U',
          style: TextStyle(
            fontSize: radius * 0.7,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
      );
    }
  }
}
